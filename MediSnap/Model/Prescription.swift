//
//  Prescription.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import Foundation

struct Prescription: Codable, Identifiable {
    var id: String = UUID().uuidString
    var date: Date
    var medications: [Medication]
    var userId: String? = nil
}

