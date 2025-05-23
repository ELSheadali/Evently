import UIKit
import FirebaseCore
import FirebaseFirestore
import Foundation

// MARK: - Головний Делегат Додатку
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - UIApplicationDelegate
    
    // Викликається після завершення запуску додатку.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }

    // MARK: - UISceneSession Lifecycle

    // Повертає конфігурацію для створення нової сцени.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // Викликається, коли користувач відхиляє сесію сцени.
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

// MARK: - Розширення Notification.Name
extension Notification.Name {
    static let didCreateNewEvent = Notification.Name("didCreateNewEvent")
    static let didUpdateEvent = Notification.Name("didUpdateEvent")
}
