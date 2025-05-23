import UIKit
import FirebaseAuth
import FirebaseFirestore

// MARK: - Контролер для спливаючого вікна профілю користувача
class UserProfilePopupViewController: UIViewController {

    // MARK: - Properties
    private var userProfilePopupView: UserProfilePopupView {
        // Примусове приведення типу, оскільки ми впевнені, що view буде UserProfilePopupView
        return self.view as! UserProfilePopupView
    }

    private let userID: String
    private var userProfile: UserProfile?

    // MARK: - Initialization
    init(userID: String) {
        self.userID = userID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods
    override func loadView() {
        // Встановлюємо кастомне view
        self.view = UserProfilePopupView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        loadUserProfile()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Тут можна додати логіку, якщо потрібно оновити розмір контенту scrollView
        // після того, як всі елементи отримали свої фінальні розміри.
        // Зазвичай AutoLayout справляється з цим автоматично.
    }

    // MARK: - Setup Methods
    private func setupNavigationBar() {
        navigationItem.title = "Завантаження..." // Початковий заголовок
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissView))
        navigationItem.rightBarButtonItem = doneButton
        
        AppAppearance.setupStandardNavigationBar(navigationController) 
    }

    // MARK: - Data Loading
    private func loadUserProfile() {
        userProfilePopupView.showLoadingState(true)

        FirestoreManager.shared.fetchUserProfile(userID: userID) { [weak self] result in
            guard let self = self else { return }
            self.userProfilePopupView.showLoadingState(false)

            switch result {
            case .success(var profile):
                // Переконуємося, що UID встановлено в профілі
                profile.uid = self.userID
                self.userProfile = profile
                
                let displayName = "\(profile.firstName ?? "") \(profile.lastName ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
                self.navigationItem.title = displayName.isEmpty ? "Профіль користувача" : displayName
                
                self.userProfilePopupView.configure(with: profile)
                self.userProfilePopupView.showData() // Показуємо scrollView з даними

            case .failure(_):
                self.navigationItem.title = "Профіль не знайдено"
                self.userProfilePopupView.showNoDataAvailable(message: "Не вдалося завантажити профіль. Спробуйте пізніше.")
            }
            // Оновлення layout після заповнення даних, особливо для UITextView та StackView
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Actions
    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}
