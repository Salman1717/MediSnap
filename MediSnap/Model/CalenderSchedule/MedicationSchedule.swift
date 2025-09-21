//
//  MedicationSchedule 2.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//

import Foundation

struct MedicationSchedule: Identifiable, Codable {
    var id = UUID().uuidString
    var med: Medication
    var reminders: [Date] // times the user should take the medication
}

