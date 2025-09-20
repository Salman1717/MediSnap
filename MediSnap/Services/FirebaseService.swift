//
//  FirebaseService.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//


import FirebaseFirestore
import Foundation
import FirebaseAuth

final class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()

    private init() {}
    
    var userId: String? {
               Auth.auth().currentUser?.uid
           }


    // Save a prescription document (expects authenticated user)
    func savePrescription(_ prescription: Prescription) async throws {
        guard let uid = userId else {
            throw NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthenticated"])
        }

        var p = prescription
        if p.id.isEmpty { p.id = UUID().uuidString }
        p.userId = uid

        // Use Firestore.Encoder to convert codable model to dictionary
        let encoded = try Firestore.Encoder().encode(p)
        try await db.collection("prescriptions").document(p.id).setData(encoded)
    }
}

