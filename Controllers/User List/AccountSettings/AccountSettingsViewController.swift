import UIKit
import FirebaseAuth

// MARK: - View Controller for Account Settings Screen
class AccountSettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Properties
    private var accountSettingsView: AccountSettingsView {
        return self.view as! AccountSettingsView
    }

    private var currentUserProfile: UserProfile?
    private var currentUserID: String?
    
    private let datePicker = UIDatePicker()
    private var selectedDateOfBirth: Date?
    private var newProfileImageToUpload: UIImage?

    // MARK: - Lifecycle Methods
    override func loadView() {
        self.view = AccountSettingsView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        
        guard let userID = Auth.auth().currentUser?.uid else {
            showAlert(title: "Помилка", message: "Не вдалося отримати ID користувача. Спробуйте увійти знову.") {
                self.dismissViewController()
            }
            return
        }
        currentUserID = userID
        
        setupDatePicker()
        setupProfileImageTap()
        loadUserData(userID: userID)
        
        accountSettingsView.saveButton.addTarget(self, action: #selector(handleSaveChanges), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        tapGesture.cancelsTouchesInView = false
    }
    
    // MARK: - Setup Methods
    private func setupNavigationBar() {
        navigationItem.title = "Налаштування Профілю"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissViewController))
        AppAppearance.setupStandardNavigationBar(navigationController) 
    }
    
    private func setupDatePicker() {
        datePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.maximumDate = Date()
        
        let toolbar = UIToolbar(); toolbar.sizeToFit()
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.tintColor = AppColors.accentBlue 

        let doneButton = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(doneDatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Скасувати", style: .plain, target: self, action: #selector(cancelDatePicker))
        
        toolbar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        
        accountSettingsView.dateOfBirthTextField.inputAccessoryView = toolbar
        accountSettingsView.dateOfBirthTextField.inputView = datePicker
    }

    private func setupProfileImageTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        accountSettingsView.profileImageView.addGestureRecognizer(tapGesture)
        accountSettingsView.profileImageView.isUserInteractionEnabled = true
    }

    // MARK: - Data Handling
    private func loadUserData(userID: String) {
        if self.currentUserProfile == nil {
            self.currentUserProfile = UserProfile()
        }

        if let currentUser = Auth.auth().currentUser, let displayName = currentUser.displayName {
            let nameComponents = displayName.components(separatedBy: " ")
            accountSettingsView.nameTextField.text = nameComponents.first
            if nameComponents.count > 1 {
                accountSettingsView.surnameTextField.text = nameComponents.dropFirst().joined(separator: " ")
            }
        }

        FirestoreManager.shared.fetchUserProfile(userID: userID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let profile):
                self.currentUserProfile = profile
                DispatchQueue.main.async { self.populateProfileData(profile) }
            case .failure(_):
                DispatchQueue.main.async { self.populateProfileData(self.currentUserProfile ?? UserProfile()) }
            }
        }
    }

    private func populateProfileData(_ profile: UserProfile) {
        accountSettingsView.bioTextView.text = profile.bio ?? ""
        accountSettingsView.placeOfWorkTextField.text = profile.placeOfWork
        
        if let dob = profile.dateOfBirth {
            self.selectedDateOfBirth = dob
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            accountSettingsView.dateOfBirthTextField.text = formatter.string(from: dob)
            datePicker.setDate(dob, animated: false)
        } else {
            accountSettingsView.dateOfBirthTextField.text = ""
            self.selectedDateOfBirth = nil
        }
        
        accountSettingsView.interestsTextField.text = profile.interests?.joined(separator: ", ")
        accountSettingsView.updateRatingDisplay(profile: profile)
        
        accountSettingsView.profileImageView.image = UIImage(systemName: "person.circle.fill")
        accountSettingsView.profileImageView.tintColor = AppColors.primaryText.withAlphaComponent(0.7) 
        if let photoURLString = profile.profilePhotoURL, let photoURL = URL(string: photoURLString) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: photoURL), let image = UIImage(data: data) {
                    DispatchQueue.main.async { self.accountSettingsView.profileImageView.image = image }
                }
            }
        }
    }

    // MARK: - Actions
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func doneDatePicker() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        accountSettingsView.dateOfBirthTextField.text = formatter.string(from: datePicker.date)
        self.selectedDateOfBirth = datePicker.date
        view.endEditing(true)
    }
    
    @objc private func cancelDatePicker() {
        view.endEditing(true)
    }

    @objc private func profileImageTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        let alert = UIAlertController(title: "Змінити фото профілю", message: "Оберіть джерело", preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Камера", style: .default, handler: { _ in
                imagePicker.sourceType = .camera
                self.present(imagePicker, animated: true, completion: nil)
            }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "Галерея", style: .default, handler: { _ in
                imagePicker.sourceType = .photoLibrary
                self.present(imagePicker, animated: true, completion: nil)
            }))
        }
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel, handler: nil))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = accountSettingsView.profileImageView
            popoverController.sourceRect = accountSettingsView.profileImageView.bounds
            popoverController.permittedArrowDirections = []
        }
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func handleSaveChanges() {
        dismissKeyboard()
        guard let userID = currentUserID else {
            showAlert(title: "Помилка", message: "ID користувача не знайдено.")
            return
        }
        guard let name = accountSettingsView.nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
              let surname = accountSettingsView.surnameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !surname.isEmpty else {
            showAlert(title: "Помилка", message: "Ім'я та прізвище не можуть бути порожніми.")
            return
        }

        accountSettingsView.saveButton.isEnabled = false
        // Consider showing an activity indicator

        func saveProfileToFirestore(photoURLString: String?) {
            let newDisplayName = "\(name) \(surname)"
            let authChangeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            authChangeRequest?.displayName = newDisplayName
            
            authChangeRequest?.commitChanges { [weak self] authError in
                guard let self = self else {
                    DispatchQueue.main.async { self?.accountSettingsView.saveButton.isEnabled = true }
                    return
                }
                if let authError = authError {
                    self.showAlert(title: "Помилка оновлення імені", message: authError.localizedDescription)
                    self.accountSettingsView.saveButton.isEnabled = true; return
                }
                
                if self.currentUserProfile == nil { self.currentUserProfile = UserProfile(uid: userID) }
                else { if self.currentUserProfile!.uid == nil { self.currentUserProfile!.uid = userID } }
                
                self.currentUserProfile?.firstName = name
                self.currentUserProfile?.lastName = surname
                self.currentUserProfile?.bio = self.accountSettingsView.bioTextView.text
                self.currentUserProfile?.placeOfWork = self.accountSettingsView.placeOfWorkTextField.text
                self.currentUserProfile?.dateOfBirth = self.selectedDateOfBirth
                let updatedInterestsString = self.accountSettingsView.interestsTextField.text
                self.currentUserProfile?.interests = updatedInterestsString?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                if let newPhotoURL = photoURLString { self.currentUserProfile?.profilePhotoURL = newPhotoURL }

                FirestoreManager.shared.updateUserProfile(userID: userID, profile: self.currentUserProfile!) { firestoreError in
                    self.accountSettingsView.saveButton.isEnabled = true
                    if let firestoreError = firestoreError {
                        self.showAlert(title: "Помилка збереження профілю", message: firestoreError.localizedDescription)
                    } else {
                        self.showAlert(title: "Успіх", message: "Дані профілю оновлено.")
                        self.accountSettingsView.updateRatingDisplay(profile: self.currentUserProfile!)
                    }
                }
            }
        }

        if let imageToUpload = self.newProfileImageToUpload {
            StorageManager.shared.uploadUserProfilePhoto(imageToUpload, userID: userID) { [weak self] result in
                guard let self = self else {
                    DispatchQueue.main.async { self?.accountSettingsView.saveButton.isEnabled = true }
                    return
                }
                switch result {
                case .success(let url):
                    self.newProfileImageToUpload = nil
                    saveProfileToFirestore(photoURLString: url.absoluteString)
                case .failure(let error):
                    self.showAlert(title: "Помилка завантаження фото", message: error.localizedDescription)
                    self.accountSettingsView.saveButton.isEnabled = true
                }
            }
        } else {
            saveProfileToFirestore(photoURLString: self.currentUserProfile?.profilePhotoURL)
        }
    }

    // MARK: - Helper Methods
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completion?() }))
        present(alert, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else { return }
        accountSettingsView.profileImageView.image = selectedImage
        self.newProfileImageToUpload = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
