//
//  AuthViewModel.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false

    func signInGoogle() async throws {
        if isSignedIn { return } // prevent multiple sign-ins

        let tokens = try await GoogleSignInHelper.shared.signIn()
        try await AuthServices.shared.signInWithGoogle(tokens: tokens)
        isSignedIn = true
    }

    func logout() {
        Task {
            do {
                try AuthServices.shared.signOut()
                GoogleSignInHelper.shared.reset() // ✅ now exists
                isSignedIn = false
            } catch {
                print("Logout failed:", error.localizedDescription)
            }
        }
    }
}


