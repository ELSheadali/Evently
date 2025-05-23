import UIKit
import FirebaseAuth

class LoadingViewController: UIViewController {

    private let loadingView = LoadingView()

    override func loadView() {
        self.view = loadingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkUserAuthenticationStatus()
        }
    }

    private func checkUserAuthenticationStatus() {
        if Auth.auth().currentUser != nil {
            navigateToHomeScreen()
        } else {
            navigateToLoginScreen()
        }
    }

    private func navigateToHomeScreen() {
        let homeVC = HomeViewController()
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            
            let navController = UINavigationController(rootViewController: homeVC)
            window.rootViewController = navController
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        } else {
            if let navigationController = self.navigationController {
                navigationController.setViewControllers([homeVC], animated: true)
            } else {
                let navController = UINavigationController(rootViewController: homeVC)
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true, completion: nil)
            }
        }
    }

    private func navigateToLoginScreen() {
        let loginVC = LoginViewController()
        self.navigationController?.pushViewController(loginVC, animated: true)
    }
}
