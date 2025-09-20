// ExtractViewModel.swift (add/replace in your class)
import FirebaseAuth
import Combine
import UIKit

@MainActor
class ExtractViewModel: ObservableObject {
    // existing published properties...
    @Published var ocrText: String = ""
    @Published var medications: [Medication] = []
    @Published var prescriptionDate: Date? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showCamera: Bool = false
    @Published var selectedImage: UIImage? = nil

    // New: present AgenticFlowView
    @Published var runningAgentPrescription: Prescription? = nil
    @Published var isAgentRunning: Bool = false

    // existing processImage(...) left unchanged

    // Save and then automatically run the full agentic flow
    func saveAndRunAgent() async {
        isLoading = true
        errorMessage = nil

        // ensure we have a date (fallback to today if not)
        let date = prescriptionDate ?? Date()

        // ensure user is signed in (anonymous fallback)
        do {
            if Auth.auth().currentUser == nil {
                _ = try await Auth.auth().signInAnonymously()
            }
        } catch {
            isLoading = false
            errorMessage = "Auth failed: \(error.localizedDescription)"
            return
        }

        // Build prescription object to save
        let pres = Prescription(id: UUID().uuidString, date: date, medications: medications)

        do {
            // Persist to Firestore
            try await FirebaseService.shared.savePrescription(pres)

            // Save succeeded — store for UI and start agent
            runningAgentPrescription = pres
            isAgentRunning = true

            // Start agentic flow (await it so we reflect final status)
            await AgenticManager.shared.startFlow(prescription: pres)

            // Agent finished (success or failure statuses are in AgenticManager)
            isAgentRunning = false

        } catch {
            errorMessage = "Failed to save prescription: \(error.localizedDescription)"
            isAgentRunning = false
        }

        isLoading = false
    }

    // Optionally expose a simple wrapper to just save (without running agent)
    func savePrescriptionOnly() async throws -> Prescription {
        let date = prescriptionDate ?? Date()
        if Auth.auth().currentUser == nil {
            _ = try await Auth.auth().signInAnonymously()
        }
        let pres = Prescription(id: UUID().uuidString, date: date, medications: medications)
        try await FirebaseService.shared.savePrescription(pres)
        return pres
    }
}
