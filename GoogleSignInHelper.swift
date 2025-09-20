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
    
    @MainActor
    func signIn() async throws -> GoogleSignInResultModel {
        guard let topVC = Utilities.shared.topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        // Define Calendar scopes
        let calendarScopes = [
            "https://www.googleapis.com/auth/calendar" // Full calendar access
        ]
        
        // Sign in with additional scopes
        let GIDSignInResult = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: topVC, hint: "",
            additionalScopes: calendarScopes
        )
        
        // Extract ID and access tokens
        guard let idToken = GIDSignInResult.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = GIDSignInResult.user.accessToken.tokenString
        
        return GoogleSignInResultModel(idToken: idToken, accessToken: accessToken)
    }
}

