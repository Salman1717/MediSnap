// EditableMedicationsView.swift
import SwiftUI

struct EditableMedicationsView: View {
    @ObservedObject var vm: ExtractViewModel

    @State private var isSaving = false
    @State private var showAgentPrompt = false
    @State private var savedPrescriptionId: String?
    @State private var lastSavedPrescription: Prescription?

    var body: some View {
        VStack(spacing: 12) {
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

            HStack(spacing: 12) {
                Button(action: { Task { await saveAndPromptAgent() }}) {
                    if isSaving {
                        ProgressView().padding(.vertical, 8)
                    } else {
                        Text("Save & Setup")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isSaving || vm.medications.isEmpty)
                .buttonStyle(.borderedProminent)

                Button("Save") {
                    Task {
                        isSaving = true
                        do {
                            _ = try await vm.savePrescription()
                            // simple success feedback
                        } catch {
                            vm.errorMessage = error.localizedDescription
                        }
                        isSaving = false
                    }
                }
                .disabled(isSaving || vm.medications.isEmpty)
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("Editable Medications")
        // Alert-like confirmation sheet (iOS 15+ sheet style)
        .confirmationDialog("Setup agentic actions for prescription \(savedPrescriptionId ?? "")?", isPresented: $showAgentPrompt, titleVisibility: .visible) {
            Button("Yes — run agent") {
                if let pres = lastSavedPrescription {
//                    Task { await AgenticManager.shared.startFlow(prescription: pres) }
                }
            }
            Button("No, later", role: .cancel) { }
        } message: {
            Text("AI can automatically set up reminders, checklist and a shareable summary for this prescription.")
        }
    }

    // Save then display prompt to run agent
    private func saveAndPromptAgent() async {
        isSaving = true
        do {
            let saved = try await vm.savePrescription()
            lastSavedPrescription = saved
            savedPrescriptionId = saved.id
            // Show confirmation to run the agent
            showAgentPrompt = true
        } catch {
            vm.errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
