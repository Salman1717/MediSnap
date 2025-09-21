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
    
    // Flow tracking
    @Published var currentStep: ProcessingStep = .idle
    @Published var completedSteps: Set<ProcessingStep> = []
    
    var currentPrescriptionId: String?
    
    enum ProcessingStep {
        case idle
        case savingPrescription
        case generatingSchedule
        case addingToCalendar
        case generatingSafetyInfo
        case savingAll
        case completed
        
        var description: String {
            switch self {
            case .idle: return "Ready"
            case .savingPrescription: return "Saving Prescription..."
            case .generatingSchedule: return "Creating Schedule..."
            case .addingToCalendar: return "Adding to Google Calendar..."
            case .generatingSafetyInfo: return "Generating Safety Information..."
            case .savingAll: return "Saving Everything..."
            case .completed: return "Completed"
            }
        }
    }
    
    // MARK: - Process image (OCR + extraction)
    func processImage(_ image: UIImage) async {
        isLoading = true
        errorMessage = nil
        currentStep = .idle
        completedSteps.removeAll()
        
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
    
    // MARK: - Step 1: Save prescription and generate schedule
    func savePrescriptionAndGenerateSchedule() async {
        guard !medications.isEmpty else {
            errorMessage = "No medications to save."
            return
        }
        
        isLoading = true
        errorMessage = nil
        currentStep = .savingPrescription
        
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
            completedSteps.insert(.savingPrescription)
            
            // 2️⃣ Generate schedule using Gemini
            currentStep = .generatingSchedule
            try await GeminiService.shared.generateScheduleWithGemini(prescription: pres)
            completedSteps.insert(.generatingSchedule)
            
            currentStep = .completed
            errorMessage = nil
            
        } catch {
            errorMessage = "Failed to save prescription or generate schedule: \(error.localizedDescription)"
            currentStep = .idle
        }
        
        isLoading = false
    }
    
    // MARK: - Complete Sequential Flow: Schedule → Calendar → Safety → Save
    func executeCompleteFlow() async {
        guard let presId = currentPrescriptionId else {
            errorMessage = "No prescription ID available."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Step 1: Ensure schedule is ready (should already be done)
            let validSchedules = GeminiService.shared.medicationSchedule.filter { !$0.reminders.isEmpty }
            guard !validSchedules.isEmpty else {
                errorMessage = "No valid schedules available."
                isLoading = false
                return
            }
            
            // Step 2: Add to Google Calendar
            currentStep = .addingToCalendar
            let eventIds = try await GoogleCalendarService.shared.addMedicationScheduleToCalendar(schedule: validSchedules)
            completedSteps.insert(.addingToCalendar)
            
            // Step 3: Generate Safety Information
            currentStep = .generatingSafetyInfo
            let safetyResponse = try await GeminiService.shared.getSafetyInformation(for: medications)
            completedSteps.insert(.generatingSafetyInfo)
            
            // Step 4: Save Everything Together
            currentStep = .savingAll
            
            // Save schedule
            try await FirebaseService.shared.saveSchedule(
                prescriptionId: presId,
                schedule: validSchedules
            )
            
            // Save calendar event IDs
            let eventMap = Dictionary(uniqueKeysWithValues: eventIds.enumerated().map { (index, id) in
                ("event_\(index)", [id])
            })
            try await FirebaseService.shared.saveScheduleEventIds(
                prescriptionId: presId,
                eventMap: eventMap
            )
            
            // Save safety information
            try await FirebaseService.shared.saveSafetyInformation(
                prescriptionId: presId,
                safetyResponse: safetyResponse
            )
            
            // Update final status
            try await FirebaseService.shared.updatePrescriptionStatus(
                prescriptionId: presId,
                status: .completed
            )
            
            completedSteps.insert(.savingAll)
            currentStep = .completed
            prescriptionStatus = .completed
            
            print("✅ Complete flow executed successfully:")
            print("   - Schedule created and saved")
            print("   - \(eventIds.count) calendar events added")
            print("   - Safety information generated and saved")
            print("   - All data persisted to Firestore")
            
        } catch {
            errorMessage = "Failed to complete flow: \(error.localizedDescription)"
            currentStep = .idle
            print("❌ Flow failed at step: \(currentStep)")
        }
        
        isLoading = false
    }
    
    // MARK: - Individual step methods (for manual execution if needed)
    
    // Only save schedule (without safety info)
    func saveScheduleOnly() async {
        guard let presId = currentPrescriptionId else {
            errorMessage = "No prescription ID available."
            return
        }
        
        isLoading = true
        currentStep = .savingAll
        
        let validSchedules = GeminiService.shared.medicationSchedule.filter { !$0.reminders.isEmpty }
        
        guard !validSchedules.isEmpty else {
            errorMessage = "No valid schedules to save."
            isLoading = false
            return
        }
        
        do {
            try await FirebaseService.shared.saveSchedule(
                prescriptionId: presId,
                schedule: validSchedules
            )
            
            try await FirebaseService.shared.updatePrescriptionStatus(
                prescriptionId: presId,
                status: .scheduled
            )
            
            completedSteps.insert(.savingAll)
            currentStep = .completed
            errorMessage = nil
            
        } catch {
            errorMessage = "Failed to save schedule: \(error.localizedDescription)"
            currentStep = .idle
        }
        
        isLoading = false
    }
    
    // Only add to calendar
    func addToCalendarOnly() async {
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
        currentStep = .addingToCalendar
        
        do {
            let eventIds = try await GoogleCalendarService.shared.addMedicationScheduleToCalendar(schedule: schedule)
            
            let eventMap = Dictionary(uniqueKeysWithValues: eventIds.enumerated().map { (index, id) in
                ("event_\(index)", [id])
            })
            
            try await FirebaseService.shared.saveScheduleEventIds(
                prescriptionId: presId,
                eventMap: eventMap
            )
            
            try await FirebaseService.shared.updatePrescriptionStatus(
                prescriptionId: presId,
                status: .calendarAdded
            )
            
            completedSteps.insert(.addingToCalendar)
            currentStep = .completed
            errorMessage = nil
            
        } catch {
            errorMessage = "Failed to add schedule to Google Calendar: \(error.localizedDescription)"
            currentStep = .idle
        }
        
        isLoading = false
    }
    
    // Only generate safety info
    func generateSafetyInfoOnly() async {
        guard let presId = currentPrescriptionId else {
            errorMessage = "No prescription ID available."
            return
        }
        
        guard !medications.isEmpty else {
            errorMessage = "No medications available for safety analysis."
            return
        }
        
        isLoading = true
        currentStep = .generatingSafetyInfo
        
        do {
            let safetyResponse = try await GeminiService.shared.getSafetyInformation(for: medications)
            
            try await FirebaseService.shared.saveSafetyInformation(
                prescriptionId: presId,
                safetyResponse: safetyResponse
            )
            
            try await FirebaseService.shared.updatePrescriptionStatus(
                prescriptionId: presId,
                status: .safetyAnalyzed
            )
            
            completedSteps.insert(.generatingSafetyInfo)
            currentStep = .completed
            errorMessage = nil
            
        } catch {
            errorMessage = "Failed to generate safety information: \(error.localizedDescription)"
            currentStep = .idle
        }
        
        isLoading = false
    }
    
    // Show safety information manually
    func showMedicationSafetyInfo() {
        showSafetyInformation = true
    }
    
    // Load existing safety information from Firestore
    func loadSafetyInformation() async -> SafetyResponse? {
        guard let presId = currentPrescriptionId else { return nil }
        
        do {
            return try await FirebaseService.shared.getSafetyInformation(prescriptionId: presId)
        } catch {
            print("Failed to load safety information: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Reset flow state
    func resetFlow() {
        currentStep = .idle
        completedSteps.removeAll()
        errorMessage = nil
    }
    
    // Helper to check if a step is completed
    func isStepCompleted(_ step: ProcessingStep) -> Bool {
        return completedSteps.contains(step)
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
