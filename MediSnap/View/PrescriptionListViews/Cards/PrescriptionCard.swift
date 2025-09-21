import SwiftUI

struct EnhancedPrescriptionCard: View {
    let prescription: CompletePrescription
    let onTapAction: () -> Void
    @State private var isExpanded: Bool = false
    
    var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.7), Color.teal.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var statusColor: Color {
        switch prescription.status?.lowercased() {
        case "completed": return .green
        case "safety_analyzed": return .blue
        case "scheduled": return .orange
        case "extracted": return .yellow
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prescription")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(prescription.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Status indicator
                if let status = prescription.status {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                
                Text("\(prescription.medications.count) Meds")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.leading, 8)
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.white)
                    .padding(.leading, 8)
            }
            .padding()
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.5))
                    
                    // Medications list
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Medications:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        ForEach(prescription.medications) { med in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(med.name)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    if let dosage = med.dosage, !dosage.isEmpty {
                                        Text(dosage)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                Spacer()
                                if let frequency = med.frequency, !frequency.isEmpty {
                                    Text(frequency)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Data summary
                    HStack {
                        DataSummaryItem(
                            icon: "clock.fill",
                            title: "Schedule",
                            count: prescription.schedule?.count ?? 0,
                            color: .yellow
                        )
                        
                        Spacer()
                        
                        DataSummaryItem(
                            icon: "shield.fill",
                            title: "Safety Info",
                            count: prescription.safetyInfo?.medications.count ?? 0,
                            color: .red
                        )
                        
                        Spacer()
                        
                        DataSummaryItem(
                            icon: "calendar.badge.clock",
                            title: "Reminders",
                            count: prescription.calendarEventIds?.values.flatMap { $0 }.count ?? 0,
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // View Details Button
                    Button(action: onTapAction) {
                        HStack {
                            Image(systemName: "eye.fill")
                            Text("View Complete Details")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
        .padding(.horizontal)
    }
}

struct DataSummaryItem: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}
