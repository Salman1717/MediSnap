//
//  EditableMedicationsView.swift
//  MediSnap
//
//  Created by Aaseem Mhaskar on 20/09/25.
//

import SwiftUI

struct EditableMedicationsView: View {
    @ObservedObject var vm: ExtractViewModel

    var body: some View {
        VStack(spacing: 12) {
            if let date = vm.prescriptionDate {
                HStack {
                    Text("Prescription Date:")
                    Spacer()
                    Text(date, style: .date)
                        .foregroundColor(.secondary)
                }
                .padding()
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
        }
        .navigationTitle("Editable Medications")
    }
}
