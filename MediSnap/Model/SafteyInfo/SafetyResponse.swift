//
//  SafetyResponse.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//
import Foundation

struct SafetyResponse: Codable {
    let medications: [MedicationSafetyInfo]
    let generalWarning: String
}
