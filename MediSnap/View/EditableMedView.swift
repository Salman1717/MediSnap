// EditableMedicationsView.swift
import SwiftUI

struct EditableMedicationsView: View {
    @ObservedObject var vm: ExtractViewModel
    
    @State private var isSaving = false
    @State private var showAgentPrompt = false
    @State private var savedPrescriptionId: String?
    @State private var lastSavedPrescription: Prescription?
    @State private var showAgentFlow = false
    
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
                Button(action: {
                    Task {
                        isSaving = true
                        await vm.saveAndRunAgent()
                        isSaving = false
                        // present agent flow UI (vm.runningAgentPrescription gets set if saved succeeded)
                        if vm.runningAgentPrescription != nil {
                            showAgentFlow = true
                        }
                    }
                }) {
                    if isSaving {
                        ProgressView().padding(.vertical, 8)
                    } else {
                        Text("Save & Setup (Agent)")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isSaving || vm.medications.isEmpty)
                .buttonStyle(.borderedProminent)
                
                Button("Save only") {
                    Task {
                        isSaving = true
                        do {
                            _ = try await vm.savePrescriptionOnly()
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
        .sheet(isPresented: $showAgentFlow, onDismiss: {
            // optionally reset vm.runningAgentPrescription
            vm.runningAgentPrescription = nil
        }) {
            if let pres = vm.runningAgentPrescription {
                AgenticFlowView(prescription: pres)
            } else {
                Text("No prescription")
            }
        }
    }
}
