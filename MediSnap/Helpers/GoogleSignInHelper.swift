//
//  GoogleSignInHelper.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import Foundation
import GoogleSignIn
import GoogleSignInSwift

struct GoogleSignInResultModel{
    let idToken: String
    let accessToken: String
}

final class GoogleSignInHelper {
    static let shared = GoogleSignInHelper()
    private var currentUser: GIDGoogleUser?
    
    @MainActor
    func signIn() async throws -> GoogleSignInResultModel {
        // Reuse current user if token is valid
        if let user = currentUser,
           let expiration = user.accessToken.expirationDate,
           expiration.timeIntervalSinceNow > 60 {
            guard let idToken = user.idToken?.tokenString else {
                throw URLError(.badServerResponse)
            }
            return GoogleSignInResultModel(
                idToken: idToken,
                accessToken: user.accessToken.tokenString
            )
        }
        
        guard let topVC = Utilities.shared.topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        let calendarScopes = ["https://www.googleapis.com/auth/calendar"]
        
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: topVC,
            hint: "",
            additionalScopes: calendarScopes
        )
        
        currentUser = result.user
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        return GoogleSignInResultModel(
            idToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
    }
    
    // ✅ Reset cached user on logout
    func reset() {
        currentUser = nil
    }
}



