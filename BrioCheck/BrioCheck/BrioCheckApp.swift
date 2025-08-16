import SwiftUI
import FirebaseCore

@main
struct BrioCheckApp: App {
    init() {
        FirebaseApp.configure()
        UIView.appearance().overrideUserInterfaceStyle = .light
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
