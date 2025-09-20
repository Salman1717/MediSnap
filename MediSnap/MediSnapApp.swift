//
//  MediSnapApp.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct MediSnapApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var showAuthView: Bool = true
    
    var body: some Scene {
        
        WindowGroup {
            if showAuthView{
                AuthView(showAuthView: $showAuthView)
            }else{
                ContentView(showAuth: $showAuthView)
            }
//            ExtractView()
        }
    }
}
