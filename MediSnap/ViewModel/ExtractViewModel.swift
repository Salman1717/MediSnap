//
//  ExtractViewModel.swift
//  MediSnap
//

import FirebaseAuth
import Combine
import UIKit

@MainActor
class ExtractViewModel: ObservableObject {
    // MARK: - Published properties
    @Published var ocrText: String = ""
    @Published var medications: [Medication] = []
    @Published var prescriptionDate: Date? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showCamera: Bool = false
    @Published var selectedImage: UIImage? = nil

    // MARK: - Process image (OCR + extraction)
    func processImage(_ image: UIImage) async {
        isLoading = true
        errorMessage = nil
        
        // Reset previous data
        ocrText = ""
        medications = []
        prescriptionDate = nil
        
        do {
            // 1️⃣ OCR the image
            let text = try await OCRHelper.recognizeText(from: image)
            ocrText = text
            
            // 2️⃣ Extract medications + optional date
            let (meds, dateString) = try await GeminiService.shared.extractMedsAndDate(from: text)
            medications = meds
            
            // 3️⃣ Parse date if available
            if let dateString = dateString {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd" // adjust if Gemini returns different format
                if let date = formatter.date(from: dateString) {
                    prescriptionDate = date
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Save prescription to Firestore
    func savePrescription() async {
        guard !medications.isEmpty else {
            errorMessage = "No medications to save."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let date = prescriptionDate ?? Date()
        
        do {
            // Ensure user is signed in (anonymous fallback)
            if Auth.auth().currentUser == nil {
                _ = try await Auth.auth().signInAnonymously()
            }
            
            let pres = Prescription(id: UUID().uuidString, date: date, medications: medications)
            try await FirebaseService.shared.savePrescription(pres)
            
        } catch {
            errorMessage = "Failed to save prescription: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
