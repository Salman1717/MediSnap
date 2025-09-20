//
//  ExtractViewModel.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import UIKit
import SwiftUI
import Combine

@MainActor
class ExtractViewModel: ObservableObject {
    @Published var ocrText: String = ""
    @Published var medications: [Medication] = []
    @Published var prescriptionDate: Date? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showCamera: Bool = false
    @Published var selectedImage: UIImage? = nil

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
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
