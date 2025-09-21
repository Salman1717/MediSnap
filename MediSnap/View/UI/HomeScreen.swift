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
            ZStack {
                // Gradient background
                gradientBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    HStack {
                        Spacer() // Pushes button to the right
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 16) // distance from right edge
                        .padding(.top, 16)     // distance from top edge
                    }
                    // App Title
                    Text("MediSnap")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 60)
                    
                    // Illustration Image
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
                        NavigationLink(destination: ExtractView().navigationBarBackButtonHidden()) {
                            Text("Scan Prescription")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                        .glassButton()
                        
                        // View Schedule Button
                        NavigationLink(destination: PrescriptionHistoryView().navigationBarBackButtonHidden())
                        {
                            Text("View Schedule")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .glassButton()
                        
                        // View Schedule Button
                        NavigationLink(destination: RadiologyAnalysisView().navigationBarBackButtonHidden())
                        {
                            Text("Scan Radiology Reports")
                                .font(.headline)
                                .foregroundColor(.white)
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

// Glass Button Modifier
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
