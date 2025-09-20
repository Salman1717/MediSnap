//
//  Medications.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import Foundation

struct Medication: Codable, Identifiable{
    var id: String = UUID().uuidString
        var name: String
        var dosage: String?
        var frequency: String?
        var duration: String?
        var route: String?
        var originalText: String?
        var confidence: Double?
        var uncertain: Bool = false
        var plainExplanation: String?
        var tips: [String]?

}
