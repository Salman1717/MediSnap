//
//  GeminiService.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import FirebaseAI
import Foundation

@MainActor
final class GeminiService {
    static let shared = GeminiService()
    
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
