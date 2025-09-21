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
    @Published var showSafetyInformation: Bool = false
    @Published var prescriptionStatus: PrescriptionStatus = .extracted
    
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
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: dateString) {
                    prescriptionDate = date
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Complete prescription processing workflow
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
            
            // 1️⃣ Save prescription
            let pres = Prescription(id: UUID().uuidString, date: date, medications: medications)
            try await FirebaseService.shared.savePrescription(pres)
            currentPrescriptionId = pres.id
            
            // 2️⃣ Generate schedule using Gemini
            try await GeminiService.shared.generateScheduleWithGemini(prescription: pres)
            
            // Clear any previous error messages if successful
            errorMessage = nil
            
        } catch {
            errorMessage = "Failed to save prescription or generate schedule: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Save schedule to Firestore
    func saveScheduleToFirestore() async {
        guard let presId = currentPrescriptionId else {
            errorMessage = "No prescription ID available."
            return
        }
        
        isLoading = true
        
        let validSchedules = GeminiService.shared.medicationSchedule.filter { !$0.reminders.isEmpty }
        
        guard !validSchedules.isEmpty else {
            errorMessage = "No valid schedules to save."
            isLoading = false
            return
        }
        
        do {
            // Save schedule
            try await FirebaseService.shared.saveSchedule(
                prescriptionId: presId,
                schedule: validSchedules
            )
            
            // Update status
            try await FirebaseService.shared.updatePrescriptionStatus(
                prescriptionId: presId,
                status: .scheduled
            )
            
            // 🆕 AUTOMATICALLY GENERATE AND SAVE SAFETY INFORMATION
            try await generateAndSaveSafetyInformation()
            
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save schedule: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Add schedule to Google Calendar
    func addScheduleToGoogleCalendar() async {
        guard let presId = currentPrescriptionId else {
            errorMessage = "No prescription ID available."
            return
        }
        
        let schedule = GeminiService.shared.medicationSchedule
        
        guard !schedule.isEmpty else {
            errorMessage = "No schedule available to add to calendar."
            return
        }
        
        isLoading = true
        
        do {
            let eventIds = try await GoogleCalendarService.shared.addMedicationScheduleToCalendar(schedule: schedule)
            
            // Save event IDs to Firestore
            let eventMap = Dictionary(uniqueKeysWithValues: eventIds.enumerated().map { (index, id) in
                ("event_\(index)", [id])
            })
            
            try await FirebaseService.shared.saveScheduleEventIds(
                prescriptionId: presId,
                eventMap: eventMap
            )
            
            // Update status
            try await FirebaseService.shared.updatePrescriptionStatus(
                prescriptionId: presId,
                status: .calendarAdded
            )
            
            errorMessage = nil
            print("Successfully added \(eventIds.count) events to Google Calendar")
            
        } catch {
            errorMessage = "Failed to add schedule to Google Calendar: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // 🆕 NEW: Generate and save safety information
    private func generateAndSaveSafetyInformation() async throws {
        guard let presId = currentPrescriptionId else {
            throw NSError(domain: "ExtractViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "No prescription ID available"])
        }
        
        guard !medications.isEmpty else {
            throw NSError(domain: "ExtractViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "No medications available for safety analysis"])
        }
        
        // Generate safety information using Gemini
        let safetyResponse = try await GeminiService.shared.getSafetyInformation(for: medications)
        
        // Save to Firestore
        try await FirebaseService.shared.saveSafetyInformation(
            prescriptionId: presId,
            safetyResponse: safetyResponse
        )
        
        // Update status
        try await FirebaseService.shared.updatePrescriptionStatus(
            prescriptionId: presId,
            status: .safetyAnalyzed
        )
        
        print("Safety information generated and saved successfully")
    }
    
    // 🆕 NEW: Complete all processing workflow
    func completeAllProcessing() async {
        guard let presId = currentPrescriptionId else {
            errorMessage = "No prescription ID available."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1️⃣ Save schedule if not already saved
            if prescriptionStatus.rawValue == "extracted" {
                await saveScheduleToFirestore()
                if errorMessage != nil { return } // Exit if error occurred
            }
            
            // 2️⃣ Add to calendar if requested
            // This is optional - you might want to make this based on user preference
            
            // 3️⃣ Mark as completed
            try await FirebaseService.shared.updatePrescriptionStatus(
                prescriptionId: presId,
                status: .completed
            )
            
            prescriptionStatus = .completed
            
        } catch {
            errorMessage = "Failed to complete processing: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Show safety information manually
    func showMedicationSafetyInfo() {
        showSafetyInformation = true
    }
    
    // 🆕 NEW: Load existing safety information from Firestore
    func loadSafetyInformation() async -> SafetyResponse? {
        guard let presId = currentPrescriptionId else { return nil }
        
        do {
            return try await FirebaseService.shared.getSafetyInformation(prescriptionId: presId)
        } catch {
            print("Failed to load safety information: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Helper parsers
    private func parseFrequency(_ text: String) -> Int {
        let lower = text.lowercased()
        if lower.contains("once") { return 1 }
        if lower.contains("twice") { return 2 }
        if lower.contains("thrice") { return 3 }
        return 1
    }
    
    private func parseDuration(_ text: String) -> Int {
        let components = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
        for comp in components {
            if let num = Int(comp) { return max(num, 1) }
        }
        return 1
    }
}
