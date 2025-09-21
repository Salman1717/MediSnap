import SwiftUI
import CoreLocation
import UserNotifications
import PhotosUI
import SwiftfulLoadingIndicators

struct RadiologyAnalysisView: View {
    @StateObject private var analysisService = RadiologyAnalysisService.shared
    @StateObject private var doctorService = DoctorDirectoryService.shared
    @StateObject private var locationManager = LocationManager()
    
    // Image picker state - Updated to match ExtractView
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false
    
    // Privacy consent
    @State private var showPrivacyConsent = true
    @State private var hasLocationPermission = false
    @State private var hasDataPermission = false
    
    @Environment(\.presentationMode) private var presentationMode
    
    var gradientBackground: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.5), Color.teal.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.white).ignoresSafeArea()
                gradientBackground.ignoresSafeArea()
                
                if showPrivacyConsent {
                    privacyConsentView
                } else {
                    mainContentView
                }
                
                // Loading overlay
                if isLoading {
                    loaderOverlay
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
            }
            .onChange(of: selectedItem) { _, newItem in
                handleGallerySelection(newItem)
            }
            .onChange(of: selectedImage) { _, newImage in
                handleCameraImage(newImage)
            }
        }
    }
    
    // MARK: - Privacy Consent View
    private var privacyConsentView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Radiology Report Analysis")
                    .foregroundStyle(.blue)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                   
                
                Text("AI-powered analysis of your medical reports")
                    .font(.subheadline)
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                consentItem(
                    icon: "location.fill",
                    title: "Location Access",
                    description: "To find nearby specialists based on your report",
                    isEnabled: $hasLocationPermission
                )
                
                consentItem(
                    icon: "doc.text",
                    title: "Medical Data Processing",
                    description: "To analyze your radiology report with AI",
                    isEnabled: $hasDataPermission
                )
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: {
                    if hasLocationPermission && hasDataPermission {
                        locationManager.requestLocation()
                        showPrivacyConsent = false
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            (hasLocationPermission && hasDataPermission) ?
                            Color.blue : Color.gray.opacity(0.5)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!(hasLocationPermission && hasDataPermission))
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            disclaimerView
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
    
    private func consentItem(icon: String, title: String, description: String, isEnabled: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var disclaimerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(.orange)
            
            Text("Important Medical Disclaimer")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            
            Text("This analysis is NOT a medical diagnosis. Always consult with qualified healthcare professionals for medical advice, diagnosis, and treatment decisions.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                
                if let report = analysisService.currentReport {
                    analysisResultsSection(report: report)
                    
                    // Scan Another Report Button
                    scanAnotherReportButton
                        .padding(.top, 20)
                } else if let error = analysisService.errorMessage {
                    errorCard(error)
                } else {
                    uploadCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                }
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Radiology Report Analysis")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("Upload your radiology report for AI-powered analysis")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Upload Card (Updated from ExtractView)
    private var uploadCard: some View {
        VStack(spacing: 20) {
            Text("Upload Radiology Report")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.top, 20)
            
            // Image preview section
            radiologyImageView
            
            // Camera and Gallery buttons
            HStack(spacing: 16) {
                cameraButton
                galleryButton
            }
            .padding(.horizontal)
            
            if let error = analysisService.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var radiologyImageView: some View {
        Group {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 260)
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .padding(.horizontal)
            } else {
                Rectangle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 260)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 40))
                                .foregroundColor(.blue.opacity(0.6))
                            Text("Capture or Select Radiology Report")
                                .foregroundColor(.blue.opacity(0.8))
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        }
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                    .padding(.horizontal)
            }
        }
        .animation(.easeInOut, value: selectedImage)
    }
    
    private var cameraButton: some View {
        Button(action: { showCamera = true }) {
            Label("Camera", systemImage: "camera.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 4)
        }
    }
    
    private var galleryButton: some View {
        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
            Label("Gallery", systemImage: "photo.fill.on.rectangle.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 4)
        }
    }
    
    private var loaderOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                LoadingIndicator(animation: .doubleHelix, color: .blue, size: .large, speed: .fast)
                
                Text("Analyzing Report...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("AI is processing your radiology report")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(30)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Analysis Results Section
    private func analysisResultsSection(report: RadiologyReport) -> some View {
        VStack(spacing: 20) {
            reportOverviewCard(report: report)
            findingsCard(findings: report.findings)
            specialistsCard(specialties: report.recommendedSpecialties)
            precautionsCard(precautions: report.precautions, nextSteps: report.nextSteps)
            actionButtonsCard(report: report)
        }
    }
    
    // MARK: - Scan Another Report Button
    private var scanAnotherReportButton: some View {
        Button(action: {
            resetForNewScan()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Scan Another Report")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.teal, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Report Overview Card
    private func reportOverviewCard(report: RadiologyReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Report Overview")
                    .foregroundStyle(.blue)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                severityBadge(severity: report.severity)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                
                Text(report.summary)
                    .font(.body)
                    .foregroundColor(.black)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.black)
                    
                    Text("\(Int(report.confidence * 100))%")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Analyzed")
                        .font(.caption)
                        .foregroundColor(.black)
                    
                    Text(report.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.black)
                }
            }
            
            if !analysisService.safetyFlags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Safety Flags Detected")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    ForEach(analysisService.safetyFlags, id: \.self) { flag in
                        Text("• \(flag)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private func severityBadge(severity: ReportSeverity) -> some View {
        HStack(spacing: 6) {
            Image(systemName: severity == .critical ? "exclamationmark.triangle.fill" :
                    severity == .moderate ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
            .font(.caption)
            
            Text(severity.title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(severity.color.opacity(0.2))
        .foregroundColor(severity.color)
        .cornerRadius(20)
    }
    
    // MARK: - Findings Card
    private func findingsCard(findings: [Finding]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Findings")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(findings.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(findings) { finding in
                    findingRow(finding: finding)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private func findingRow(finding: Finding) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: finding.suggestedSeverity.icon)
                    .foregroundColor(finding.suggestedSeverity.color)
                    .font(.title3)
                
                Text(finding.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(finding.suggestedSeverity.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(finding.suggestedSeverity.color.opacity(0.2))
                    .foregroundColor(finding.suggestedSeverity.color)
                    .cornerRadius(8)
            }
            
            Text(finding.valueDescription)
                .font(.body)
                .foregroundColor(.black)
            
            if !finding.significance.isEmpty {
                Text(finding.significance)
                    .font(.caption)
                    .foregroundColor(.black)
                    .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Specialists Card
    private func specialistsCard(specialties: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Recommended Specialists")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            
            if doctorService.isLoadingDoctors {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Finding specialists...")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else if doctorService.nearbyDoctors.isEmpty {
                VStack(spacing: 12) {
                    Text("Recommended Specialties:")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(specialties, id: \.self) { specialty in
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(.blue)
                                Text(specialty)
                                    .font(.subheadline)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(doctorService.nearbyDoctors) { doctor in
                        doctorRow(doctor: doctor)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private func doctorRow(doctor: Doctor) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(doctor.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    
                    Text(doctor.specialty)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(String(format: "%.1f", doctor.rating))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    Text(String(format: "%.1f km", doctor.distance))
                        .font(.caption)
                        .foregroundColor(.black)
                }
            }
            
            HStack(spacing: 4) {
                Image(systemName: "location")
                    .foregroundColor(.black)
                    .font(.caption)
                Text(doctor.address)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    if let url = URL(string: "tel:\(doctor.phone)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                        Text("Call")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    let lat = doctor.location.latitude
                    let lon = doctor.location.longitude
                    let urlString = "maps://?q=\(lat),\(lon)"
                    if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                            .font(.caption)
                        Text("Directions")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Precautions Card
    private func precautionsCard(precautions: [String], nextSteps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.shield")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text("Precautions & Next Steps")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Spacer()
            }
            
            if !precautions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Precautions")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(precautions, id: \.self) { precaution in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                    .padding(.top, 2)
                                
                                Text(precaution)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            
            if !nextSteps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Next Steps")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(nextSteps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                Text(step)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Action Buttons Card
    private func actionButtonsCard(report: RadiologyReport) -> some View {
        VStack(spacing: 16) {
            Text("Actions")
                .foregroundStyle(.blue)
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                if report.severity == .critical {
                    Button(action: {
                        if let url = URL(string: "tel://911") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "phone.fill")
                                .font(.title3)
                            Text("Call Emergency")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        // Book appointment action
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.title3)
                            Text("Book Appointment")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        saveReport(report)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title3)
                            Text("Save Report")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Error Card
    private func errorCard(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("Analysis Failed")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.red)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                resetForNewScan()
            }) {
                Text("Try Again")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Image Handler Functions (from ExtractView)
    private func handleGallerySelection(_ newItem: PhotosPickerItem?) {
        Task {
            guard let item = newItem else { return }
            isLoading = true
            
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                selectedImage = uiImage
                await processImage(uiImage)
            }
            
            isLoading = false
        }
    }
    
    private func handleCameraImage(_ newImage: UIImage?) {
        Task {
            guard let img = newImage else { return }
            isLoading = true
            await processImage(img)
            isLoading = false
        }
    }
    
    private func processImage(_ image: UIImage) async {
        do {
            await analysisService.analyzeReport(image: image)
            
            // Find doctors if report is analyzed and specialties are available
            if let report = analysisService.currentReport, !report.recommendedSpecialties.isEmpty {
                await doctorService.findDoctors(
                    for: report.recommendedSpecialties,
                    userLocation: locationManager.location
                )
            }
        } catch {
            analysisService.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Reset Function
    private func resetForNewScan() {
        selectedImage = nil
        selectedItem = nil
        analysisService.currentReport = nil
        analysisService.errorMessage = nil
        analysisService.safetyFlags = []
        doctorService.nearbyDoctors = []
        isLoading = false
    }
    
    // MARK: - Helper Functions
    private func saveReport(_ report: RadiologyReport) {
        // Implement report saving logic
        print("Saving report: \(report.id)")
        
        // Show success message
        let notification = UNMutableNotificationContent()
        notification.title = "Report Saved"
        notification.body = "Your radiology report analysis has been saved successfully."
        notification.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notification,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

