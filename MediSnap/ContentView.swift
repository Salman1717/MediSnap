//
//  ContentView.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import SwiftUI

struct ContentView: View {
    @Binding var showAuth: Bool
    @ObservedObject var viewModel = AuthViewModel()
    var body: some View {
        VStack {
            
            Text("Helloo Bhaiii")
            
            Button(action: {
                viewModel.logout()
                showAuth = true
            }) {
                Text("Logout")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }
}


