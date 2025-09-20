import SwiftUI

struct PrescriptionCard: View {
    let prescription: Prescription
    @State private var isExpanded: Bool = false

    var cardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.7), Color.teal.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

                Text("\(prescription.medications.count) Meds")
                    .font(.subheadline)
                    .foregroundColor(.white)

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
                    
                    ForEach(prescription.medications) { med in
                        HStack {
                            Text(med.name)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Spacer()
                            Text(med.dosage ?? "")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal)
                    }
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


