import SwiftUI

struct ContentView: View {
    @Binding var showAuth: Bool

    var body: some View {
        NavigationView {
            ZStack {
                // Your main home screen
                HomeScreen()
                    .navigationBarHidden(true)
            }

        }
    }
}


