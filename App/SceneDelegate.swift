import UIKit
import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

// MARK: - Делегат Сцени
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // MARK: - UIWindowSceneDelegate
    
    // Налаштовує сцену при підключенні.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let rootVC = LoadingViewController()
        let navController = UINavigationController(rootViewController: rootVC)
        navController.setNavigationBarHidden(true, animated: false)

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        configureKeyboardDismiss()
        
        window?.rootViewController?.view.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        )
    }

    // Викликається, коли сцена була відключена.
    func sceneDidDisconnect(_ scene: UIScene) {}

    // Викликається, коли сцена стала активною.
    func sceneDidBecomeActive(_ scene: UIScene) {}

    // Викликається, коли сцена переходить у неактивний стан.
    func sceneWillResignActive(_ scene: UIScene) {}

    // Викликається, коли сцена переходить на передній план.
    func sceneWillEnterForeground(_ scene: UIScene) {}

    // Викликається, коли сцена перейшла у фоновий режим.
    func sceneDidEnterBackground(_ scene: UIScene) {}

    // MARK: - Приватні Методи
    
    // Закриває клавіатуру.
    @objc private func dismissKeyboard() {
        window?.endEditing(true)
    }

    // Налаштовує закриття клавіатури при натисканні поза полем вводу.
    private func configureKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        window?.addGestureRecognizer(tapGesture)
    }
}
