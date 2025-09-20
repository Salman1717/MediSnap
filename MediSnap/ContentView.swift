import SwiftUI

struct ContentView: View {
    @Binding var showAuth: Bool

    var body: some View {
        NavigationView {
            ZStack {
                // Your main home screen
                HomeScreen()
                    .navigationBarHidden(true)

                // Profile button positioned properly
                VStack {
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
                    Spacer()
                }
            }

        }
    }
}


