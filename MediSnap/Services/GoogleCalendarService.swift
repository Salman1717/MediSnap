//
//  GoogleCalendarService.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//

import Foundation


final class GoogleCalendarService {
    static let shared = GoogleCalendarService()
    
    private let baseURL = "https://www.googleapis.com/calendar/v3"
    
    private init() {}
    
    // MARK: - Add medication schedule to Google Calendar
    func addMedicationScheduleToCalendar(schedule: [MedicationSchedule]) async throws -> [String] {
        // Get Google access token
        let signInResult = try await GoogleSignInHelper.shared.signIn()
        let accessToken = signInResult.accessToken
        
        var eventIds: [String] = []
        
        for medSchedule in schedule {
            for reminder in medSchedule.reminders {
                let eventId = try await createCalendarEvent(
                    for: medSchedule.med,
                    at: reminder,
                    accessToken: accessToken
                )
                eventIds.append(eventId)
            }
        }
        
        return eventIds
    }
    
    // MARK: - Create individual calendar event
    private func createCalendarEvent(
        for medication: Medication,
        at reminderTime: Date,
        accessToken: String
    ) async throws -> String {
        
        let url = URL(string: "\(baseURL)/calendars/primary/events")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create event details
        let eventTitle = "💊 Take \(medication.name)"
        let eventDescription = buildEventDescription(for: medication)
        
        // Event duration: 15 minutes
        let endTime = Calendar.current.date(byAdding: .minute, value: 15, to: reminderTime) ?? reminderTime
        
        let timeZone = TimeZone.current.identifier
        let dateFormatter = ISO8601DateFormatter()
        
        let event = CalendarEvent(
            summary: eventTitle,
            description: eventDescription,
            start: CalendarEvent.EventDateTime(
                dateTime: dateFormatter.string(from: reminderTime),
                timeZone: timeZone
            ),
            end: CalendarEvent.EventDateTime(
                dateTime: dateFormatter.string(from: endTime),
                timeZone: timeZone
            ),
            reminders: CalendarEvent.EventReminders(
                useDefault: false,
                overrides: [
                    CalendarEvent.EventReminders.ReminderOverride(method: "popup", minutes: 0),
                    CalendarEvent.EventReminders.ReminderOverride(method: "popup", minutes: 5)
                ]
            )
        )
        
        // Encode event to JSON
        let jsonData = try JSONEncoder().encode(event)
        request.httpBody = jsonData
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Calendar API Error: \(httpResponse.statusCode) - \(errorString)")
            throw URLError(.badServerResponse)
        }
        
        // Parse response
        let eventResponse = try JSONDecoder().decode(CalendarEventResponse.self, from: data)
        return eventResponse.id
    }
    
    // MARK: - Build event description
    private func buildEventDescription(for medication: Medication) -> String {
        var description = "Medication Reminder\n\n"
        description += "Medication: \(medication.name)\n"
        
        if let dosage = medication.dosage, !dosage.isEmpty {
            description += "Dosage: \(dosage)\n"
        }
        
        if let frequency = medication.frequency, !frequency.isEmpty {
            description += "Frequency: \(frequency)\n"
        }
        
        if let route = medication.route, !route.isEmpty {
            description += "Route: \(route)\n"
        }
        
        if let duration = medication.duration, !duration.isEmpty {
            description += "Duration: \(duration)\n"
        }
        
        description += "\n📱 Created by MediSnap"
        
        return description
    }
    
    // MARK: - Delete calendar event
    func deleteCalendarEvent(eventId: String) async throws {
        let signInResult = try await GoogleSignInHelper.shared.signIn()
        let accessToken = signInResult.accessToken
        
        let url = URL(string: "\(baseURL)/calendars/primary/events/\(eventId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 204 else {
            throw URLError(.badServerResponse)
        }
    }
}
