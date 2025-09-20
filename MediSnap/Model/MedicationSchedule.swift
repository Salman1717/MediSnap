//
//  MedicationSchedule.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//


import Foundation

struct MedicationSchedule: Identifiable, Codable {
    var id: String = UUID().uuidString
    var med: Medication
    var reminders: [Date] = [] // scheduled times
}
