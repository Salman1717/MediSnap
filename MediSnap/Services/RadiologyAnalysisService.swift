//
//  RadiologyAnalysisService.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//
import Foundation
import Combine
import UIKit

// MARK: - Radiology Analysis Service
@MainActor
class RadiologyAnalysisService: ObservableObject {
    static let shared = RadiologyAnalysisService()
    private init() {}
    
    @Published var isAnalyzing = false
    @Published var currentReport: RadiologyReport?
    @Published var errorMessage: String?
    @Published var safetyFlags: [String] = []
    
    private let geminiService = GeminiService.shared
    
    func analyzeReport(image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        safetyFlags = []
        
        do {
            // Step 1: AI Analysis using Gemini with image input
            let aiReport = try await geminiService.analyzeRadiologyReport(image: image)
            
            // Step 2: Local safety check on the summary and findings text
            let combinedText = aiReport.summary + " " + aiReport.findings.map { "\($0.name) \($0.valueDescription) \($0.significance)" }.joined(separator: " ")
            let safetyResult = SafetyChecker.shared.analyzeText(combinedText)
            
            // Step 3: Combine severities
            let finalSeverity = combineSeverities(aiSeverity: aiReport.severity, localSeverity: safetyResult.severity)
            
            // Step 4: Create final report with combined severity
            let finalReport = RadiologyReport(
                summary: aiReport.summary,
                findings: aiReport.findings,
                recommendedSpecialties: aiReport.recommendedSpecialties,
                precautions: aiReport.precautions,
                nextSteps: aiReport.nextSteps,
                confidence: aiReport.confidence,
                rawModelText: aiReport.rawModelText,
                severity: finalSeverity,
                timestamp: Date()
            )
            
            currentReport = finalReport
            safetyFlags = safetyResult.flags
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Radiology analysis error: \(error)")
        }
        
        isAnalyzing = false
    }
    
    private func combineSeverities(aiSeverity: ReportSeverity, localSeverity: ReportSeverity) -> ReportSeverity {
        // Take the more severe of the two
        switch (aiSeverity, localSeverity) {
        case (.critical, _), (_, .critical):
            return .critical
        case (.moderate, _), (_, .moderate):
            return .moderate
        default:
            return .normal
        }
    }
}

enum AnalysisError: LocalizedError {
    case invalidImage
    case invalidResponse
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Invalid image format"
        case .invalidResponse: return "Invalid response from AI service"
        case .invalidJSON: return "Failed to parse AI response"
        }
    }
}
