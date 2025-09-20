//
//  GoogleCalendarService.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//


import Foundation

final class GoogleCalendarService {
    static let shared = GoogleCalendarService()
    private init() {}

    // Minimal function to insert event with access token
    func insertEvent(accessToken: String, event: [String: Any]) async throws -> [String: Any] {
        guard let calendarId = "primary".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        guard let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: event, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "GoogleCalendarService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar insert failed"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError(domain: "GoogleCalendarService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response JSON"])
        }

        return json
    }
}
