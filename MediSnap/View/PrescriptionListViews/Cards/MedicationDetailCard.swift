//
//  MedicationDetailCard.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//
import SwiftUI

struct MedicationDetailCard: View {
    let medication: Medication
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pill.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text(medication.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if medication.uncertain {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if let dosage = medication.dosage, !dosage.isEmpty {
                    DetailRow(label: "Dosage", value: dosage)
                }
                
                if let frequency = medication.frequency, !frequency.isEmpty {
                    DetailRow(label: "Frequency", value: frequency)
                }
                
                if let duration = medication.duration, !duration.isEmpty {
                    DetailRow(label: "Duration", value: duration)
                }
                
                if let route = medication.route, !route.isEmpty {
                    DetailRow(label: "Route", value: route)
                }
                
                DetailRow(label: "Confidence", value: String(format: "%.1f%%", (medication.confidence ?? 0) * 100))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
