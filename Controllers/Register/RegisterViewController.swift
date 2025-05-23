import UIKit
import FirebaseAuth

// MARK: - View Controller for Registration Screen
class RegisterViewController: UIViewController {

    private let registerView = RegisterView()

    // MARK: - Lifecycle Methods
    override func loadView() {
        self.view = registerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        AppAppearance.setupStandardNavigationBar(navigationController, backgroundColor: .clear)
        navigationController?.navigationBar.tintColor = AppColors.primaryText

        registerView.registerButton.addTarget(self, action: #selector(handleRegister), for: .touchUpInside)
        registerView.loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true)
    }

    private func navigateToHome() {
        let homeVC = HomeViewController()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let windowDelegate = windowScene.delegate as? SceneDelegate,
           let window = windowDelegate.window {
            let navController = UINavigationController(rootViewController: homeVC)
            window.rootViewController = navController
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        } else {
            self.navigationController?.setViewControllers([homeVC], animated: true)
        }
    }

    // MARK: - Actions
    @objc private func handleRegister() {
        guard let name = registerView.nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
              let surname = registerView.surnameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !surname.isEmpty,
              let email = registerView.emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty,
              let password = registerView.passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Помилка", message: "Будь ласка, заповніть усі поля.")
            return
        }
        // Додаткова валідація (приклад)
        guard password.count >= 6 else {
            showAlert(title: "Помилка", message: "Пароль має містити щонайменше 6 символів.")
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: "Помилка реєстрації", message: error.localizedDescription)
                return
            }

            guard let user = authResult?.user else {
                self.showAlert(title: "Помилка", message: "Не вдалося отримати дані користувача.")
                return
            }

            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = "\(name) \(surname)"
            changeRequest.commitChanges { _ in  }

            let userProfile = UserProfile(uid: user.uid, firstName: name, lastName: surname)
            
            FirestoreManager.shared.updateUserProfile(userID: user.uid, profile: userProfile) { firestoreError in
                if firestoreError != nil {
                    self.showAlert(title: "Увага", message: "Акаунт створено, але сталася помилка при збереженні додаткових даних профілю.") {
                        self.navigateToHome()
                    }
                } else {
                    self.navigateToHome()
                }
            }
        }
    }

    @objc private func handleLogin() {
        if let navigationController = self.navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            let loginVC = LoginViewController()
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let windowDelegate = windowScene.delegate as? SceneDelegate,
               let window = windowDelegate.window {
                window.rootViewController = UINavigationController(rootViewController: loginVC)
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            }
        }
    }
}
