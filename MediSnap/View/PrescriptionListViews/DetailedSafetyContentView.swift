//
//  DetailedSafetyContentView.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//
import SwiftUI

struct DetailedSafetyContentView: View {
    let safetyResponse: SafetyResponse
    @State private var selectedMedicationIndex = 0
    @State private var isDisclaimerExpanded = true // Start expanded for safety
    
    var body: some View {
        VStack(spacing: 0) {
            // Medical disclaimer banner (collapsible)
            medicalDisclaimerBanner
            
            // Medication picker (horizontal scroll)
            if safetyResponse.medications.count > 1 {
                medicationPicker
            }
            
            // Selected medication safety details
            if selectedMedicationIndex < safetyResponse.medications.count {
                let currentMedication = safetyResponse.medications[selectedMedicationIndex]
                DetailedMedicationSafetyCard(medication: currentMedication)
                    .animation(.easeInOut(duration: 0.3), value: selectedMedicationIndex)
            }
        }
    }
    
    private var medicalDisclaimerBanner: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isDisclaimerExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.red)
                        .font(.title2)
                    
                    Text("Medical Disclaimer")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Emergency") {
                        if let url = URL(string: "tel://911") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .onTapGesture { } // Prevent parent button tap
                    
                    Image(systemName: isDisclaimerExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable content
            if isDisclaimerExpanded {
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.red.opacity(0.3))
                    
                    Text(safetyResponse.generalWarning)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.red.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.red.opacity(0.3)),
            alignment: .bottom
        )
        .cornerRadius(12)
    }
    
    private var medicationPicker: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Select Medication:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(selectedMedicationIndex + 1) of \(safetyResponse.medications.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(safetyResponse.medications.enumerated()), id: \.offset) { index, medication in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedMedicationIndex = index
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "pills.fill")
                                    .font(.title2)
                                    .foregroundColor(selectedMedicationIndex == index ? .white : .blue)
                                
                                Text(medication.medicationName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(selectedMedicationIndex == index ? .white : .primary)
                                
                                // Safety info summary
                                HStack(spacing: 4) {
                                    if !medication.seriousSideEffects.isEmpty {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption2)
                                            .foregroundColor(selectedMedicationIndex == index ? .white : .red)
                                    }
                                    
                                    Text("\(medication.commonSideEffects.count + medication.seriousSideEffects.count) effects")
                                        .font(.caption2)
                                        .foregroundColor(selectedMedicationIndex == index ? .white.opacity(0.8) : .secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(minWidth: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedMedicationIndex == index ? Color.blue : Color(.systemGray6))
                                    .shadow(
                                        color: selectedMedicationIndex == index ? Color.blue.opacity(0.3) : Color.clear,
                                        radius: selectedMedicationIndex == index ? 4 : 0,
                                        x: 0,
                                        y: selectedMedicationIndex == index ? 2 : 0
                                    )
                            )
                        }
                        .scaleEffect(selectedMedicationIndex == index ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedMedicationIndex == index)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .padding(.bottom, 8)
    }
}
