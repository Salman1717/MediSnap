//
//  HomeScreen.swift
//  MediSnap
//
//  Created by Aaseem Mhaskar on 20/09/25.
//

import SwiftUI

struct HomeScreen: View {
    var gradientBackground: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.7), Color.teal.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

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
                    NavigationLink(destination: ExtractView().navigationBarBackButtonHidden()){
                        Text("Scan Prescription")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    
                    
                    Image("homeIllus")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(20)
                        .shadow(radius: 8)
                        .padding(.horizontal)

                    Spacer()

                    // Main Buttons
                    VStack(spacing: 20) {

                        // Scan Prescription Button
                        NavigationLink(destination: ExtractView()) {
                            Text("Scan Prescription")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        .glassButton()

                        // View Schedule Button
                        NavigationLink(destination: Text("Schedule Screen Coming Soon")) {
                            Text("View Schedule")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        .glassButton()
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// Glass Button Modifier (reuse from ExtractView)
struct GlassButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.15))
                    .blur(radius: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func glassButton() -> some View {
        self.modifier(GlassButton())
    }
}

#Preview {
    HomeScreen()
}
