//
//  EditableScheduleConfirmationView.swift
//  MediSnap
//

import SwiftUI

struct EditableScheduleConfirmationView: View {
    @ObservedObject var vm: ExtractViewModel
    @ObservedObject var geminiService = GeminiService.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isSaving = false
    @State private var isAddingToCalendar = false
    @State private var showSuccessAlert = false
    @State private var showCalendarSuccessAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                        HStack(spacing: 12) {
                            Button(action: {
                                Task {
                                    isSaving = true
                                    await vm.saveScheduleToFirestore()
                                    isSaving = false
                                    if vm.errorMessage == nil {
                                        showSuccessAlert = true
                                    }
                                }
                            }) {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                    Text("Confirm & Save Schedule")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSaving)
                        }
                        
                        Button(action: {
                            Task {
                                isAddingToCalendar = true
                                await vm.addScheduleToGoogleCalendar()
                                isAddingToCalendar = false
                                if vm.errorMessage == nil {
                                    showCalendarSuccessAlert = true
                                }
                            }
                        }) {
                            HStack {
                                if isAddingToCalendar {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "calendar.badge.plus")
                                }
                                Text("Add to Google Calendar")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isAddingToCalendar)
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
            }
        }
        .alert("Schedule Saved!", isPresented: $showSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your medication schedule has been saved successfully.")
        }
        .alert("Added to Calendar!", isPresented: $showCalendarSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Your medication reminders have been added to Google Calendar successfully.")
        }
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
