import UIKit
import SnapKit

// MARK: - View for Account Settings Screen
class AccountSettingsView: UIView {
    
    // MARK: - UI Elements - ScrollView & ContentView
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = true
        return sv
    }()
    
    let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    // MARK: - UI Elements - Profile Image & Instruction
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = AppConstants.profileImageLargeSize / 2 
        imageView.backgroundColor = AppColors.placeholderText.withAlphaComponent(0.5) 
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = AppColors.primaryText.withAlphaComponent(0.7) 
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Заповніть або оновіть інформацію про себе."
        label.font = AppFonts.settingsInstruction 
        label.textColor = AppColors.primaryText 
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - UI Elements - Ratings Display
    private let organizerRatingTitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.settingsFieldLabel 
        label.textColor = AppColors.secondaryText 
        label.textAlignment = .center
        label.text = "Рейтинг організатора"
        return label
    }()

    let organizerRatingValueDisplayLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.settingsRatingValue 
        label.textColor = AppColors.primaryText 
        label.textAlignment = .center
        label.text = "–"
        return label
    }()

    private let participantRatingTitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.settingsFieldLabel 
        label.textColor = AppColors.secondaryText 
        label.textAlignment = .center
        label.text = "Рейтинг учасника"
        return label
    }()

    let participantRatingValueDisplayLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.settingsRatingValue 
        label.textColor = AppColors.primaryText 
        label.textAlignment = .center
        label.text = "–"
        return label
    }()

    private let ratingsStackView: UIStackView = {
        let organizerStack = UIStackView()
        organizerStack.axis = .vertical
        organizerStack.alignment = .center
        organizerStack.spacing = AppConstants.paddingXS / 2 

        let participantStack = UIStackView()
        participantStack.axis = .vertical
        participantStack.alignment = .center
        participantStack.spacing = AppConstants.paddingXS / 2 
        
        let mainStack = UIStackView(arrangedSubviews: [organizerStack, participantStack])
        mainStack.axis = .horizontal
        mainStack.distribution = .fillEqually
        mainStack.alignment = .top
        mainStack.spacing = AppConstants.paddingS 
        return mainStack
    }()

    // MARK: - UI Elements - Text Fields & View
    let nameTextField: UITextField = {
        let tf = UITextField()
        AppAppearance.styleTextFieldForDarkBackground(tf, placeholder: "Ім'я") 
        return tf
    }()

    let surnameTextField: UITextField = {
        let tf = UITextField()
        AppAppearance.styleTextFieldForDarkBackground(tf, placeholder: "Прізвище") 
        return tf
    }()
    
    let bioLabel: UILabel = {
        let label = UILabel()
        label.text = "Біографія:"
        label.textColor = AppColors.primaryText 
        label.font = AppFonts.settingsFieldLabel 
        return label
    }()

    let bioTextView: UITextView = {
        let tv = UITextView()
        AppAppearance.styleTextViewForDarkBackground(tv) 
        tv.isScrollEnabled = true
        return tv
    }()

    let placeOfWorkTextField: UITextField = {
        let tf = UITextField()
        AppAppearance.styleTextFieldForDarkBackground(tf, placeholder: "Місце роботи") 
        return tf
    }()
    
    let interestsTextField: UITextField = {
        let tf = UITextField()
        AppAppearance.styleTextFieldForDarkBackground(tf, placeholder: "Інтереси (через кому)") 
        return tf
    }()

    let dateOfBirthTextField: UITextField = {
        let tf = UITextField()
        AppAppearance.styleTextFieldForDarkBackground(tf, placeholder: "Дата народження (оберіть)") 
        return tf
    }()

    // MARK: - UI Elements - Save Button
    let saveButton: UIButton = {
        let button = UIButton(type: .system)
        AppAppearance.styleButton(button,
                                  title: "Зберегти Зміни",
                                  font: AppFonts.bold(size: 18), 
                                  backgroundColor: AppColors.actionGreen) 
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        AppAppearance.applyPrimaryBackground(to: self) 
        setupViews()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup Layout
    private func setupViews() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        [profileImageView, instructionLabel,
         ratingsStackView,
         nameTextField, surnameTextField,
         bioLabel, bioTextView,
         placeOfWorkTextField, interestsTextField,
         dateOfBirthTextField, saveButton].forEach { contentView.addSubview($0) }

        guard ratingsStackView.arrangedSubviews.count == 2,
              let organizerStack = ratingsStackView.arrangedSubviews.first as? UIStackView,
              let participantStack = ratingsStackView.arrangedSubviews.last as? UIStackView else {
            return
        }
        organizerStack.addArrangedSubview(organizerRatingTitleLabel)
        organizerStack.addArrangedSubview(organizerRatingValueDisplayLabel)
        participantStack.addArrangedSubview(participantRatingTitleLabel)
        participantStack.addArrangedSubview(participantRatingValueDisplayLabel)

        // --- Constraints ---
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(safeAreaLayoutGuide)
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        profileImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppConstants.paddingXL) 
            make.centerX.equalToSuperview()
            make.width.height.equalTo(AppConstants.profileImageLargeSize) 
        }
        instructionLabel.snp.makeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(AppConstants.paddingXL) 
            make.leading.trailing.equalToSuperview().inset(AppConstants.paddingXXL) 
        }
        ratingsStackView.snp.makeConstraints { make in
            make.top.equalTo(instructionLabel.snp.bottom).offset(AppConstants.paddingXL) 
            make.leading.trailing.equalToSuperview().inset(AppConstants.paddingXL) 
        }
        nameTextField.snp.makeConstraints { make in
            make.top.equalTo(ratingsStackView.snp.bottom).offset(AppConstants.paddingXL) 
            make.leading.trailing.equalToSuperview().inset(AppConstants.paddingXXL) 
            make.height.equalTo(AppConstants.textFieldHeight) 
        }
        surnameTextField.snp.makeConstraints { make in
            make.top.equalTo(nameTextField.snp.bottom).offset(AppConstants.paddingL) 
            make.leading.trailing.equalTo(nameTextField)
            make.height.equalTo(AppConstants.textFieldHeight) 
        }
        bioLabel.snp.makeConstraints { make in
            make.top.equalTo(surnameTextField.snp.bottom).offset(AppConstants.paddingXL) 
            make.leading.equalTo(nameTextField)
        }
        bioTextView.snp.makeConstraints { make in
            make.top.equalTo(bioLabel.snp.bottom).offset(AppConstants.paddingS) 
            make.leading.trailing.equalTo(nameTextField)
            make.height.equalTo(100)
        }
        placeOfWorkTextField.snp.makeConstraints { make in
            make.top.equalTo(bioTextView.snp.bottom).offset(AppConstants.paddingL) 
            make.leading.trailing.equalTo(nameTextField)
            make.height.equalTo(AppConstants.textFieldHeight) 
        }
        interestsTextField.snp.makeConstraints { make in
            make.top.equalTo(placeOfWorkTextField.snp.bottom).offset(AppConstants.paddingL) 
            make.leading.trailing.equalTo(nameTextField)
            make.height.equalTo(AppConstants.textFieldHeight) 
        }
        dateOfBirthTextField.snp.makeConstraints { make in
            make.top.equalTo(interestsTextField.snp.bottom).offset(AppConstants.paddingL) 
            make.leading.trailing.equalTo(nameTextField)
            make.height.equalTo(AppConstants.textFieldHeight) 
        }
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(dateOfBirthTextField.snp.bottom).offset(AppConstants.paddingXXL) 
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(AppConstants.largeButtonHeight) 
            make.bottom.equalToSuperview().inset(AppConstants.paddingXXL)
        }
    }
    
    // MARK: - Keyboard Handling
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        var bottomInset = keyboardFrame.height
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) {
             if keyboardFrame.maxY >= window.frame.height - window.safeAreaInsets.bottom {
                bottomInset -= window.safeAreaInsets.bottom
            }
        }

        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    // MARK: - UI Update Methods
    func updateRatingDisplay(profile: UserProfile) {
        var hasAnyRating = false
        if let avgOrgRating = profile.averageOrganizerRating, let orgCount = profile.organizerRatingsCount, orgCount > 0 {
            organizerRatingValueDisplayLabel.text = String(format: "%.1f", avgOrgRating)
            hasAnyRating = true
        } else {
            organizerRatingValueDisplayLabel.text = "–"
        }

        if let avgPartRating = profile.averageParticipantRating, let partCount = profile.participantRatingsCount, partCount > 0 {
            participantRatingValueDisplayLabel.text = String(format: "%.1f", avgPartRating)
            hasAnyRating = true
        } else {
            participantRatingValueDisplayLabel.text = "–"
        }
        ratingsStackView.isHidden = !hasAnyRating 
    }
}
