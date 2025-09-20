//
//  PrescriptionViewModel.swift
//  MediSnap
//
//  Created by Aaseem Mhaskar on 21/09/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import Combine

@MainActor
class PrescriptionHistoryViewModel: ObservableObject {
    @Published var prescriptions: [Prescription] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func fetchPrescriptions(for userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let snapshot = try await db.collection("prescriptions")
                .whereField("userId", isEqualTo: userId)
                .order(by: "date", descending: true)
                .getDocuments()
            
            let fetchedPrescriptions = try snapshot.documents.compactMap { doc -> Prescription? in
                try doc.data(as: Prescription.self)
            }
            
            self.prescriptions = fetchedPrescriptions
        } catch {
            self.errorMessage = "Failed to fetch prescriptions: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

