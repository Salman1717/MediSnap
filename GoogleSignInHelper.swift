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

final class GoogleSignInHelper{
    
    @MainActor
    func signIn() async throws -> GoogleSignInResultModel{
        guard let TopVC =  Utilities.shared.topViewController() else{
            throw URLError(.cannotFindHost)
        }
        
        let GIDSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: TopVC)
        
        guard let idToken = GIDSignInResult.user.idToken?.tokenString else{
            throw URLError(.badServerResponse)
        }
        
        let accessToken = GIDSignInResult.user.accessToken.tokenString
        
        let tokens = GoogleSignInResultModel(idToken: idToken, accessToken: accessToken)
        
        return tokens
    }
}
