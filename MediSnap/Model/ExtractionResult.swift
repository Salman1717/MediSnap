//
//  ExtractionResult.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import Foundation

class ExtractionResult: Codable{
    var prescriptionId: String
    var medications: [Medication]
    var rawOcrText: String?
}
