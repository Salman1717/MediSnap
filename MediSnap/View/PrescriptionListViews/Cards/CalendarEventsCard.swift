//
//  CalendarEventsCard.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//

import SwiftUI

struct CalendarEventsCard: View {
    let eventIds: [String: [String]]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Calendar Events")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                let totalEvents = eventIds.values.flatMap { $0 }.count
                Text("Total events created: \(totalEvents)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(Array(eventIds.keys.sorted()), id: \.self) { key in
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text(key)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(eventIds[key]?.count ?? 0) events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
