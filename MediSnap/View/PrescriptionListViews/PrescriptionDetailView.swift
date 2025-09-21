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
                            detailedSafetyView
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
    
    // NEW: Detailed Safety View (no longer in sheet)
    private var detailedSafetyView: some View {
        VStack(spacing: 16) {
            if let safetyInfo = prescription.safetyInfo, !safetyInfo.medications.isEmpty {
                DetailedSafetyContentView(safetyResponse: safetyInfo)
            } else {
                EmptyStateView(
                    icon: "shield.slash",
                    title: "No Safety Information",
                    description: "Safety information hasn't been generated for this prescription yet."
                )
            }
        }
    }
    
    // NEW: Detailed Safety Content View with Medication Picker
    
    
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
