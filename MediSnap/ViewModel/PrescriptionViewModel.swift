import Foundation
import SwiftUI
import FirebaseFirestore
import Combine

@MainActor
class PrescriptionHistoryViewModel: ObservableObject {
    @Published var prescriptions: [CompletePrescription] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedPrescription: CompletePrescription?
    @Published var showDetailView: Bool = false
    
    func fetchCompletePrescriptions(for userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let completePrescriptions = try await FirebaseService.shared.getCompletePrescriptions(for: userId)
            self.prescriptions = completePrescriptions
        } catch {
            self.errorMessage = "Failed to fetch prescriptions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func selectPrescription(_ prescription: CompletePrescription) {
        selectedPrescription = prescription
        showDetailView = true
    }
    
    func refreshPrescription(_ prescriptionId: String) async {
        do {
            if let updatedPrescription = try await FirebaseService.shared.getCompletePrescription(prescriptionId: prescriptionId) {
                // Update the prescription in the array
                if let index = prescriptions.firstIndex(where: { $0.id == prescriptionId }) {
                    prescriptions[index] = updatedPrescription
                }
                
                // Update selected prescription if it's the same one
                if selectedPrescription?.id == prescriptionId {
                    selectedPrescription = updatedPrescription
                }
            }
        } catch {
            errorMessage = "Failed to refresh prescription: \(error.localizedDescription)"
        }
    }
}
