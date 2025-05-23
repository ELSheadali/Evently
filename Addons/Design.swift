import UIKit

// MARK: - Кольори Додатку
struct AppColors {
    static let primaryDeepRed = UIColor(red: 100/255, green: 0/255, blue: 0/255, alpha: 1.0)
    static let navigationRed = UIColor(red: 120/255, green: 20/255, blue: 20/255, alpha: 1.0)
    static let primaryDeepRedTransparent = UIColor(red: 100/255, green: 0/255, blue: 0/255, alpha: 0.7)
    static let accentYellow = UIColor.systemYellow
    static let primaryText = UIColor.white
    static let secondaryText = UIColor.systemGray
    static let tertiaryText = UIColor.systemGray3
    static let placeholderText = UIColor.systemGray2

    static let subtleBackground = UIColor.white.withAlphaComponent(0.08)
    static let darkSubtleBackground = UIColor.black.withAlphaComponent(0.25)
    static let activityIndicator = UIColor.white
    static let popupBackground = UIColor(red: 40/255, green: 40/255, blue: 60/255, alpha: 1.0)
    static let panelBackground = UIColor(red: 120/255, green: 0/255, blue: 0/255, alpha: 1.0)

    static let accentBlue = UIColor.systemBlue
    static let actionGreen = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
    static let actionRed = UIColor.systemRed
    static let destructiveRedButton = UIColor(red: 170/255, green: 0/255, blue: 0/255, alpha: 1.0)
    static let disabledButtonBackground = UIColor.systemGray.withAlphaComponent(0.7)
    static let warningButtonBackground = UIColor.systemOrange.withAlphaComponent(0.7)
    
    static let textFieldBackgroundDark = UIColor.black.withAlphaComponent(0.3)
    static let textFieldBorderDark = UIColor.black.withAlphaComponent(0.4)
}

// MARK: - Шрифти Додатку
struct AppFonts {
    // Створює стандартний шрифт вказаного розміру.
    static func regular(size: CGFloat) -> UIFont { UIFont.systemFont(ofSize: size) }
    // Створює шрифт середньої жирності вказаного розміру.
    static func medium(size: CGFloat) -> UIFont { UIFont.systemFont(ofSize: size, weight: .medium) }
    // Створює шрифт напівжирний вказаного розміру.
    static func semibold(size: CGFloat) -> UIFont { UIFont.systemFont(ofSize: size, weight: .semibold) }
    // Створює жирний шрифт вказаного розміру.
    static func bold(size: CGFloat) -> UIFont { UIFont.boldSystemFont(ofSize: size) }

    static let navigationTitle = AppFonts.semibold(size: 17)
    static let largeNavigationTitle = AppFonts.bold(size: 34)
    static let tableSectionHeader = AppFonts.semibold(size: 17)
    static let emptyStateLabel = AppFonts.regular(size: 18)
    
    static let cellTitle = AppFonts.medium(size: 16)
    static let cellSubtitle = AppFonts.regular(size: 13)
    static let cellCaption = AppFonts.regular(size: 11)

    static let buttonTitle = AppFonts.bold(size: 16)
    static let smallButtonTitle = AppFonts.bold(size: 11)

    static let popupTitle = AppFonts.bold(size: 20)
    static let drawerTitle = AppFonts.bold(size: 24)
    
    static let profileName = AppFonts.bold(size: 22)
    static let profileSectionHeader = AppFonts.regular(size: 14)
    static let profileValue = AppFonts.regular(size: 16)
    static let profileRatingValue = AppFonts.bold(size: 16)

    static let settingsInstruction = AppFonts.regular(size: 16)
    static let settingsFieldLabel = AppFonts.regular(size: 16)
    static let settingsFieldValue = AppFonts.regular(size: 16)
    static let settingsRatingValue = AppFonts.semibold(size: 22)
}

// MARK: - Константи Додатку
struct AppConstants {
    static let cornerRadiusS: CGFloat = 8.0
    static let cornerRadiusM: CGFloat = 10.0
    static let cornerRadiusL: CGFloat = 16.0
    static let cornerRadiusXL: CGFloat = 22.0

    static let profileImageLargeSize: CGFloat = 150.0
    static let profileImageMediumSize: CGFloat = 120.0
    static let profileImageSmallSize: CGFloat = 44.0
    
    static let paddingXS: CGFloat = 4.0
    static let paddingS: CGFloat = 8.0
    static let paddingM: CGFloat = 12.0
    static let paddingL: CGFloat = 16.0
    static let paddingXL: CGFloat = 20.0
    static let paddingXXL: CGFloat = 30.0

    static let borderWidth: CGFloat = 0.5
    static let textFieldHeight: CGFloat = 44.0
    static let buttonHeight: CGFloat = 46.0
    static let largeButtonHeight: CGFloat = 48.0
    
    static let defaultAnimationDuration: TimeInterval = 0.25
}

// MARK: - Зовнішній Вигляд Додатку
class AppAppearance {

    // Застосовує основний фон до вказаного view.
    static func applyPrimaryBackground(to view: UIView) {
        view.backgroundColor = AppColors.primaryDeepRed
    }
    
    // Застосовує фон панелі до вказаного view.
    static func applyPanelBackground(to view: UIView) {
        view.backgroundColor = AppColors.panelBackground
    }

    // Налаштовує стандартний вигляд навігаційної панелі.
    static func setupStandardNavigationBar(_ navigationController: UINavigationController?,
                                         titleColor: UIColor = AppColors.primaryText,
                                         buttonTintColor: UIColor = AppColors.primaryText,
                                         backgroundColor: UIColor = AppColors.navigationRed) {
        guard let navController = navigationController else { return }
        
        let navBar = navController.navigationBar
        navBar.tintColor = buttonTintColor
        
        let titleAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: titleColor, .font: AppFonts.navigationTitle]
        let largeTitleAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: titleColor, .font: AppFonts.largeNavigationTitle]

        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = backgroundColor
            appearance.titleTextAttributes = titleAttributes
            appearance.largeTitleTextAttributes = largeTitleAttributes

            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
            navBar.compactAppearance = appearance
        } else {
            navBar.barTintColor = backgroundColor
            navBar.titleTextAttributes = titleAttributes
            navBar.isTranslucent = false
        }
    }

    // Стилізує заголовок секції таблиці.
    static func styleTableViewHeader(_ headerView: UITableViewHeaderFooterView, customBackgroundColor: UIColor? = AppColors.primaryDeepRedTransparent) {
        headerView.textLabel?.textColor = AppColors.primaryText.withAlphaComponent(0.9)
        headerView.textLabel?.font = AppFonts.tableSectionHeader
        if let bgColor = customBackgroundColor {
            headerView.contentView.backgroundColor = bgColor
        }
    }

    // Стилізує індикатор активності.
    static func styleActivityIndicator(_ indicator: UIActivityIndicatorView, color: UIColor = AppColors.activityIndicator) {
        indicator.color = color
    }
    
    // Стилізує мітку для порожнього стану.
    static func styleEmptyStateLabel(_ label: UILabel, text: String) {
        label.text = text
        label.textColor = AppColors.secondaryText
        label.textAlignment = .center
        label.font = AppFonts.emptyStateLabel
        label.numberOfLines = 0
    }

    // Стилізує вигляд картки.
    static func styleCardView(_ view: UIView,
                               backgroundColor: UIColor = AppColors.subtleBackground,
                               cornerRadius: CGFloat = AppConstants.cornerRadiusM) {
        view.backgroundColor = backgroundColor
        view.layer.cornerRadius = cornerRadius
        view.clipsToBounds = true
    }
    
    // Стилізує внутрішній заголовок-стрічку.
    static func styleInternalHeaderRibbon(view: UIView, label: UILabel, title: String, backgroundColor: UIColor = AppColors.navigationRed, titleFont: UIFont = AppFonts.navigationTitle, titleColor: UIColor = AppColors.primaryText, cornerRadius: CGFloat = AppConstants.cornerRadiusM) {
        view.backgroundColor = backgroundColor
        view.layer.cornerRadius = cornerRadius
        view.clipsToBounds = true
        
        label.text = title
        label.font = titleFont
        label.textColor = titleColor
        label.textAlignment = .center
    }
    
    // Конфігурує вигляд текстового поля.
    static func configureTextFieldAppearance(_ textField: UITextField,
                                             placeholderText: String,
                                             font: UIFont = AppFonts.regular(size: 15),
                                             textColor: UIColor,
                                             placeholderColor: UIColor,
                                             backgroundColor: UIColor,
                                             borderColor: UIColor = UIColor.clear,
                                             borderWidth: CGFloat = 0,
                                             cornerRadius: CGFloat = AppConstants.cornerRadiusM,
                                             leftPadding: CGFloat = AppConstants.paddingM) {
        textField.placeholder = placeholderText
        textField.font = font
        textField.textColor = textColor
        textField.backgroundColor = backgroundColor
        textField.layer.cornerRadius = cornerRadius
        textField.layer.borderWidth = borderWidth
        textField.layer.borderColor = borderColor.cgColor
        
        if leftPadding > 0 {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: leftPadding, height: textField.frame.height))
            textField.leftView = paddingView
            textField.leftViewMode = .always
        }
        
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [NSAttributedString.Key.foregroundColor: placeholderColor.withAlphaComponent(0.7)]
        )
        textField.autocorrectionType = .no
    }

    // Стилізує текстове поле для темного фону.
    static func styleTextFieldForDarkBackground(_ textField: UITextField, placeholder: String) {
        configureTextFieldAppearance(textField,
                                     placeholderText: placeholder,
                                     textColor: AppColors.primaryText,
                                     placeholderColor: AppColors.placeholderText,
                                     backgroundColor: AppColors.textFieldBackgroundDark,
                                     borderColor: AppColors.textFieldBorderDark,
                                     borderWidth: AppConstants.borderWidth)
    }
    
    // Стилізує текстове поле (багаторядкове).
    static func styleTextView(_ textView: UITextView,
                              font: UIFont = AppFonts.regular(size: 15),
                              textColor: UIColor,
                              backgroundColor: UIColor,
                              cornerRadius: CGFloat = AppConstants.cornerRadiusM,
                              borderColor: UIColor = UIColor.clear,
                              borderWidth: CGFloat = 0,
                              textContainerInset: UIEdgeInsets = UIEdgeInsets(top: AppConstants.paddingS, left: AppConstants.paddingS, bottom: AppConstants.paddingS, right: AppConstants.paddingS)) {
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = backgroundColor
        textView.layer.cornerRadius = cornerRadius
        textView.layer.borderWidth = borderWidth
        textView.layer.borderColor = borderColor.cgColor
        textView.textContainerInset = textContainerInset
        textView.autocorrectionType = .no
    }
    
    // Стилізує текстове поле (багаторядкове) для темного фону.
    static func styleTextViewForDarkBackground(_ textView: UITextView) {
        styleTextView(textView,
                      textColor: AppColors.primaryText,
                      backgroundColor: AppColors.textFieldBackgroundDark,
                      borderColor: AppColors.textFieldBorderDark,
                      borderWidth: AppConstants.borderWidth)
    }

    // Стилізує кнопку.
    static func styleButton(_ button: UIButton,
                            title: String,
                            font: UIFont = AppFonts.buttonTitle,
                            titleColor: UIColor = AppColors.primaryText,
                            backgroundColor: UIColor = AppColors.actionGreen,
                            cornerRadius: CGFloat = AppConstants.cornerRadiusM,
                            image: UIImage? = nil,
                            imagePadding: CGFloat = AppConstants.paddingS) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = backgroundColor
        config.baseForegroundColor = titleColor
        config.cornerStyle = .fixed
        config.image = image
        config.imagePadding = imagePadding
        
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = font
            return outgoing
        }
        button.configuration = config
        button.layer.cornerRadius = cornerRadius
        button.clipsToBounds = true
    }
}
