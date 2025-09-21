//
//  GeminiService.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import FirebaseAI
import Foundation
import Combine
import UIKit

@MainActor
final class GeminiService : ObservableObject {
    static let shared = GeminiService()
    @Published var medicationSchedule: [MedicationSchedule] = []
    
    
    private let ai: FirebaseAI
    var model: GenerativeModel?
    
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
    
    // MARK: - Get Safety Information
    func getSafetyInformation(for medications: [Medication]) async throws -> SafetyResponse {
        let medicationNames = medications.map { $0.name }.joined(separator: ", ")
        
        let systemPrompt = """
        You are a medical safety information assistant. For the given medications, provide comprehensive safety information in JSON format.
        
        Return a JSON object with this EXACT structure:
        {
          "medications": [
            {
              "medicationName": "string",
              "commonSideEffects": ["string1", "string2"],
              "seriousSideEffects": ["string1", "string2"],
              "precautions": ["string1", "string2"],
              "foodInteractions": ["string1", "string2"],
              "drugInteractions": ["string1", "string2"],
              "contraindications": ["string1", "string2"],
              "whenToSeekHelp": ["string1", "string2"],
              "generalAdvice": ["string1", "string2"]
            }
          ],
          "generalWarning": "Important disclaimer about consulting healthcare professionals"
        }
        
        IMPORTANT: 
        - Return ONLY valid JSON
        - Use double quotes for strings
        - Include at least 2-3 items for each array field
        - If no information available, use empty array []
        - Do not use markdown formatting or code blocks
        - All array fields must exist even if empty
        """
        
        let prompt = """
        \(systemPrompt)
        
        Medications to analyze: \(medicationNames)
        """
        
        let response = try await model?.generateContent(prompt)
        guard let text = response?.text else {
            throw NSError(domain: "GeminiService", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "No response from AI model"
            ])
        }
        
        print("=== SAFETY INFO RESPONSE ===")
        print(text)
        print("============================")
        
        // Try to parse JSON with better error handling
        guard let jsonData = extractCleanJSON(from: text) else {
            throw NSError(domain: "GeminiService", code: 6, userInfo: [
                NSLocalizedDescriptionKey: "Failed to extract valid JSON from AI response: \(String(text.prefix(300)))..."
            ])
        }
        
        let decoder = JSONDecoder()
        
        // Add better error handling for decoding
        do {
            let safetyResponse = try decoder.decode(SafetyResponse.self, from: jsonData)
            
            // Validate that we have at least one medication
            guard !safetyResponse.medications.isEmpty else {
                throw NSError(domain: "GeminiService", code: 7, userInfo: [
                    NSLocalizedDescriptionKey: "No medication safety information found in response"
                ])
            }
            
            return safetyResponse
            
        } catch let decodingError as DecodingError {
            print("=== DECODING ERROR ===")
            print(decodingError)
            print("=== RAW JSON DATA ===")
            print(String(data: jsonData, encoding: .utf8) ?? "Could not convert to string")
            print("====================")
            
            // Create a more descriptive error message
            let errorMessage: String
            switch decodingError {
            case .keyNotFound(let key, _):
                errorMessage = "Missing required field: \(key.stringValue)"
            case .typeMismatch(let type, _):
                errorMessage = "Type mismatch for expected type: \(type)"
            case .valueNotFound(let type, _):
                errorMessage = "Missing value for type: \(type)"
            case .dataCorrupted(let context):
                errorMessage = "Data corrupted: \(context.debugDescription)"
            @unknown default:
                errorMessage = "Unknown decoding error: \(decodingError.localizedDescription)"
            }
            
            throw NSError(domain: "GeminiService", code: 8, userInfo: [
                NSLocalizedDescriptionKey: "Failed to parse safety information: \(errorMessage)"
            ])
        } catch {
            throw NSError(domain: "GeminiService", code: 9, userInfo: [
                NSLocalizedDescriptionKey: "Unexpected error parsing safety information: \(error.localizedDescription)"
            ])
        }
    }

    // MARK: - Helper method for better JSON extraction
    // Add this helper method to your GeminiService class:

    private func extractCleanJSON(from text: String) -> Data? {
        print("=== SEARCHING FOR JSON IN TEXT ===")
        print("Full response text:")
        print(text)
        print("========================")
        
        // Remove common markdown formatting
        var cleanText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Look for object start
        guard let objectStart = cleanText.firstIndex(of: "{") else {
            print("❌ No '{' found in text")
            return nil
        }
        
        // Find the matching closing brace by counting braces
        var braceCount = 0
        var objectEnd: String.Index?
        
        for index in cleanText[objectStart...].indices {
            let char = cleanText[index]
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
        
        let jsonSubstring = cleanText[objectStart...end]
        let jsonString = String(jsonSubstring).trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("=== FOUND JSON SUBSTRING ===")
        print(jsonString)
        print("============================")
        
        // Validate JSON before returning
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("❌ Could not convert to UTF-8 data")
            return nil
        }
        
        // Try to parse as JSON to validate
        do {
            _ = try JSONSerialization.jsonObject(with: jsonData, options: [])
            print("✅ JSON validation successful")
            return jsonData
        } catch {
            print("❌ JSON validation failed: \(error)")
            return nil
        }
    }
    
    
    
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

// MARK: - Extended GeminiService for Radiology
// MARK: - Extended GeminiService for Radiology
extension GeminiService {
    
    func analyzeRadiologyReport(image: UIImage) async throws -> RadiologyReport {
        let systemPrompt = """
        You are a medical AI assistant specialized in analyzing radiology reports and medical images. 
        Analyze the provided radiology report image and return a JSON response with this exact structure:
        
        {
          "summary": "1-2 sentence summary of key findings",
          "findings": [
            {
              "name": "Finding name",
              "value": "Description of the finding",
              "significance": "Clinical significance",
              "suggestedSeverity": "normal|moderate|critical"
            }
          ],
          "recommendedSpecialties": ["specialty1", "specialty2"],
          "precautions": ["precaution1", "precaution2"],
          "nextSteps": ["step1", "step2"],
          "confidence": 0.85,
          "rawModelText": "Brief explanation of analysis approach",
          "severity": "normal|moderate|critical"
        }
        
        For recommended specialties, use these standard terms:
        - Cardiology, Pulmonology, Neurology, Orthopedics, Gastroenterology, Urology, Oncology, Emergency Medicine, Internal Medicine, Radiology
        
        Guidelines:
        1. Extract all visible findings from the radiology report
        2. Assess clinical significance of each finding
        3. Recommend appropriate medical specialties based on findings
        4. Suggest reasonable precautions and next steps
        5. Provide confidence score based on image quality and clarity
        6. Set overall severity based on most critical finding
        7. Use "critical" severity only for findings requiring immediate medical attention
        8. Use "moderate" for findings that need follow-up but aren't emergent
        9. Use "normal" for normal or insignificant findings
        
        Return only valid JSON, no additional text or markdown formatting.
        """
        
        // FirebaseAI can handle UIImage directly - no need to convert to Data
        // Generate content with UIImage and text prompt
        let response = try await model?.generateContent(image, systemPrompt)
        
        guard let responseText = response?.text else {
            throw AnalysisError.invalidResponse
        }
        
        print("=== RADIOLOGY ANALYSIS RESPONSE ===")
        print(responseText)
        print("===================================")
        
        // Extract JSON from response
        guard let jsonData = firstJSONData(from: responseText) else {
            throw AnalysisError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        let aiResponse = try decoder.decode(AIRadiologyResponse.self, from: jsonData)
        
        // Create RadiologyReport with generated UUID and current timestamp
        let report = RadiologyReport(from: aiResponse, severity: aiResponse.severity)
        
        return report
    }
}




