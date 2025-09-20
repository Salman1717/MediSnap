import SwiftUI
import SwiftfulLoadingIndicators
import FirebaseAuth

struct PrescriptionHistoryView: View {
    @StateObject private var vm = PrescriptionHistoryViewModel()
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.4), Color.teal.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient.ignoresSafeArea()
                
                if vm.isLoading {
                    LoadingIndicator(animation: .threeBallsTriangle, color: .blue, size: .large, speed: .fast)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
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
