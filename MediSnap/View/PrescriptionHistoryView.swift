import SwiftUI
import SwiftfulLoadingIndicators

struct PrescriptionHistoryView: View {
    @StateObject private var vm = PrescriptionHistoryViewModel()
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.4), Color.teal.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient.ignoresSafeArea()
                
                if vm.isLoading {
                    LoadingIndicator(animation: .threeBallsTriangle, color: .red, size: .large, speed: .fast)
                } else if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if vm.prescriptions.isEmpty {
                    Text("No prescriptions yet")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(vm.prescriptions) { prescription in
                                PrescriptionCard(prescription: prescription)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Prescription History")
            .task {
                if let userId = AuthServices.shared.currentUser?.uid {
                    await vm.fetchPrescriptions(for: userId)
                } else {
                    vm.errorMessage = "User not logged in"
                }
            }
        }
    }
}
