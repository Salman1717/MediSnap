//
//  MedicationSafetyInfo.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//
import Foundation

struct MedicationSafetyInfo: Codable, Identifiable {
    let id = UUID()
    let medicationName: String
    let commonSideEffects: [String]
    let seriousSideEffects: [String]
    let precautions: [String]
    let foodInteractions: [String]
    let drugInteractions: [String]
    let contraindications: [String]
    let whenToSeekHelp: [String]
    let generalAdvice: [String]
}
