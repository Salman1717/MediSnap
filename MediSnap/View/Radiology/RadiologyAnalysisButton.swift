//
//  RadiologyAnalysisButton.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//

import SwiftUI


// MARK: - Home Screen Integration Button
struct RadiologyAnalysisButton: View {
    @State private var showRadiologyAnalysis = false
    
    var body: some View {
        Button(action: {
            showRadiologyAnalysis = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Radiology Analysis")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("AI-powered report analysis")
                        .font(.caption)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .fullScreenCover(isPresented: $showRadiologyAnalysis) {
            RadiologyAnalysisView()
        }
    }
}
