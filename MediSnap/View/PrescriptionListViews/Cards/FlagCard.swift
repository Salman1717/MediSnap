//
//  FlagCard.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//
import SwiftUI

struct FlagCard: View {
    let flag: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("Medication Flag")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(flag.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key.capitalized + ":")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let value = flag[key] as? String {
                            Text(value)
                                .font(.subheadline)
                        } else if let value = flag[key] as? [String] {
                            Text(value.joined(separator: ", "))
                                .font(.subheadline)
                        } else {
                            Text(String(describing: flag[key] ?? ""))
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
