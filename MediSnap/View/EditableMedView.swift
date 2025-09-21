import SwiftUI

struct EditableMedicationsView: View {
    @ObservedObject var vm: ExtractViewModel
    
    @State private var showScheduleConfirmation = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Step indicator for current flow state
            if vm.currentStep != .idle {
                stepStatusView
            }
            
            List {
                if vm.medications.isEmpty {
                    Text("No medications extracted").foregroundColor(.secondary)
                } else {
                    ForEach($vm.medications) { $med in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Name", text: $med.name)
                                .textFieldStyle(.roundedBorder)
                            
                            HStack {
                                TextField("Dosage", text: Binding(
                                    get: { med.dosage ?? "" },
                                    set: { med.dosage = $0.isEmpty ? nil : $0 }
                                ))
                                TextField("Frequency", text: Binding(
                                    get: { med.frequency ?? "" },
                                    set: { med.frequency = $0.isEmpty ? nil : $0 }
                                ))
                            }
                            .textFieldStyle(.roundedBorder)
                            
                            HStack {
                                TextField("Duration", text: Binding(
                                    get: { med.duration ?? "" },
                                    set: { med.duration = $0.isEmpty ? nil : $0 }
                                ))
                                TextField("Route", text: Binding(
                                    get: { med.route ?? "" },
                                    set: { med.route = $0.isEmpty ? nil : $0 }
                                ))
                            }
                            .textFieldStyle(.roundedBorder)
                            
                            if let original = med.originalText {
                                Text("OCR: \(original)").font(.caption2).foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .listStyle(.plain)
            
            // Action Buttons
            VStack(spacing: 12) {
                // Primary Action: Generate Schedule (Step 1)
                Button(action: {
                    Task {
                        await vm.savePrescriptionAndGenerateSchedule()
                        
                        // Show schedule confirmation if schedule was generated
                        if !GeminiService.shared.medicationSchedule.isEmpty && vm.errorMessage == nil {
                            showScheduleConfirmation = true
                        }
                    }
                }) {
                    HStack {
                        if vm.isLoading && (vm.currentStep == .savingPrescription || vm.currentStep == .generatingSchedule) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(vm.currentStep.description)
                        } else if vm.isStepCompleted(.generatingSchedule) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Schedule Generated")
                        } else {
                            Image(systemName: "calendar.badge.plus")
                            Text("Generate Schedule")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isLoading || vm.medications.isEmpty)
                
                // Secondary Actions (only show after schedule is generated)
                if vm.isStepCompleted(.generatingSchedule) {
                    VStack(spacing: 8) {
                        Text("Next Steps:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                showScheduleConfirmation = true
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "pencil.and.outline")
                                    Text("Edit Schedule")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                Task {
                                    await vm.executeCompleteFlow()
                                }
                            }) {
                                VStack(spacing: 4) {
                                    if vm.isLoading && vm.currentStep != .idle && vm.currentStep != .generatingSchedule {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                    } else {
                                        Image(systemName: "checkmark.seal.fill")
                                    }
                                    Text("Complete All")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(vm.isLoading)
                        }
                    }
                }
            }
            .padding()
            
            if let error = vm.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
        }
        .navigationTitle("Edit Medications")
        .sheet(isPresented: $showScheduleConfirmation) {
            EditableScheduleConfirmationView(vm: vm)
        }
    }
    
    // Step Status View
    private var stepStatusView: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Step")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(vm.currentStep.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            if vm.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
