//
//  MedicationSafetyInfo.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//
import Foundation

struct MedicationSafetyInfo: Codable, Identifiable {
    let id = UUID() // This should NOT be included in JSON decoding
    let medicationName: String
    let commonSideEffects: [String]
    let seriousSideEffects: [String]
    let precautions: [String]
    let foodInteractions: [String]
    let drugInteractions: [String]
    let contraindications: [String]
    let whenToSeekHelp: [String]
    let generalAdvice: [String]
    
    // IMPORTANT: Exclude 'id' from JSON coding since AI won't provide it
    private enum CodingKeys: String, CodingKey {
        case medicationName, commonSideEffects, seriousSideEffects, precautions,
             foodInteractions, drugInteractions, contraindications, whenToSeekHelp, generalAdvice
        // Note: 'id' is intentionally excluded
    }
}

