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
    @Binding var showAuthView:Bool
    
    var body: some View {
        NavigationStack {
            VStack{
                Text("Welcome To MediSnap")
                    .font(.headline)
                GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .standard, state: .pressed) ){
                    Task{
                        do{
                           
                            try await viewModel.signInGoogle()
                            
                            showAuthView = false
                        }
                        catch{
                            print("AuthError: \(error.localizedDescription)")
                        }
                    }
                }
                
                
            }
        }
    }
}

#Preview {
    AuthView( showAuthView: .constant(false))
}
