//
//  SafetyChecker.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//

import Foundation

// MARK: - Safety Checker
class SafetyChecker {
    static let shared = SafetyChecker()
    private init() {}
    
    private let criticalKeywords = [
        "pneumothorax", "intracranial hemorrhage", "free air", "acute infarct",
        "massive", "rupture", "perforation", "acute", "emergency", "urgent",
        "immediate", "critical", "severe", "hemorrhage", "bleeding", "stroke",
        "embolism", "thrombosis", "dissection", "aneurysm", "fracture"
    ]
    
    private let moderateKeywords = [
        "abnormal", "enlarged", "thickened", "nodule", "mass", "lesion",
        "inflammation", "infection", "consolidation", "opacity", "density"
    ]
    
    func analyzeText(_ text: String) -> (severity: ReportSeverity, flags: [String]) {
        let lowercaseText = text.lowercased()
        var detectedFlags: [String] = []
        
        // Check for critical keywords
        for keyword in criticalKeywords {
            if lowercaseText.contains(keyword) {
                detectedFlags.append(keyword)
            }
        }
        
        if !detectedFlags.isEmpty {
            return (.critical, detectedFlags)
        }
        
        // Check for moderate keywords
        for keyword in moderateKeywords {
            if lowercaseText.contains(keyword) {
                detectedFlags.append(keyword)
            }
        }
        
        if !detectedFlags.isEmpty {
            return (.moderate, detectedFlags)
        }
        
        return (.normal, [])
    }
}
