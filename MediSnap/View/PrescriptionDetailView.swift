//
//  PrescriptionDetailView.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//


import SwiftUI

struct PrescriptionDetailView: View {
    let prescription: CompletePrescription
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab: DetailTab = .medications
    
    enum DetailTab: String, CaseIterable {
        case medications = "Medications"
        case schedule = "Schedule"
        case safety = "Safety Info"
        case calendar = "Calendar"
        case flags = "Flags"
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.teal.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with prescription info
                prescriptionHeader
                
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                ScrollView {
                    LazyVStack(spacing: 20) {
                        switch selectedTab {
                        case .medications:
                            medicationsView
                        case .schedule:
                            scheduleView
                        case .safety:
                            safetyView
                        case .calendar:
                            calendarView
                        case .flags:
                            flagsView
                        }
                    }
                    .padding()
                }
            }
            .background(backgroundGradient.ignoresSafeArea())
            .navigationTitle("Prescription Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var prescriptionHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Prescription ID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(prescription.id.prefix(8) + "...")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Date Created")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(prescription.date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            if let status = prescription.status {
                HStack {
                    Text("Status:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    if let lastUpdated = prescription.lastUpdated {
                        Text("Updated: \(lastUpdated, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 2)
    }
    
    private var statusColor: Color {
        switch prescription.status?.lowercased() {
        case "completed": return .green
        case "safety_analyzed": return .blue
        case "scheduled": return .orange
        case "extracted": return .yellow
        default: return .gray
        }
    }
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: iconForTab(tab))
                                .font(.title3)
                            
                            Text(tab.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedTab == tab ? Color.blue : Color(.systemGray6)
                        )
                        .foregroundColor(
                            selectedTab == tab ? .white : .primary
                        )
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    private func iconForTab(_ tab: DetailTab) -> String {
        switch tab {
        case .medications: return "pills.fill"
        case .schedule: return "clock.fill"
        case .safety: return "shield.fill"
        case .calendar: return "calendar.badge.clock"
        case .flags: return "flag.fill"
        }
    }
    
    private var medicationsView: some View {
        VStack(spacing: 16) {
            ForEach(prescription.medications) { medication in
                MedicationDetailCard(medication: medication)
            }
        }
    }
    
    private var scheduleView: some View {
        VStack(spacing: 16) {
            if let schedule = prescription.schedule, !schedule.isEmpty {
                ForEach(Array(schedule.enumerated()), id: \.offset) { index, scheduleItem in
                    ScheduleDetailCard(schedule: scheduleItem)
                }
            } else {
                EmptyStateView(
                    icon: "clock.badge.exclamationmark",
                    title: "No Schedule Available",
                    description: "This prescription doesn't have a medication schedule yet."
                )
            }
        }
    }
    
    private var safetyView: some View {
        VStack(spacing: 16) {
            if let safetyInfo = prescription.safetyInfo, !safetyInfo.medications.isEmpty {
                SafetyInfoSummaryCard(safetyResponse: safetyInfo)
            } else {
                EmptyStateView(
                    icon: "shield.slash",
                    title: "No Safety Information",
                    description: "Safety information hasn't been generated for this prescription yet."
                )
            }
        }
    }
    
    private var calendarView: some View {
        VStack(spacing: 16) {
            if let calendarEvents = prescription.calendarEventIds, !calendarEvents.isEmpty {
                CalendarEventsCard(eventIds: calendarEvents)
            } else {
                EmptyStateView(
                    icon: "calendar.badge.exclamationmark",
                    title: "No Calendar Events",
                    description: "This prescription hasn't been added to your calendar yet."
                )
            }
        }
    }
    
    
    
    private var flagsView: some View {
        VStack(spacing: 16) {
            if let flags = prescription.flags, !flags.isEmpty {
                ForEach(Array(flags.enumerated()), id: \.offset) { index, flag in
                    FlagCard(flag: flag)
                }
            } else {
                EmptyStateView(
                    icon: "checkmark.shield",
                    title: "No Flags",
                    description: "No medication flags or warnings have been identified."
                )
            }
        }
    }
}

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

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

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

struct SafetyInfoSummaryCard: View {
    let safetyResponse: SafetyResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("Safety Information")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            Text(safetyResponse.generalWarning)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(safetyResponse.medications.enumerated()), id: \.offset) { index, medication in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medication.medicationName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            SafetyBadge(
                                text: "Side Effects: \(medication.commonSideEffects.count)",
                                color: .blue
                            )
                            
                            SafetyBadge(
                                text: "Serious: \(medication.seriousSideEffects.count)",
                                color: .red
                            )
                            
                            SafetyBadge(
                                text: "Interactions: \(medication.drugInteractions.count)",
                                color: .orange
                            )
                        }
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

struct SafetyBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

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

struct ChecklistItemCard: View {
    let item: ChecklistItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text(item.medName)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Scheduled Times:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct FlagCard: View {
    let flag: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("Medication Flag")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(flag.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key.capitalized + ":")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let value = flag[key] as? String {
                            Text(value)
                                .font(.subheadline)
                        } else if let value = flag[key] as? [String] {
                            Text(value.joined(separator: ", "))
                                .font(.subheadline)
                        } else {
                            Text(String(describing: flag[key] ?? ""))
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    PrescriptionDetailView(prescription: CompletePrescription(
        id: "sample-id",
        date: Date(),
        medications: [
            Medication(name: "Amoxicillin", dosage: "500mg", frequency: "3 times daily", duration: "10 days", route: "Oral", originalText: "", confidence: 0.95, uncertain: false)
        ],
        userId: "user-id",
        status: "completed",
        createdAt: Date(),
        lastUpdated: Date(),
        schedule: nil,
        safetyInfo: nil,
        calendarEventIds: nil,
        flags: nil
    ))
}
