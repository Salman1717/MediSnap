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
                    VStack(spacing: 20) {
                        LoadingIndicator(animation: .threeBallsTriangle, color: .blue, size: .large, speed: .fast)
                        
                        Text("Loading prescription data...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("This may take a moment as we fetch all related information.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if let error = vm.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Data")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(error)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Retry") {
                            Task {
                                if let userId = AuthServices.shared.currentUser?.uid {
                                    await vm.fetchCompletePrescriptions(for: userId)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if vm.prescriptions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No Prescriptions Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Start by scanning your first prescription to see it appear here with all the detailed information.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Header with stats
                            prescriptionStatsHeader
                            
                            // Prescription cards
                            ForEach(vm.prescriptions) { prescription in
                                EnhancedPrescriptionCard(prescription: prescription) {
                                    vm.selectPrescription(prescription)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .refreshable {
                        if let userId = AuthServices.shared.currentUser?.uid {
                            await vm.fetchCompletePrescriptions(for: userId)
                        }
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            if let userId = AuthServices.shared.currentUser?.uid {
                                await vm.fetchCompletePrescriptions(for: userId)
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
            .task {
                if let userId = AuthServices.shared.currentUser?.uid {
                    await vm.fetchCompletePrescriptions(for: userId)
                } else {
                    vm.errorMessage = "User not logged in"
                }
            }
            .sheet(isPresented: $vm.showDetailView) {
                if let prescription = vm.selectedPrescription {
                    PrescriptionDetailView(prescription: prescription)
                }
            }
        }
    }
    
    private var prescriptionStatsHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Prescriptions")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(vm.prescriptions.count) Total")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Stats overview
            HStack(spacing: 20) {
                StatItem(
                    icon: "pills.fill",
                    count: totalMedicationCount,
                    label: "Medications",
                    color: .blue
                )
                
                StatItem(
                    icon: "clock.fill",
                    count: scheduledPrescriptionsCount,
                    label: "Scheduled",
                    color: .orange
                )
                
                StatItem(
                    icon: "shield.fill",
                    count: safetyAnalyzedCount,
                    label: "Safety Info",
                    color: .red
                )
                
                StatItem(
                    icon: "checkmark.circle.fill",
                    count: completedPrescriptionsCount,
                    label: "Completed",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var totalMedicationCount: Int {
        vm.prescriptions.reduce(0) { total, prescription in
            total + prescription.medications.count
        }
    }
    
    private var scheduledPrescriptionsCount: Int {
        vm.prescriptions.filter { prescription in
            prescription.schedule?.isEmpty == false
        }.count
    }
    
    private var safetyAnalyzedCount: Int {
        vm.prescriptions.filter { prescription in
            prescription.safetyInfo?.medications.isEmpty == false
        }.count
    }
    
    private var completedPrescriptionsCount: Int {
        vm.prescriptions.filter { prescription in
            prescription.status?.lowercased() == "completed"
        }.count
    }
}

struct StatItem: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    PrescriptionHistoryView()
}
