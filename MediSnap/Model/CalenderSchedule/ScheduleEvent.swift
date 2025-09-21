//
//  ScheduleEvent.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//
import Foundation

struct ScheduleEvent: Identifiable {
    var id = UUID().uuidString
    var title: String
    var startDate: Date
    var endDate: Date
}
