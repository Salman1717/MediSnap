//
//  ScheduleDetailCard.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//
import SwiftUI

struct ScheduleDetailCard: View {
    let schedule: MedicationSchedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text(schedule.med.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            if schedule.reminders.isEmpty {
                Text("No reminders set")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scheduled Reminders:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(schedule.reminders.enumerated()), id: \.offset) { index, reminder in
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            
                            Text(reminder, style: .time)
                                .font(.subheadline)
                            
                            Text("on")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(reminder, style: .date)
                                .font(.subheadline)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
