//
//  ContentView.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    @Binding var showAuth: Bool
  

    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                // Replace with your real home view
                HomeScreen()
                    .navigationBarHidden(true)

                // Logout button at top-right
                Button(action: {
                    do {
                        try AuthServices.shared.signOut()
                        // After signOut, show the auth screen
                        showAuth = true
                    } catch {
                        // Handle sign out error (you can show an alert instead)
                        print("Sign out failed:", error.localizedDescription)
                        showAuth = true // still fallback to auth UI if desired
                    }
                }) {
                    Text("Logout")
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .ignoresSafeArea(edges: .top) // optional: let the button float into the safe area
        }
    }
}




