import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var userName: String = "User"
    @State private var profileCompletion: Double = 0.65
    @Environment(\.presentationMode) private var presentationMode
    @State private var showAuthView: Bool = false

    var gradientBackground: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.7), Color.teal.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
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

                Spacer()

                // Log Out Button
                Button(action: {
                    do {
                        try AuthServices.shared.signOut()
                        showAuthView = true
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        print("Sign out failed:", error.localizedDescription)
                    }
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
        .task {
            if let user = AuthServices.shared.currentUser {
                userName = user.displayName ?? user.email ?? "User"
            }
        }
        .fullScreenCover(isPresented: $showAuthView) {
            AuthView(showAuthView: $showAuthView) // Pass the binding here
        }
    }
}

#Preview {
    ProfileView()
}
