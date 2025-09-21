//
//  CalendarEvent.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//

import Foundation

struct CalendarEvent: Codable {
    let summary: String
    let description: String?
    let start: EventDateTime
    let end: EventDateTime
    let reminders: EventReminders?
    
    struct EventDateTime: Codable {
        let dateTime: String
        let timeZone: String
    }
    
    struct EventReminders: Codable {
        let useDefault: Bool
        let overrides: [ReminderOverride]?
        
        struct ReminderOverride: Codable {
            let method: String // "popup" or "email"
            let minutes: Int
        }
    }
}
