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
    
    @Published var showScheduleConfirmation: Bool = false
    var currentPrescriptionId: String?

    
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
    func savePrescriptionAndGenerateSchedule() async {
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

            // Save prescription
            let pres = Prescription(id: UUID().uuidString, date: date, medications: medications)
            try await FirebaseService.shared.savePrescription(pres)
            currentPrescriptionId = pres.id

            // ✅ Generate schedule using Gemini
            try await GeminiService.shared.generateScheduleWithGemini(prescription: pres)

            // ✅ Clear any previous error messages if successful
            errorMessage = nil

        } catch {
            errorMessage = "Failed to save prescription or generate schedule: \(error.localizedDescription)"
        }

        isLoading = false
    }

    
    func saveScheduleToFirestore() async {
        guard let presId = currentPrescriptionId else {
            errorMessage = "No prescription ID available."
            return
        }

        // ✅ Use the schedule from GeminiService
        let validSchedules = GeminiService.shared.medicationSchedule.filter { !$0.reminders.isEmpty }
        
        guard !validSchedules.isEmpty else {
            errorMessage = "No valid schedules to save."
            return
        }

        do {
            try await FirebaseService.shared.saveSchedule(
                prescriptionId: presId,
                schedule: validSchedules
            )
            errorMessage = nil // Clear any previous errors
        } catch {
            errorMessage = "Failed to save schedule: \(error.localizedDescription)"
        }
    }


    // Add schedule to Google Calendar
    func addScheduleToGoogleCalendar() async {
        let schedule = GeminiService.shared.medicationSchedule
        
        guard !schedule.isEmpty else {
            errorMessage = "No schedule available to add to calendar."
            return
        }
        
        do {
            let eventIds = try await GoogleCalendarService.shared.addMedicationScheduleToCalendar(schedule: schedule)
            
            // Optionally save event IDs to Firestore for future reference
            if let presId = currentPrescriptionId {
                try await saveCalendarEventIds(prescriptionId: presId, eventIds: eventIds)
            }
            
            errorMessage = nil
            print("Successfully added \(eventIds.count) events to Google Calendar")
            
        } catch {
            errorMessage = "Failed to add schedule to Google Calendar: \(error.localizedDescription)"
        }
    }
    
    // Save calendar event IDs to Firestore (optional)
    private func saveCalendarEventIds(prescriptionId: String, eventIds: [String]) async throws {
        // You can implement this to save event IDs to Firestore
        // This allows you to delete events later if needed
        print("Saving calendar event IDs: \(eventIds)")
    }
    
    // Helper parsers
    private func parseFrequency(_ text: String) -> Int {
        let lower = text.lowercased()
        if lower.contains("once") { return 1 }
        if lower.contains("twice") { return 2 }
        if lower.contains("thrice") { return 3 }
        // fallback: 1
        return 1
    }
    
    private func parseDuration(_ text: String) -> Int {
        // Extract number of days from string like "5 days"
        let components = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
        for comp in components {
            if let num = Int(comp) { return max(num, 1) }
        }
        return 1
    }
}
