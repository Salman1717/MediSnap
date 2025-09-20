import SwiftUI

struct ProfileView: View {
    // Example user data
    @State private var userName: String = "Aaseem Mhaskar"
    @State private var profileCompletion: Double = 0.65 // 65% completed
    
    var gradientBackground: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.7), Color.teal.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            // Background Gradient
            gradientBackground
                .ignoresSafeArea()

            VStack(spacing: 40) {
                // User Name
                Text("Hello, \(userName)!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                    .padding(.top, 60)

                // Profile Completion Progress
                VStack(spacing: 16) {
                    Text("Medicine Progress")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ProgressView(value: profileCompletion)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.white))
                        .frame(height: 10)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(5)
                    
                    Text("\(Int(profileCompletion * 100))% completed")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.8))
                }
                .padding(.horizontal, 24)

                Spacer()

                // Log Out Button
                Button(action: {
                    print("Log Out tapped")
                    // TODO: Add logout functionality
                }) {
                    Text("Log Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitle("Profile", displayMode: .inline)
    }
}

#Preview {
    ProfileView()
}
