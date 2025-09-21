import SwiftUI

struct EditableScheduleConfirmationView: View {
    @ObservedObject var vm: ExtractViewModel
    @ObservedObject var geminiService = GeminiService.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showSuccessAlert = false
    @State private var showStepProgress = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Step Progress Indicator (when flow is running)
                if vm.isLoading && vm.currentStep != .idle {
                    stepProgressView
                        .padding()
                        .background(Color(.systemGray6))
                }
                
                if geminiService.medicationSchedule.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No schedule generated yet.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Please try generating the schedule again.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else {
                    // Schedule list
                    List {
                        ForEach(0..<geminiService.medicationSchedule.count, id: \.self) { index in
                            EditableScheduleRow(
                                schedule: Binding(
                                    get: { geminiService.medicationSchedule[index] },
                                    set: { geminiService.medicationSchedule[index] = $0 }
                                )
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        // Primary Action: Complete Flow Button
                        Button(action: {
                            Task {
                                await vm.executeCompleteFlow()
                                if vm.errorMessage == nil {
                                    showSuccessAlert = true
                                }
                            }
                        }) {
                            HStack {
                                if vm.isLoading && vm.currentStep != .idle {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text(vm.currentStep.description)
                                } else {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text("Complete All Steps")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.isLoading)
                        
                        // Divider
                        Text("Or do individual steps:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Individual action buttons (secondary actions)
                        HStack(spacing: 8) {
                            Button(action: {
                                Task {
                                    await vm.saveScheduleOnly()
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: vm.isStepCompleted(.savingAll) ? "checkmark.circle.fill" : "square.and.arrow.down")
                                        .foregroundColor(vm.isStepCompleted(.savingAll) ? .green : .blue)
                                    Text("Save Schedule")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .disabled(vm.isLoading)
                            
                            Button(action: {
                                Task {
                                    await vm.addToCalendarOnly()
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: vm.isStepCompleted(.addingToCalendar) ? "checkmark.circle.fill" : "calendar.badge.plus")
                                        .foregroundColor(vm.isStepCompleted(.addingToCalendar) ? .green : .blue)
                                    Text("Add Calendar")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .disabled(vm.isLoading)
                            
                            Button(action: {
                                Task {
                                    await vm.generateSafetyInfoOnly()
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: vm.isStepCompleted(.generatingSafetyInfo) ? "checkmark.circle.fill" : "shield.fill")
                                        .foregroundColor(vm.isStepCompleted(.generatingSafetyInfo) ? .green : .orange)
                                    Text("Safety Info")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .disabled(vm.isLoading)
                        }
                        
                        // Note about viewing safety information
                        if vm.isStepCompleted(.generatingSafetyInfo) || vm.currentStep == .completed {
                            VStack(spacing: 8) {
                                Divider()
                                
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                    
                                    Text("Safety information has been generated. View it in the prescription history after completion.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                }
                
                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle("Confirm Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        vm.resetFlow()
                    }
                    .font(.caption)
                    .disabled(vm.isLoading)
                }
            }
        }
        .alert("All Steps Completed!", isPresented: $showSuccessAlert) {
            Button("View in History") {
                // Navigate to prescription history where they can view detailed safety info
                presentationMode.wrappedValue.dismiss()
            }
            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your medication schedule has been saved, added to calendar, and safety information has been generated. View detailed safety information in your prescription history.")
        }
    }
    
    // Step Progress View
    private var stepProgressView: some View {
        VStack(spacing: 12) {
            Text(vm.currentStep.description)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 8) {
                stepIndicator(.generatingSchedule, title: "Schedule")
                
                progressArrow(vm.isStepCompleted(.generatingSchedule))
                
                stepIndicator(.addingToCalendar, title: "Calendar")
                
                progressArrow(vm.isStepCompleted(.addingToCalendar))
                
                stepIndicator(.generatingSafetyInfo, title: "Safety")
                
                progressArrow(vm.isStepCompleted(.generatingSafetyInfo))
                
                stepIndicator(.savingAll, title: "Save")
            }
            
            ProgressView(value: progressValue, total: 4.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .animation(.easeInOut, value: progressValue)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func stepIndicator(_ step: ExtractViewModel.ProcessingStep, title: String) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(stepColor(step))
                .frame(width: 24, height: 24)
                .overlay(
                    Group {
                        if vm.isStepCompleted(step) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(.white)
                        } else if vm.currentStep == step {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                    }
                )
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func progressArrow(_ completed: Bool) -> some View {
        Image(systemName: "arrow.right")
            .font(.caption2)
            .foregroundColor(completed ? .green : .gray)
    }
    
    private func stepColor(_ step: ExtractViewModel.ProcessingStep) -> Color {
        if vm.isStepCompleted(step) {
            return .green
        } else if vm.currentStep == step {
            return .blue
        } else {
            return .gray
        }
    }
    
    private var progressValue: Double {
        let completedCount = vm.completedSteps.count
        return Double(completedCount)
    }
}

struct EditableScheduleRow: View {
    @Binding var schedule: MedicationSchedule
    @State private var showingAddReminder = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Medication header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.med.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let dosage = schedule.med.dosage, !dosage.isEmpty {
                        Text("Dosage: \(dosage)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let frequency = schedule.med.frequency, !frequency.isEmpty {
                        Text("Frequency: \(frequency)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    addNewReminder()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // Reminders section
            if schedule.reminders.isEmpty {
                Text("No reminders set")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(schedule.reminders.enumerated()), id: \.offset) { index, reminder in
                        HStack(spacing: 12) {
                            DatePicker(
                                "Reminder \(index + 1)",
                                selection: Binding(
                                    get: { schedule.reminders[index] },
                                    set: { schedule.reminders[index] = $0 }
                                ),
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            
                            Button(action: {
                                removeReminder(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func addNewReminder() {
        let newReminder = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        schedule.reminders.append(newReminder)
    }
    
    private func removeReminder(at index: Int) {
        guard index < schedule.reminders.count else { return }
        schedule.reminders.remove(at: index)
    }
}

#Preview {
    EditableScheduleConfirmationView(vm: ExtractViewModel())
}
