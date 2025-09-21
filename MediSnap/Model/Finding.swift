//
//  Finding.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Data Models
struct RadiologyReport: Codable, Identifiable {
    let id: UUID
    let summary: String
    let findings: [Finding]
    let recommendedSpecialties: [String]
    let precautions: [String]
    let nextSteps: [String]
    let confidence: Double
    let rawModelText: String
    let severity: ReportSeverity
    let timestamp: Date
    
    // Custom initializer for creating new reports
    init(summary: String, findings: [Finding], recommendedSpecialties: [String],
         precautions: [String], nextSteps: [String], confidence: Double,
         rawModelText: String, severity: ReportSeverity, timestamp: Date = Date()) {
        self.id = UUID()
        self.summary = summary
        self.findings = findings
        self.recommendedSpecialties = recommendedSpecialties
        self.precautions = precautions
        self.nextSteps = nextSteps
        self.confidence = confidence
        self.rawModelText = rawModelText
        self.severity = severity
        self.timestamp = timestamp
    }
    
    // Custom initializer from AI response (without id and timestamp)
    init(from aiResponse: AIRadiologyResponse, severity: ReportSeverity) {
        self.id = UUID()
        self.summary = aiResponse.summary
        self.findings = aiResponse.findings
        self.recommendedSpecialties = aiResponse.recommendedSpecialties
        self.precautions = aiResponse.precautions
        self.nextSteps = aiResponse.nextSteps
        self.confidence = aiResponse.confidence
        self.rawModelText = aiResponse.rawModelText
        self.severity = severity
        self.timestamp = Date()
    }
}

// Separate struct for AI response decoding (without UUID and Date)
struct AIRadiologyResponse: Codable {
    let summary: String
    let findings: [Finding]
    let recommendedSpecialties: [String]
    let precautions: [String]
    let nextSteps: [String]
    let confidence: Double
    let rawModelText: String
    let severity: ReportSeverity
}

struct Finding: Codable, Identifiable {
    let id: UUID
    let name: String
    let valueDescription: String
    let significance: String
    let suggestedSeverity: FindingSeverity
    
    enum CodingKeys: String, CodingKey {
        case name, valueDescription = "value", significance, suggestedSeverity
    }
    
    // Custom initializer
    init(name: String, valueDescription: String, significance: String, suggestedSeverity: FindingSeverity) {
        self.id = UUID()
        self.name = name
        self.valueDescription = valueDescription
        self.significance = significance
        self.suggestedSeverity = suggestedSeverity
    }
    
    // Custom Codable implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.valueDescription = try container.decode(String.self, forKey: .valueDescription)
        self.significance = try container.decode(String.self, forKey: .significance)
        self.suggestedSeverity = try container.decode(FindingSeverity.self, forKey: .suggestedSeverity)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(valueDescription, forKey: .valueDescription)
        try container.encode(significance, forKey: .significance)
        try container.encode(suggestedSeverity, forKey: .suggestedSeverity)
    }
}

enum FindingSeverity: String, Codable, CaseIterable {
    case normal = "normal"
    case moderate = "moderate"
    case critical = "critical"
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .moderate: return .orange
        case .critical: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .normal: return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

enum ReportSeverity: String, Codable, CaseIterable {
    case normal = "normal"
    case moderate = "moderate"
    case critical = "critical"
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .moderate: return .orange
        case .critical: return .red
        }
    }
    
    var title: String {
        switch self {
        case .normal: return "Normal Results"
        case .moderate: return "Moderate Findings"
        case .critical: return "Critical Findings"
        }
    }
}

struct Doctor: Identifiable {
    let id = UUID()
    let name: String
    let specialty: String
    let address: String
    let distance: Double
    let phone: String
    let rating: Double
    let location: CLLocationCoordinate2D
}
