//
//  AuthView.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import SwiftUI
import GoogleSignInSwift

struct AuthView: View {
    
    @ObservedObject var viewModel = AuthViewModel()
    @Binding var showAuthView: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.7), Color.teal.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    
                    Spacer()
                    
                    // App Icon / Symbol
                    Image(systemName: "pills.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .shadow(radius: 8)
                    
                    // App Title
                    Text("MediSnap")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Tagline
                    Text("Your Smart Prescription Assistant")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Google Sign-In Button
                    GoogleSignInButton(
                        viewModel: GoogleSignInButtonViewModel(
                            scheme: .light,
                            style: .wide,
                            state: .normal
                        )
                    ) {
                        Task {
                            do {
                                try await viewModel.signInGoogle()
                                showAuthView = false
                            } catch {
                                print("AuthError: \(error.localizedDescription)")
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .shadow(radius: 4)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

#Preview {
    AuthView(showAuthView: .constant(true))
}
