//
//  HomeScreen.swift
//  MediSnap
//
//  Created by Aaseem Mhaskar on 20/09/25.
//

import SwiftUI

struct HomeScreen: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                
                // App Title
                Text("MediSnap")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 60)
                
                Spacer()
                
                // Main Buttons
                VStack(spacing: 20) {
                    
                    // Scan Prescription Button
                    Button(action: {
                        print("Scan Prescription tapped")
                        // TODO: Navigate to scan feature screen
                    }) {
                        Text("Scan Prescription")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    
                    // View Schedule Button
                    NavigationLink(destination: Text("Schedule Screen Coming Soon")) {
                        Text("View Schedule")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    HomeScreen()
}
