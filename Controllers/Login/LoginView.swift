import UIKit
import SnapKit

// MARK: - View for Login Screen
class LoginView: UIView {

    // MARK: - UI Elements
    private let gradientLayer = CAGradientLayer()

    let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "AppLogo")
        imageView.tintColor = AppColors.primaryText
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let emailTextField: UITextField = {
        let tf = UITextField()
        AppAppearance.configureTextFieldAppearance(tf,
                                                 placeholderText: "Email",
                                                 font: AppFonts.regular(size: 16),
                                                 textColor: UIColor.black,
                                                 placeholderColor: AppColors.placeholderText,
                                                 backgroundColor: AppColors.primaryText,
                                                 borderColor: AppColors.tertiaryText.withAlphaComponent(0.5),
                                                 borderWidth: 1,
                                                 cornerRadius: AppConstants.cornerRadiusM,
                                                 leftPadding: AppConstants.paddingM)
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        return tf
    }()

    let passwordTextField: UITextField = {
        let tf = UITextField()
        AppAppearance.configureTextFieldAppearance(tf,
                                                 placeholderText: "Пароль",
                                                 font: AppFonts.regular(size: 16),
                                                 textColor: UIColor.black,
                                                 placeholderColor: AppColors.placeholderText,
                                                 backgroundColor: AppColors.primaryText,
                                                 borderColor: AppColors.tertiaryText.withAlphaComponent(0.5),
                                                 borderWidth: 1,
                                                 cornerRadius: AppConstants.cornerRadiusM,
                                                 leftPadding: AppConstants.paddingM)
        tf.isSecureTextEntry = true
        return tf
    }()

    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        AppAppearance.styleButton(button,
                                  title: "Увійти",
                                  font: AppFonts.popupTitle,
                                  titleColor: AppColors.primaryText,
                                  backgroundColor: AppColors.destructiveRedButton,
                                  cornerRadius: AppConstants.cornerRadiusM)
        return button
    }()

    let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Зареєструватися", for: .normal)
        button.titleLabel?.font = AppFonts.regular(size: 16)
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
        addSubview(logoImageView)
        addSubview(emailTextField)
        addSubview(passwordTextField)
        addSubview(loginButton)
        addSubview(registerButton)

        logoImageView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(60)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(200)
        }

        emailTextField.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(AppConstants.paddingXXL)
            make.leading.trailing.equalToSuperview().inset(AppConstants.paddingXXL)
            make.height.equalTo(AppConstants.textFieldHeight)
        }

        passwordTextField.snp.makeConstraints { make in
            make.top.equalTo(emailTextField.snp.bottom).offset(AppConstants.paddingL)
            make.leading.trailing.equalTo(emailTextField)
            make.height.equalTo(AppConstants.textFieldHeight)
        }

        loginButton.snp.makeConstraints { make in
            make.top.equalTo(passwordTextField.snp.bottom).offset(AppConstants.paddingXXL)
            make.leading.trailing.equalTo(emailTextField)
            make.height.equalTo(AppConstants.largeButtonHeight)
        }

        registerButton.snp.makeConstraints { make in
            make.top.equalTo(loginButton.snp.bottom).offset(AppConstants.paddingM)
            make.centerX.equalToSuperview()
        }
    }

    // MARK: - Lifecycle Methods
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
