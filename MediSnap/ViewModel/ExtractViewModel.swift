//
//  ExtractViewModel.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import UIKit
import SwiftUI
import Combine
import FirebaseAuth

@MainActor
class ExtractViewModel: ObservableObject {
    @Published var ocrText: String = ""
    @Published var medications: [Medication] = []
    @Published var prescriptionDate: Date? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showCamera: Bool = false
    @Published var selectedImage: UIImage? = nil

    // existing processImage(...) left unchanged
    func processImage(_ image: UIImage) async {
        isLoading = true
        errorMessage = nil
        ocrText = ""
        medications = []
        prescriptionDate = nil

        do {
            let text = try await OCRHelper.recognizeText(from: image)
            ocrText = text

            let (meds, dateString) = try await GeminiService.shared.extractMedsAndDate(from: text)
            medications = meds

            if let dateString = dateString {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                prescriptionDate = formatter.date(from: dateString)
            } else {
                // fallback: use today
                prescriptionDate = Date()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // NEW: savePrescription returns the saved Prescription
    func savePrescription() async throws -> Prescription {
        guard let date = prescriptionDate else {
            throw NSError(domain: "ExtractViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "Prescription date is missing"])
        }

        let prescription = Prescription(id: UUID().uuidString, date: date, medications: medications)

        // ensure user authenticated for Firestore rules — you can sign in anon if needed
        if Auth.auth().currentUser == nil {
            _ = try await Auth.auth().signInAnonymously()
        }

        try await FirebaseService.shared.savePrescription(prescription)
        return prescription
    }
}
