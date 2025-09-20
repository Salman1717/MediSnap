//
//  AuthViewModel.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject{
    
    func signInGoogle() async throws{
            let helper = GoogleSignInHelper()
            let tokens = try await helper.signIn()
            try await AuthServices.shared.signInWithGoogle(tokens: tokens)
        }
}
