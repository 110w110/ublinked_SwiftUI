//
//  ublinked_SwiftUIApp.swift
//  ublinked_SwiftUI
//
//  Created by 한태희 on 2022/10/09.
//

import SwiftUI
//import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//    FirebaseApp.configure()
    return true
  }
}

@main
struct ublinked_SwiftUIApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                    ContentView()
                  }
        }
    }
}
