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

// Rest of the existing views remain the same...
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
