//
//  DetailedMedicationSafetyCard.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//

import SwiftUI

// NEW: Detailed Medication Safety Card
struct DetailedMedicationSafetyCard: View {
    let medication: MedicationSafetyInfo
    @State private var expandedSections: Set<SafetySection> = []
    
    enum SafetySection: String, CaseIterable {
        case emergency = "Emergency Information"
        case commonSideEffects = "Common Side Effects"
        case precautions = "Important Precautions"
        case foodInteractions = "Food & Dietary Guidelines"
        case drugInteractions = "Drug Interactions"
        case contraindications = "Contraindications"
        case generalAdvice = "General Advice"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Medication header
            HStack {
                Image(systemName: "pill.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title)
                
                Text(medication.medicationName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Emergency section (always visible)
            if !medication.seriousSideEffects.isEmpty || !medication.whenToSeekHelp.isEmpty {
                emergencySection
            }
            
            // Other safety sections (expandable)
            ForEach(SafetySection.allCases.filter { $0 != .emergency }, id: \.self) { section in
                if let items = itemsForSection(section), !items.isEmpty {
                    safetySection(
                        section: section,
                        items: items,
                        isExpanded: expandedSections.contains(section)
                    ) {
                        toggleSection(section)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            // Start with emergency section expanded
            expandedSections.insert(.emergency)
        }
    }
    
    private var emergencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("⚠️ URGENT - When to Seek Help")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Spacer()
            }
            
            HStack {
                Text("Call 911 or go to ER immediately if you experience:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Call 911") {
                    if let url = URL(string: "tel://911") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if !medication.seriousSideEffects.isEmpty {
                    Text("Serious Side Effects:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    ForEach(Array(medication.seriousSideEffects.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 2)
                            
                            Text(item)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                }
                
                if !medication.whenToSeekHelp.isEmpty {
                    Text("When to Contact Healthcare Provider:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                    
                    ForEach(Array(medication.whenToSeekHelp.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "cross.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 2)
                            
                            Text(item)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.4), lineWidth: 2)
        )
    }
    
    private func safetySection(
        section: SafetySection,
        items: [String],
        isExpanded: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggle) {
                HStack {
                    Image(systemName: iconForSection(section))
                        .foregroundColor(colorForSection(section))
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(subtitleForSection(section))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(colorForSection(section).opacity(0.7))
                                .frame(width: 8, height: 8)
                                .padding(.top, 4)
                            
                            Text(item)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
            }
        }
        .padding()
        .background(colorForSection(section).opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorForSection(section).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func itemsForSection(_ section: SafetySection) -> [String]? {
        switch section {
        case .emergency:
            return nil // Handled separately
        case .commonSideEffects:
            return medication.commonSideEffects.isEmpty ? nil : medication.commonSideEffects
        case .precautions:
            return medication.precautions.isEmpty ? nil : medication.precautions
        case .foodInteractions:
            return medication.foodInteractions.isEmpty ? nil : medication.foodInteractions
        case .drugInteractions:
            return medication.drugInteractions.isEmpty ? nil : medication.drugInteractions
        case .contraindications:
            return medication.contraindications.isEmpty ? nil : medication.contraindications
        case .generalAdvice:
            return medication.generalAdvice.isEmpty ? nil : medication.generalAdvice
        }
    }
    
    private func iconForSection(_ section: SafetySection) -> String {
        switch section {
        case .emergency: return "exclamationmark.triangle.fill"
        case .commonSideEffects: return "info.circle.fill"
        case .precautions: return "shield.fill"
        case .foodInteractions: return "fork.knife.circle.fill"
        case .drugInteractions: return "pills.fill"
        case .contraindications: return "x.circle.fill"
        case .generalAdvice: return "lightbulb.fill"
        }
    }
    
    private func colorForSection(_ section: SafetySection) -> Color {
        switch section {
        case .emergency: return .red
        case .commonSideEffects: return .blue
        case .precautions: return .orange
        case .foodInteractions: return .green
        case .drugInteractions: return .purple
        case .contraindications: return .red
        case .generalAdvice: return .yellow
        }
    }
    
    private func subtitleForSection(_ section: SafetySection) -> String {
        switch section {
        case .emergency: return "Immediate medical attention required"
        case .commonSideEffects: return "Usually mild and may go away as your body adjusts"
        case .precautions: return "Please follow these guidelines carefully"
        case .foodInteractions: return "How to take this medication with food"
        case .drugInteractions: return "Medications that may interact with this drug"
        case .contraindications: return "Conditions where this medication should be avoided"
        case .generalAdvice: return "Tips for safe and effective use"
        }
    }
    
    private func toggleSection(_ section: SafetySection) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
}
