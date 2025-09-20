//
//  GeminiService.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import FirebaseAI
import Foundation
import Combine

@MainActor
final class GeminiService: ObservableObject {
    static let shared = GeminiService()
    @Published var medicationSchedule: [MedicationSchedule] = []

    
    private let ai: FirebaseAI
    private var model: GenerativeModel?
    
    private init() {
        self.ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let modelName = "gemini-2.5-pro"
        self.model = ai.generativeModel(modelName: modelName)
    }
    
    // MARK: - Extract Medications
    func extractMedsAndDate(from prescriptionText: String) async throws -> (medications: [Medication], date: String?) {
        let systemPrompt = """
            You are a JSON extractor. From the prescription text below, return a JSON object with:
            1) medications: a JSON array of medication objects with fields:
               name (string), dosage (string or empty), frequency (string or empty), duration (string or empty),
               route (string or empty), originalText (string), confidence (number 0.0-1.0), uncertain (boolean).
            2) date: prescription date in YYYY-MM-DD format if available, else null.
            Return JSON only.
        """

        let prompt = "\(systemPrompt)\n\nPrescription text:\n\(prescriptionText)"

        let response = try await model?.generateContent(prompt)
        let text = response?.text ?? ""

        guard let jsonData = firstJSONData(from: text) else {
            throw NSError(domain: "GeminiService", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Model output did not contain valid JSON. Response preview: \(String(text.prefix(500)))"
            ])
        }

        // Decode JSON object
        struct Response: Codable {
            var medications: [Medication]
            var date: String?
        }

        let decoded = try JSONDecoder().decode(Response.self, from: jsonData)
        return (decoded.medications, decoded.date)
    }

    func generateScheduleWithGemini(prescription: Prescription) async throws {
        let systemPrompt = """
        You are a scheduling assistant. Given the following prescription medications,
        generate a JSON array of medication schedules with fields:
        - medName (string): exact medication name
        - reminders (array): array of ISO 8601 date-time strings for each dose
        
        Return ONLY a valid JSON array, no markdown formatting or extra text.
        """

        let medsText = prescription.medications.map { med in
            """
            name: \(med.name)
            dosage: \(med.dosage ?? "")
            frequency: \(med.frequency ?? "")
            duration: \(med.duration ?? "")
            """
        }.joined(separator: "\n")

        let prompt = "\(systemPrompt)\n\nMedications:\n\(medsText)\nStart date: \(ISO8601DateFormatter().string(from: prescription.date))"

        let response = try await model?.generateContent(prompt)
        guard let text = response?.text else { return }
        
        print("=== GEMINI SCHEDULE RESPONSE ===")
        print(text)
        print("===============================")

        // ✅ Extract JSON array from response (handle markdown formatting)
        guard let jsonData = firstJSONArrayData(from: text) else {
            throw NSError(domain: "GeminiService", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Failed to extract JSON array from response: \(String(text.prefix(500)))"
            ])
        }

        // ✅ Parse top-level array directly
        struct GeminiMedSchedule: Codable {
            var medName: String
            var reminders: [String]
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Wrap in try-catch to safely decode
        let decodedArray: [GeminiMedSchedule]
        do {
            decodedArray = try decoder.decode([GeminiMedSchedule].self, from: jsonData)
        } catch {
            print("Failed to decode Gemini schedule as array: \(error)")
            throw error
        }

        var schedule: [MedicationSchedule] = []

        for s in decodedArray {
            if let med = prescription.medications.first(where: { $0.name == s.medName }) {
                // Convert ISO strings to Date, skip invalid/empty
                let reminders = s.reminders.compactMap { ISO8601DateFormatter().date(from: $0) }
                schedule.append(MedicationSchedule(med: med, reminders: reminders))
            }
        }

        self.medicationSchedule = schedule
    }

    
    // ✅ New method to extract JSON array (handles markdown formatting)
    private func firstJSONArrayData(from text: String) -> Data? {
        print("=== SEARCHING FOR JSON ARRAY IN TEXT ===")
        print("Full response text:")
        print(text)
        print("========================================")
        
        // Remove markdown code block formatting if present
        var cleanText = text
        
        // Remove ```json and ``` markers
        cleanText = cleanText.replacingOccurrences(of: "```json", with: "")
        cleanText = cleanText.replacingOccurrences(of: "```", with: "")
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Look for array start
        guard let arrayStart = cleanText.firstIndex(of: "[") else {
            print("❌ No '[' found in text")
            return nil
        }
        
        // Find the matching closing bracket by counting brackets
        var bracketCount = 0
        var arrayEnd: String.Index?
        
        for index in cleanText[arrayStart...].indices {
            let char = cleanText[index]
            if char == "[" {
                bracketCount += 1
            } else if char == "]" {
                bracketCount -= 1
                if bracketCount == 0 {
                    arrayEnd = index
                    break
                }
            }
        }
        
        guard let end = arrayEnd else {
            print("❌ No matching ']' found")
            return nil
        }
        
        let jsonSubstring = cleanText[arrayStart...end]
        print("=== FOUND JSON ARRAY SUBSTRING ===")
        print(jsonSubstring)
        print("==================================")
        
        let cleaned = String(jsonSubstring).trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.data(using: .utf8)
    }
    
    private func firstJSONData(from text: String) -> Data? {
        print("=== SEARCHING FOR JSON IN TEXT ===")
        print("Full response text:")
        print(text)
        print("========================")
        
        // Look for object start
        guard let objectStart = text.firstIndex(of: "{") else {
            print("❌ No '{' found in text")
            return nil
        }
        
        // Find the matching closing brace by counting braces
        var braceCount = 0
        var objectEnd: String.Index?
        
        for index in text[objectStart...].indices {
            let char = text[index]
            if char == "{" {
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if braceCount == 0 {
                    objectEnd = index
                    break
                }
            }
        }
        
        guard let end = objectEnd else {
            print("❌ No matching '}' found")
            return nil
        }
        
        let jsonSubstring = text[objectStart...end]
        print("=== FOUND JSON SUBSTRING ===")
        print(jsonSubstring)
        print("============================")
        
        let cleaned = jsonSubstring.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.data(using: .utf8)
    }
}
