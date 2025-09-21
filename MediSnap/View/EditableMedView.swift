import SwiftUI

struct EditableMedicationsView: View {
    @ObservedObject var vm: ExtractViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var showScheduleConfirmation = false
    
    var gradientBackground: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.7), Color.teal.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack {
            gradientBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Step indicator for current flow state
                        if vm.currentStep != .idle {
                            stepStatusCard
                        }
                        
                        medicationsCard
                        
                        actionButtonsCard
                        
                        if let error = vm.errorMessage {
                            errorCard(error)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            
            if vm.isLoading {
                loaderOverlay
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showScheduleConfirmation) {
            EditableScheduleConfirmationView(vm: vm)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            Text("Edit Medications")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(radius: 5)
            
            Text("Review and modify extracted medication details")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Step Status Card
    private var stepStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
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
            
            // Progress bar
            ProgressView(value: stepProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .background(Color.gray.opacity(0.2))
                .cornerRadius(2)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var stepProgress: Double {
        switch vm.currentStep {
        case .idle: return 0.0
        case .savingPrescription: return 0.5
        case .generatingSchedule: return 1.0
        }
    }
    
    // MARK: - Medications Card
    private var medicationsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Medications")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !vm.medications.isEmpty {
                    Text("\(vm.medications.count) item\(vm.medications.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if vm.medications.isEmpty {
                emptyMedicationsView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach($vm.medications) { $med in
                        medicationCard(for: $med)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var emptyMedicationsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "pills")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No medications extracted")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Please go back and capture a prescription image")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    private func medicationCard(for med: Binding<Medication>) -> some View {
        VStack(spacing: 12) {
            // Medication name - prominent
            VStack(alignment: .leading, spacing: 4) {
                Text("Medication Name")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                TextField("Enter medication name", text: med.name)
                    .textFieldStyle(CustomTextFieldStyle())
                    .font(.headline)
            }
            
            // Dosage and Frequency row
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dosage")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., 10mg", text: Binding(
                        get: { med.wrappedValue.dosage ?? "" },
                        set: { med.wrappedValue.dosage = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(CustomTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Frequency")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Twice daily", text: Binding(
                        get: { med.wrappedValue.frequency ?? "" },
                        set: { med.wrappedValue.frequency = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(CustomTextFieldStyle())
                }
            }
            
            // Duration and Route row
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., 7 days", text: Binding(
                        get: { med.wrappedValue.duration ?? "" },
                        set: { med.wrappedValue.duration = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(CustomTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Route")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Oral", text: Binding(
                        get: { med.wrappedValue.route ?? "" },
                        set: { med.wrappedValue.route = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(CustomTextFieldStyle())
                }
            }
            
            // Original OCR text if available
            if let original = med.wrappedValue.originalText {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Original OCR Text")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(original)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons Card
    private var actionButtonsCard: some View {
        VStack(spacing: 16) {
            Text("Actions")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Primary Action: Generate Schedule
            Button(action: {
                Task {
                    await vm.savePrescriptionAndGenerateSchedule()
                    
                    // Show schedule confirmation if schedule was generated
                    if !GeminiService.shared.medicationSchedule.isEmpty && vm.errorMessage == nil {
                        showScheduleConfirmation = true
                    }
                }
            }) {
                HStack(spacing: 12) {
                    if vm.isLoading && (vm.currentStep == .savingPrescription || vm.currentStep == .generatingSchedule) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text(vm.currentStep.description)
                    } else if vm.isStepCompleted(.generatingSchedule) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Schedule Generated")
                    } else {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title3)
                        Text("Generate Schedule")
                    }
                }
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(vm.medications.isEmpty ? Color.gray : gradientBackground)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .disabled(vm.isLoading || vm.medications.isEmpty)
            .animation(.easeInOut, value: vm.isLoading)
            
            // Secondary Actions (only show after schedule is generated)
            if vm.isStepCompleted(.generatingSchedule) {
                VStack(spacing: 12) {
                    Text("Next Steps")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            showScheduleConfirmation = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "pencil.and.outline")
                                    .font(.title3)
                                Text("Edit Schedule")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            Task {
                                await vm.executeCompleteFlow()
                            }
                        }) {
                            VStack(spacing: 8) {
                                if vm.isLoading && vm.currentStep != .idle && vm.currentStep != .generatingSchedule {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.title3)
                                }
                                Text("Complete All")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(gradientBackground)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .disabled(vm.isLoading)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut, value: vm.isStepCompleted(.generatingSchedule))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Error Card
    private func errorCard(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.title3)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding(16)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Loader Overlay
    private var loaderOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Processing...")
                    .foregroundColor(.white)
                    .font(.headline)
                    .fontWeight(.medium)
                
                if vm.currentStep != .idle {
                    Text(vm.currentStep.description)
                        .foregroundColor(.white.opacity(0.8))
                        .font(.subheadline)
                }
            }
            .padding(24)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}
