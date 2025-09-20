//
//  AgenticFlowView.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 21/09/25.
//


// AgenticFlowView.swift
import SwiftUI
import UIKit

struct AgenticFlowView: View {
    @ObservedObject var agent = AgenticManager.shared
    let prescription: Prescription

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Setting up your medication plan")
                    .font(.title2).bold()
                    .padding(.top)

                List {
                    flowRow(title: "1. Safety check", key: "flag")
                    flowRow(title: "2. Build schedule", key: "schedule")
                    flowRow(title: "3. Create Calendar events", key: "calendar")
                    flowRow(title: "4. Create checklist", key: "checklist")
                    flowRow(title: "5. Prepare summary", key: "export")
                }

                if let summary = agent.exportSummary {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary").font(.headline)
                        Text(summary).font(.body)
                        HStack {
                            Button("Share") { share(summary) }
                            Spacer()
                        }
                    }
                    .padding()
                } else {
                    Spacer()
                }

                Button("Done") {
                    // dismiss sheet (host is responsible). For typical sheet this will close automatically.
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()

            }
            .navigationBarTitle("Agent Setup", displayMode: .inline)
            .onAppear {
                // if flow wasn't started by ExtractViewModel, you could start here:
                Task {
                    // flow should already be running; this is just safety
                    await AgenticManager.shared.startFlow(prescription: prescription)
                }
            }
        }
    }

    @ViewBuilder
    private func flowRow(title: String, key: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            switch agent.stepStatuses[key] ?? .pending {
            case .pending: Text("Pending").foregroundColor(.gray)
            case .running: ProgressView().scaleEffect(0.8)
            case .done: Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            case .failed(let msg): Image(systemName: "xmark.octagon.fill").foregroundColor(.red).help(msg)
            }
        }
        .padding(.vertical, 6)
    }

    private func share(_ text: String) {
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }
}
