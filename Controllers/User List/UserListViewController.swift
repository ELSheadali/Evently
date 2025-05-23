import UIKit
import FirebaseAuth
import SnapKit

// MARK: - View Controller for User Profile/Settings Menu
class UserListViewController: UIViewController {

    // MARK: - Properties
    private var userListView: UserListView!

    // MARK: - Lifecycle Methods
    override func loadView() {
        userListView = UserListView()
        view = userListView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupActions()
    }
    
    // MARK: - Setup Methods
    private func setupNavigation() {
        navigationItem.title = "Профіль"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissView))
        if let navController = self.navigationController {
            AppAppearance.setupStandardNavigationBar(navController)
        }
    }

    private func setupActions() {
        let accountSettingsTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleAccountSettingsTapped))
        userListView.accountSettingsLabel.addGestureRecognizer(accountSettingsTapGesture)
        
        let eventHistoryTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleEventHistoryTapped))
        userListView.eventHistoryLabel.addGestureRecognizer(eventHistoryTapGesture)
        
        let logoutTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLogoutTapped))
        userListView.logoutLabel.addGestureRecognizer(logoutTapGesture)
        
        let deleteAccountTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDeleteAccountTapped))
        userListView.deleteAccountLabel.addGestureRecognizer(deleteAccountTapGesture)
    }
    
    // MARK: - Actions & Navigation
    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleAccountSettingsTapped() {
        let accountSettingsVC = AccountSettingsViewController()
        self.navigationController?.pushViewController(accountSettingsVC, animated: true)
    }

    @objc private func handleEventHistoryTapped() {
        let userPastEventsVC = UserPastEventsViewController()
        self.navigationController?.pushViewController(userPastEventsVC, animated: true)
    }
    
    @objc private func handleLogoutTapped() {
        let alert = UIAlertController(title: "Вихід з системи", message: "Ви впевнені, що хочете вийти?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Так, вийти", style: .destructive, handler: { [weak self] _ in
            self?.performLogout()
        }))
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func performLogout() {
        do {
            try Auth.auth().signOut()
            navigateToLoginScreen()
        } catch let signOutError as NSError {
            showAlert(title: "Помилка виходу", message: signOutError.localizedDescription)
        }
    }
    
    @objc private func handleDeleteAccountTapped() {
        let alert = UIAlertController(title: "Видалення акаунту", message: "Ця дія незворотня. Ваш акаунт та всі пов'язані дані будуть видалені. Ви впевнені?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Так, видалити", style: .destructive, handler: { [weak self] _ in
            self?.performAccountDeletion()
        }))
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func performAccountDeletion() {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Помилка", message: "Не вдалося знайти активного користувача.")
            navigateToLoginScreen()
            return
        }
        
        user.delete { [weak self] error in
            if let error = error {
                if let authError = error as NSError?, authError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    self?.showAlert(title: "Помилка видалення", message: "Ця операція вимагає нещодавнього входу. Будь ласка, увійдіть знову та спробуйте ще раз.")
                    self?.performLogout()
                } else {
                    self?.showAlert(title: "Помилка видалення", message: "Не вдалося видалити акаунт. \(error.localizedDescription).")
                }
            } else {
                self?.showAlert(title: "Акаунт видалено", message: "Ваш акаунт було успішно видалено.")
                self?.navigateToLoginScreen()
            }
        }
    }
    
    private func navigateToLoginScreen() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let window = sceneDelegate.window else {
            return
        }

        let loginVC = LoginViewController()
        let navController = UINavigationController(rootViewController: loginVC)
        navController.setNavigationBarHidden(true, animated: false)
        
        window.rootViewController = navController
        window.makeKeyAndVisible()

        UIView.transition(with: window,
                          duration: AppConstants.defaultAnimationDuration,
                          options: .transitionCrossDissolve,
                          animations: nil,
                          completion: nil)
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if presentedViewController == nil {
            present(alert, animated: true)
        } else {
            presentedViewController?.dismiss(animated: false) { [weak self] in
                self?.present(alert, animated: true)
            }
        }
    }
}
