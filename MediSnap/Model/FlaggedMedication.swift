//
//  FlaggedMedication.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//
import Foundation

struct FlaggedMedication: Identifiable, Codable {
    var id = UUID().uuidString
    var med: Medication
    var issue: String // Why it was flagged
}
