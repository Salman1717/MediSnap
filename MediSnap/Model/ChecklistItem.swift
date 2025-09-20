//
//  ChecklistItem.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//


import Foundation

struct ChecklistItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var medName: String
    var scheduledTimes: [Date] = [] // times to take the medication
    var taken: [Bool] = []          // ✅ taken / ❌ missed
}
