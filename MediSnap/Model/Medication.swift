//
//  Medications.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import Foundation

struct Medication: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var dosage: String?
    var frequency: String?
    var duration: String?
    var route: String?
    var originalText: String?
    var confidence: Double?
    var uncertain: Bool = false
    var plainExplanation: String?
    var tips: [String]?
    
    // Custom coding keys to handle JSON properly
    private enum CodingKeys: String, CodingKey {
        case name, dosage, frequency, duration, route, originalText, confidence, uncertain
        // Note: plainExplanation and tips are not in the Gemini response, so they're excluded
    }
    
    // Custom decoder to handle empty strings as nil
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        name = try container.decode(String.self, forKey: .name)
        uncertain = try container.decodeIfPresent(Bool.self, forKey: .uncertain) ?? false
        
        // Optional fields - convert empty strings to nil
        let dosageString = try container.decodeIfPresent(String.self, forKey: .dosage)
        dosage = dosageString?.isEmpty == true ? nil : dosageString
        
        let frequencyString = try container.decodeIfPresent(String.self, forKey: .frequency)
        frequency = frequencyString?.isEmpty == true ? nil : frequencyString
        
        let durationString = try container.decodeIfPresent(String.self, forKey: .duration)
        duration = durationString?.isEmpty == true ? nil : durationString
        
        let routeString = try container.decodeIfPresent(String.self, forKey: .route)
        route = routeString?.isEmpty == true ? nil : routeString
        
        let originalTextString = try container.decodeIfPresent(String.self, forKey: .originalText)
        originalText = originalTextString?.isEmpty == true ? nil : originalTextString
        
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        
        // Generate ID
        id = UUID().uuidString
        
        // Initialize fields not in JSON
        plainExplanation = nil
        tips = nil
    }
    
    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(dosage, forKey: .dosage)
        try container.encodeIfPresent(frequency, forKey: .frequency)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(route, forKey: .route)
        try container.encodeIfPresent(originalText, forKey: .originalText)
        try container.encodeIfPresent(confidence, forKey: .confidence)
        try container.encode(uncertain, forKey: .uncertain)
    }
    
    // Convenience initializer for manual creation
    init(name: String, dosage: String? = nil, frequency: String? = nil, duration: String? = nil, route: String? = nil, originalText: String? = nil, confidence: Double? = nil, uncertain: Bool = false) {
        self.id = UUID().uuidString
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.duration = duration
        self.route = route
        self.originalText = originalText
        self.confidence = confidence
        self.uncertain = uncertain
        self.plainExplanation = nil
        self.tips = nil
    }
}
