import SwiftUI

struct MedicationSafetyView: View {
    let medications: [Medication]
    let prescriptionId: String? // NEW: Add prescription ID to load cached data
    @Environment(\.presentationMode) var presentationMode
    
    @State private var safetyInfo: SafetyResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedMedicationIndex = 0
    
    // NEW: Initialize with optional prescription ID
    init(medications: [Medication], prescriptionId: String? = nil) {
        self.medications = medications
        self.prescriptionId = prescriptionId
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    LoadingView()
                } else if let error = errorMessage {
                    ErrorView(error: error) {
                        loadSafetyInformation()
                    }
                } else if let safety = safetyInfo {
                    SafetyContentView(
                        safetyResponse: safety,
                        selectedIndex: $selectedMedicationIndex
                    )
                }
            }
            .navigationTitle("Safety Information")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Emergency") {
                        if let url = URL(string: "tel://911") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(.red)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadSafetyInformation()
        }
    }
    
    // NEW: Enhanced loading with Firestore cache check
    private func loadSafetyInformation() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                var safety: SafetyResponse?
                
                // First, try to load from Firestore cache if prescription ID is available
                if let presId = prescriptionId {
                    safety = try await FirebaseService.shared.getSafetyInformation(prescriptionId: presId)
                }
                
                // If not found in cache, generate new safety information
                if safety == nil {
                    safety = try await GeminiService.shared.getSafetyInformation(for: medications)
                    
                    // Save to cache for future use if prescription ID is available
                    if let presId = prescriptionId, let safetyResponse = safety {
                        try? await FirebaseService.shared.saveSafetyInformation(
                            prescriptionId: presId,
                            safetyResponse: safetyResponse
                        )
                    }
                }
                
                await MainActor.run {
                    self.safetyInfo = safety
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// Rest of the views remain the same...
struct SafetyContentView: View {
    let safetyResponse: SafetyResponse
    @Binding var selectedIndex: Int
    
    var body: some View {
        VStack(spacing: 0) {
            medicalDisclaimerBanner
            
            if safetyResponse.medications.count > 1 {
                medicationPicker
            }
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    if selectedIndex < safetyResponse.medications.count {
                        let currentMed = safetyResponse.medications[selectedIndex]
                        medicationSafetyContent(for: currentMed)
                    }
                }
                .padding()
            }
        }
    }
    
    private var medicalDisclaimerBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("Medical Disclaimer")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            Text(safetyResponse.generalWarning)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.red.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    private var medicationPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(safetyResponse.medications.enumerated()), id: \.offset) { index, medication in
                    Button(action: {
                        selectedIndex = index
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "pills.fill")
                                .font(.title2)
                            
                            Text(medication.medicationName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            selectedIndex == index ? Color.blue : Color(.systemGray6)
                        )
                        .foregroundColor(
                            selectedIndex == index ? .white : .primary
                        )
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    private func medicationSafetyContent(for medication: MedicationSafetyInfo) -> some View {
        VStack(spacing: 20) {
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
            
            if !medication.seriousSideEffects.isEmpty || !medication.whenToSeekHelp.isEmpty {
                EmergencySection(medication: medication)
            }
            
            if !medication.commonSideEffects.isEmpty {
                SafetySection(
                    title: "Common Side Effects",
                    subtitle: "These are usually mild and may go away as your body adjusts",
                    icon: "info.circle.fill",
                    color: .blue,
                    items: medication.commonSideEffects
                )
            }
            
            if !medication.precautions.isEmpty {
                SafetySection(
                    title: "Important Precautions",
                    subtitle: "Please follow these guidelines carefully",
                    icon: "shield.fill",
                    color: .orange,
                    items: medication.precautions
                )
            }
            
            if !medication.foodInteractions.isEmpty {
                SafetySection(
                    title: "Food & Dietary Guidelines",
                    subtitle: "How to take this medication with food",
                    icon: "fork.knife.circle.fill",
                    color: .green,
                    items: medication.foodInteractions
                )
            }
            
            if !medication.drugInteractions.isEmpty {
                SafetySection(
                    title: "Drug Interactions",
                    subtitle: "Medications that may interact with this drug",
                    icon: "pills.fill",
                    color: .purple,
                    items: medication.drugInteractions
                )
            }
            
            if !medication.contraindications.isEmpty {
                SafetySection(
                    title: "Do Not Use If You Have:",
                    subtitle: "Conditions where this medication should be avoided",
                    icon: "x.circle.fill",
                    color: .red,
                    items: medication.contraindications
                )
            }
            
            if !medication.generalAdvice.isEmpty {
                SafetySection(
                    title: "Helpful Tips",
                    subtitle: "General advice for safe and effective use",
                    icon: "lightbulb.fill",
                    color: .yellow,
                    items: medication.generalAdvice
                )
            }
        }
    }
}

struct EmergencySection: View {
    let medication: MedicationSafetyInfo
    
    var body: some View {
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
            
            if !medication.seriousSideEffects.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
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
            }
            
            if !medication.whenToSeekHelp.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
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
}

struct SafetySection: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let items: [String]
    
    init(title: String, subtitle: String? = nil, icon: String, color: Color, items: [String]) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.items = items
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(color.opacity(0.7))
                            .frame(width: 8, height: 8)
                            .padding(.top, 4)
                        
                        Text(item)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(color.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Image(systemName: "pill.fill")
                        .font(.title)
                        .foregroundColor(.blue.opacity(0.7))
                        .scaleEffect(1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: true
                        )
                }
            }
            
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Analyzing Medication Safety")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Please wait while we gather comprehensive safety information about your medications from our medical database.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Unable to Load Safety Information")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                Button("Try Again") {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Contact Support") {
                    // Add support contact functionality
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    MedicationSafetyView(medications: [
        Medication(name: "Amoxicillin", dosage: "500mg", frequency: "3 times daily", duration: "10 days", route: "Oral", originalText: "", confidence: 1.0, uncertain: false),
        Medication(name: "Ibuprofen", dosage: "400mg", frequency: "As needed", duration: "5 days", route: "Oral", originalText: "", confidence: 1.0, uncertain: false)
    ], prescriptionId: "sample-prescription-id")
}
