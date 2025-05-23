import UIKit
import SnapKit

// MARK: - View for Registration Screen
class RegisterView: UIView {

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()

    let nameTextField = RegisterView.createStyledTextField(placeholder: "Ім'я")
    let surnameTextField = RegisterView.createStyledTextField(placeholder: "Прізвище")
    let emailTextField = RegisterView.createStyledTextField(placeholder: "Email", keyboardType: .emailAddress, autocapitalizationType: .none)
    let passwordTextField: UITextField = {
        let tf = RegisterView.createStyledTextField(placeholder: "Пароль")
        tf.isSecureTextEntry = true
        return tf
    }()

    let registerButton: UIButton = {
        let button = UIButton(type: .system)
        AppAppearance.styleButton(button,
                                  title: "Зареєструватися",
                                  font: AppFonts.popupTitle,
                                  titleColor: AppColors.primaryText,
                                  backgroundColor: AppColors.destructiveRedButton,
                                  cornerRadius: AppConstants.cornerRadiusM)
        return button
    }()

    let loginButton: UIButton = { // Кнопка для переходу на екран входу
        let button = UIButton(type: .system)
        button.setTitle("Вже є акаунт? Увійти", for: .normal)
        button.titleLabel?.font = AppFonts.regular(size: 15)
        button.setTitleColor(AppColors.primaryText, for: .normal)
        return button
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup Methods
    private func setupGradient() {
        gradientLayer.colors = [
            AppColors.primaryDeepRed.cgColor,
            UIColor(red: 75/255, green: 0, blue: 130/255, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupViews() {
        let textFields = [nameTextField, surnameTextField, emailTextField, passwordTextField]
        let stack = UIStackView(arrangedSubviews: textFields)
        stack.axis = .vertical
        stack.spacing = AppConstants.paddingL
        stack.distribution = .fill

        addSubview(stack)
        addSubview(registerButton)
        addSubview(loginButton)

        textFields.forEach { textField in
            textField.snp.makeConstraints { make in
                make.height.equalTo(AppConstants.textFieldHeight)
            }
        }

        stack.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-AppConstants.paddingXXL)
            make.leading.trailing.equalToSuperview().inset(AppConstants.paddingL)
        }

        registerButton.snp.makeConstraints { make in
            make.top.equalTo(stack.snp.bottom).offset(AppConstants.paddingXXL)
            make.leading.trailing.equalTo(stack)
            make.height.equalTo(AppConstants.largeButtonHeight)
        }

        loginButton.snp.makeConstraints { make in
            make.top.equalTo(registerButton.snp.bottom).offset(AppConstants.paddingM)
            make.centerX.equalToSuperview()
        }
    }
    
    // MARK: - Lifecycle Methods
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // MARK: - Static Factory Method for TextFields
    private static func createStyledTextField(placeholder: String, keyboardType: UIKeyboardType = .default, autocapitalizationType: UITextAutocapitalizationType = .words) -> UITextField {
        let tf = UITextField()
        AppAppearance.configureTextFieldAppearance(tf,
                                                 placeholderText: placeholder,
                                                 font: AppFonts.regular(size: 16),
                                                 // --- Змінено тут: колір тексту тепер чорний ---
                                                 textColor: .black,
                                                 placeholderColor: AppColors.placeholderText,
                                                 backgroundColor: AppColors.primaryText,
                                                 borderColor: AppColors.tertiaryText.withAlphaComponent(0.5),
                                                 borderWidth: 1,
                                                 cornerRadius: AppConstants.cornerRadiusM,
                                                 leftPadding: AppConstants.paddingM)
        tf.keyboardType = keyboardType
        tf.autocapitalizationType = autocapitalizationType
        return tf
    }
}
