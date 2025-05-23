import UIKit
import FirebaseAuth
import FirebaseCore

// MARK: - View Controller for Login Screen
class LoginViewController: UIViewController {

    private let loginView = LoginView()

    // MARK: - Lifecycle Methods
    override func loadView() {
        self.view = loginView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loginView.loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        loginView.registerButton.addTarget(self, action: #selector(handleRegister), for: .touchUpInside)
    }

    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Actions
    @objc private func handleLogin() {
        guard let email = loginView.emailTextField.text, !email.isEmpty,
              let password = loginView.passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Помилка", message: "Будь ласка, введіть email та пароль.")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert(title: "Помилка входу", message: error.localizedDescription)
                return
            }
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let windowDelegate = windowScene.delegate as? SceneDelegate,
               let window = windowDelegate.window {
                let homeVC = HomeViewController()
                let navController = UINavigationController(rootViewController: homeVC)
                window.rootViewController = navController
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
            } else {
                 let homeVC = HomeViewController()
                 self.navigationController?.pushViewController(homeVC, animated: true)
            }
        }
    }

    @objc private func handleRegister() {
        let registerVC = RegisterViewController()
        navigationController?.pushViewController(registerVC, animated: true)
    }
}
