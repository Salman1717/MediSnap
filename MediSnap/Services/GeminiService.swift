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
        /// Accepts prescriptionText (OCR output or plain text) and returns decoded Medication array.
        func extractMeds(from prescriptionText: String) async throws -> [Medication] {
            let systemPrompt = """
            You are a JSON extractor. From the prescription text below, return a JSON array of medication objects.
            Each medication object must have these fields:
            name (string), dosage (string or empty), frequency (string or empty), duration (string or empty),
            route (string or empty), originalText (string), confidence (number 0.0-1.0), uncertain (boolean).
            Return JSON only (no commentary).
            """

            let prompt = """
            \(systemPrompt)

            Prescription text:
            \(prescriptionText)
            """

            let response = try await model?.generateContent(prompt)

            guard let text = response?.text else {
                throw NSError(domain: "GeminiService", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "No textual response from model"])
            }

            // Try extracting first JSON substring (tolerant parsing)
            if let jsonData = firstJSONData(from: text) {
                do {
                    let meds = try JSONDecoder().decode([Medication].self, from: jsonData)
                    return meds
                } catch {
                    // Provide debug info in error message to help iterate on prompt
                    throw NSError(domain: "GeminiService", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to decode medications JSON: \(error.localizedDescription)",
                        "modelResponsePreview": String(text.prefix(500))
                    ])
                }
            } else {
                throw NSError(domain: "GeminiService", code: 3, userInfo: [
                    NSLocalizedDescriptionKey: "Model output did not contain JSON. Response preview: \(String(text.prefix(500)))"
                ])
            }
        }

    
    private func firstJSONData(from text: String) -> Data? {
            guard let start = text.firstIndex(where: { $0 == "{" || $0 == "[" }) else { return nil }
            guard let end = text.lastIndex(where: { $0 == "}" || $0 == "]" }) else { return nil }
            guard start < end else { return nil }
            let substring = text[start...end]
            return Data(substring.utf8)
        }
}
