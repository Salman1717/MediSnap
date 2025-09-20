//
//  EditableMedicationsView.swift
//  MediSnap
//
//  Created by Aaseem Mhaskar on 20/09/25.
//

import SwiftUI

struct Medication1: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var dosage: String?
    var frequency: String?
    var duration: String?
    var route: String?
    var originalText: String?
    var confidence: Double?
    var uncertain: Bool = false
    var plainExplanation: String?
    var tips: [String]?
}

struct EditableMedicationsView: View {
    // Placeholder medications list (UI only)
    @State private var medications: [Medication1] = [
        Medication1(name: "Paracetamol", dosage: "500mg", frequency: "3x/day", duration: "5 days", route: "Oral", originalText: "Paracetamol 500mg TDS 5 days", uncertain: false, plainExplanation: "Pain relief", tips: ["Take after food"]),
        Medication1(name: "Ibuprofen", dosage: "200mg", frequency: "2x/day", duration: "7 days", route: "Oral", originalText: "Ibuprofen 200mg BD 7 days", uncertain: true, plainExplanation: "Anti-inflammatory", tips: ["Avoid on empty stomach"]),
        Medication1(name: "Amoxicillin", dosage: "250mg", frequency: "3x/day", duration: "10 days", route: "Oral", originalText: "Amoxicillin 250mg TDS 10 days", uncertain: false, plainExplanation: "Antibiotic", tips: ["Complete full course"])
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Medications")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            List {
                ForEach($medications) { $med in
                    VStack(alignment: .leading, spacing: 8) {
                        
                        HStack {
                            TextField("Medication Name", text: $med.name)
                                .textFieldStyle(.roundedBorder)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(med.uncertain ? Color.orange : Color.clear, lineWidth: 2)
                                )
                            
                            Spacer()
                            
                            if med.uncertain {
                                Text("Check")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(6)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        
                        HStack {
                            TextField("Dosage", text: Binding(
                                get: { med.dosage ?? "" },
                                set: { med.dosage = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            
                            TextField("Frequency", text: Binding(
                                get: { med.frequency ?? "" },
                                set: { med.frequency = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack {
                            TextField("Duration", text: Binding(
                                get: { med.duration ?? "" },
                                set: { med.duration = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            
                            TextField("Route", text: Binding(
                                get: { med.route ?? "" },
                                set: { med.route = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                        
                        if let original = med.originalText {
                            Text("Original: \(original)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if let explanation = med.plainExplanation {
                            Text("Explanation: \(explanation)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if let tips = med.tips, !tips.isEmpty {
                            VStack(alignment: .leading) {
                                ForEach(tips, id: \.self) { tip in
                                    Text("• \(tip)")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            
            // Confirm & Save Button
            Button(action: {
                print("Confirm & Save tapped")
                // TODO: call ViewModel save method
            }) {
                Text("Confirm & Save")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// Helper to bind optional strings to TextField
extension Binding where Value == String? {
    init(_ source: Binding<String?>, default defaultValue: String) {
        self.init(get: { source.wrappedValue ?? defaultValue },
                  set: { source.wrappedValue = $0 })
    }
}

#Preview {
    EditableMedicationsView()
}
