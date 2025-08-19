import FirebaseCore
import SwiftUI
import UserNotifications

@main
struct BrioCheckApp: App {
    @State private var showNotificationAlert = false

    init() {
        FirebaseApp.configure()
        UIView.appearance().overrideUserInterfaceStyle = .light
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestNotificationPermissionIfNeeded()
                    scheduleBrioNotifications()
                }
                .alert("Notifications Disabled",
                       isPresented: $showNotificationAlert,
                       actions: {
                           Button("OK", role: .cancel) { }
                       },
                       message: {
                           Text("To receive Brio reminders, enable notifications in Settings.")
                       })
        }
    }
    
    // MARK: - Notifications

    func requestNotificationPermissionIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "hasAskedForNotifications") { return }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            defaults.set(true, forKey: "hasAskedForNotifications")
            if !granted {
                DispatchQueue.main.async {
                    showNotificationAlert = true // one-time alert
                }
            }
        }
    }

    func scheduleBrioNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let weekdays = [3, 5]  // Tuesday, Thursday
        for weekday in weekdays {
            var dateComponents = DateComponents()
            dateComponents.hour = 8
            dateComponents.minute = 0
            dateComponents.weekday = weekday

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = "Coming to Brio today?"
            content.body = "Let your friends know if you're coming to play!"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "BrioReminder_\(weekday)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
}
