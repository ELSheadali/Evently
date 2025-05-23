import UIKit
import SnapKit

// MARK: - View для спливаючого вікна створення/редагування/перегляду події
class EventPopupView: UIView {
    
    // MARK: - UI Elements - Container and Header
    let popupContainerView: UIView = {
        let view = UIView()
        AppAppearance.applyPanelBackground(to: view) 
        view.layer.cornerRadius = AppConstants.cornerRadiusL 
        view.layer.masksToBounds = false // Дозволяє тіням, якщо вони будуть
        return view
    }()
    
    let headerRibbonView: UIView = {
        let view = UIView()
        // Стилізація відбувається в setupViews
        return view
    }()

    let headerRibbonLabel: UILabel = {
        let label = UILabel()
        // Стилізація відбувається в setupViews
        return label
    }()
    
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = AppColors.placeholderText 
        return button
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.popupTitle 
        label.textColor = AppColors.primaryText 
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    // MARK: - UI Elements - ScrollView and Content
    let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = true
        scroll.backgroundColor = .clear
        return scroll
    }()

    let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    // MARK: - UI Elements - Input Fields and Buttons
    let photoPreview: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = AppColors.textFieldBackgroundDark.withAlphaComponent(0.5) 
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = AppConstants.cornerRadiusM 
        imageView.image = UIImage(systemName: "photo.on.rectangle.angled")
        imageView.tintColor = AppColors.primaryText.withAlphaComponent(0.7) 
        return imageView
    }()

    let addPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Додати фото", for: .normal)
        button.setTitleColor(AppColors.accentBlue, for: .normal) 
        button.titleLabel?.font = AppFonts.regular(size: 16) 
        return button
    }()

    lazy var nameField: UITextField = {
        let tf = UITextField()
        AppAppearance.styleTextFieldForDarkBackground(tf, placeholder: "Назва події (макс. 30 симв.)") 
        return tf
    }()
    
    let selectThemeButton: UIButton = {
        let button = UIButton(type: .system)
        // Детальна стилізація через UIButton.Configuration в setupLayoutConstraints
        return button
    }()

    let themesSelectionTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = AppColors.primaryDeepRed.withAlphaComponent(0.95) 
        tableView.layer.borderColor = AppColors.textFieldBorderDark.cgColor 
        tableView.layer.borderWidth = AppConstants.borderWidth 
        tableView.layer.cornerRadius = AppConstants.cornerRadiusM 
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PopupThemeCell")
        tableView.allowsMultipleSelection = true
        tableView.clipsToBounds = true
        tableView.isHidden = true
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = AppColors.textFieldBorderDark.withAlphaComponent(0.8) 
        return tableView
    }()
    var isThemesListVisible: Bool = false

    lazy var peopleField: UITextField = {
        let field = UITextField()
        AppAppearance.styleTextFieldForDarkBackground(field, placeholder: "Кількість осіб (1-1000)") 
        field.keyboardType = .numberPad
        return field
    }()
    
    lazy var locationField: UITextField = {
        let tf = UITextField()
        AppAppearance.styleTextFieldForDarkBackground(tf, placeholder: "Введіть адресу") 
        return tf
    }()
    
    let getCurrentLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "location.fill"), for: .normal)
        button.tintColor = AppColors.accentBlue 
        return button
    }()

    lazy var dateField: UITextField = {
        let tf = UITextField()
        AppAppearance.styleTextFieldForDarkBackground(tf, placeholder: "Дата та час події") 
        return tf
    }()

    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Опис (макс. 200 симв.):"
        label.font = AppFonts.regular(size: 13) 
        label.textColor = AppColors.secondaryText 
        return label
    }()

    let descriptionTextView: UITextView = {
        let textView = UITextView()
        AppAppearance.styleTextViewForDarkBackground(textView) 
        return textView
    }()
    
    let datePicker = UIDatePicker()

    // MARK: - UI Elements - Action Buttons
    let primaryActionButton: UIButton = {
        let button = UIButton() // Стилізація в configureForMode
        return button
    }()
    
    let actionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = AppConstants.paddingS 
        stackView.distribution = .fill // Кнопки будуть розтягуватися по ширині
        stackView.isHidden = true // Початково приховано
        return stackView
    }()

    lazy var rateEventButton: UIButton = createStyledActionButton(
        title: "Оцінити Подію",
        systemImageName: "star.leadinghalf.filled",
        backgroundColor: AppColors.accentBlue.withAlphaComponent(0.8) 
    )
    lazy var editButton: UIButton = createStyledActionButton(
        title: "Редагувати",
        systemImageName: "pencil.circle.fill",
        backgroundColor: AppColors.accentBlue 
    )
    lazy var deleteButton: UIButton = createStyledActionButton(
        title: "Видалити",
        systemImageName: "trash.circle.fill",
        backgroundColor: AppColors.actionRed 
    )
    lazy var joinLeaveButton: UIButton = createStyledActionButton(
        title: "Приєднатися", // Текст буде змінюватися динамічно
        systemImageName: "person.crop.circle.badge.plus.fill", // Іконка буде змінюватися
        backgroundColor: AppColors.actionGreen // Колір буде змінюватися 
    )
    lazy var viewParticipantsButton: UIButton = createStyledActionButton(
        title: "Учасники",
        systemImageName: "person.2.circle.fill",
        backgroundColor: AppColors.secondaryText.withAlphaComponent(0.8) 
    )

    // MARK: - UI Elements - Address Suggestions
    let addressSuggestionsTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = AppColors.primaryDeepRed.withAlphaComponent(0.9) 
        tableView.layer.cornerRadius = AppConstants.cornerRadiusM 
        tableView.isHidden = true
        tableView.layer.borderColor = AppColors.secondaryText.withAlphaComponent(0.5).cgColor 
        tableView.layer.borderWidth = AppConstants.borderWidth 
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "suggestionCell")
        return tableView
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear // Фон самого EventPopupView прозорий
        setupViews()
        setupLayoutConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        // Стилізація стрічки заголовка
        AppAppearance.styleInternalHeaderRibbon(view: headerRibbonView, label: headerRibbonLabel, title: "", cornerRadius: 0) 
        headerRibbonView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] // Заокруглюємо тільки верхні кути
        headerRibbonView.layer.cornerRadius = AppConstants.cornerRadiusL 

        addSubview(popupContainerView)
        popupContainerView.addSubview(headerRibbonView)
        headerRibbonView.addSubview(headerRibbonLabel)
        popupContainerView.addSubview(closeButton)
        popupContainerView.addSubview(titleLabel)
        popupContainerView.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Таблиця вибору тем додається до popupContainerView, щоб вона могла перекривати scrollView
        popupContainerView.addSubview(themesSelectionTableView)

        // Додавання елементів до contentView
        [photoPreview, addPhotoButton, nameField, selectThemeButton, peopleField,
         descriptionLabel, descriptionTextView, locationField, getCurrentLocationButton,
         dateField, primaryActionButton, actionsStackView,
         addressSuggestionsTableView
        ].forEach { contentView.addSubview($0) }
         
        // Додавання кнопок до actionsStackView
        actionsStackView.addArrangedSubview(joinLeaveButton)
        actionsStackView.addArrangedSubview(editButton)
        actionsStackView.addArrangedSubview(deleteButton)
        actionsStackView.addArrangedSubview(viewParticipantsButton)
        actionsStackView.addArrangedSubview(rateEventButton)
    }

    private func createStyledActionButton(title: String, systemImageName: String?, backgroundColor: UIColor, titleColor: UIColor = AppColors.primaryText, font: UIFont = AppFonts.medium(size: 15)) -> UIButton {
        let button = UIButton()
        AppAppearance.styleButton(button, title: title, font: font, titleColor: titleColor, backgroundColor: backgroundColor, image: systemImageName != nil ? UIImage(systemName: systemImageName!) : nil, imagePadding: AppConstants.paddingS) 
        // Налаштування внутрішніх відступів кнопки та висоти
        if var currentConfig = button.configuration {
            currentConfig.contentInsets = NSDirectionalEdgeInsets(top: AppConstants.paddingS, leading: AppConstants.paddingM, bottom: AppConstants.paddingS, trailing: AppConstants.paddingM) 
            button.configuration = currentConfig
        }
        button.snp.makeConstraints { make in make.height.equalTo(AppConstants.textFieldHeight - AppConstants.paddingXS) } 
        return button
    }
    
    // MARK: - Layout Constraints Setup
    private func setupLayoutConstraints() {
        popupContainerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.88) // Ширина попапу
            make.height.lessThanOrEqualToSuperview().multipliedBy(0.75).priority(.high) // Максимальна висота
            make.height.greaterThanOrEqualTo(600).priority(.medium) // Мінімальна висота
        }
        
        headerRibbonView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(AppConstants.largeButtonHeight + AppConstants.paddingS) 
        }
        headerRibbonLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(AppConstants.paddingL) 
        }

        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(headerRibbonLabel)
            make.trailing.equalTo(headerRibbonView).inset(AppConstants.paddingM) 
            make.width.height.equalTo(AppConstants.paddingXXL)
        }

        titleLabel.textAlignment = .left // Змінено для відповідності дизайну
        titleLabel.font = AppFonts.bold(size: 18) 
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerRibbonView.snp.bottom).offset(AppConstants.paddingM) 
            make.leading.equalToSuperview().offset(AppConstants.paddingL) 
            make.trailing.equalToSuperview().inset(AppConstants.paddingL) 
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppConstants.paddingM) 
            make.leading.equalToSuperview().inset(AppConstants.paddingL) 
            make.trailing.equalToSuperview().inset(AppConstants.paddingL) 
            make.bottom.equalToSuperview().inset(AppConstants.paddingL) 
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview() // Важливо для вертикального скролу
        }

        // Загальні константи для полів вводу
        let sidePadding: CGFloat = AppConstants.paddingXS 
        let verticalSpacing: CGFloat = AppConstants.paddingM 
        let fieldHeight: CGFloat = AppConstants.textFieldHeight 

        photoPreview.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppConstants.paddingS) 
            make.leading.equalToSuperview().offset(sidePadding)
            make.width.height.equalTo(90) // Розмір фото
        }
        
        addPhotoButton.snp.makeConstraints { make in
            make.top.equalTo(photoPreview.snp.bottom).offset(AppConstants.paddingXS) 
            make.centerX.equalTo(photoPreview)
        }
        
        nameField.snp.makeConstraints { make in
            make.top.equalTo(photoPreview.snp.top)
            make.leading.equalTo(photoPreview.snp.trailing).offset(AppConstants.paddingM) 
            make.trailing.equalToSuperview().inset(sidePadding)
            make.height.equalTo(fieldHeight)
        }
        
        var themeButtonConfig = UIButton.Configuration.plain()
        themeButtonConfig.attributedTitle = AttributedString("Обрати тему (до 3-х)", attributes: AttributeContainer([
            .font: AppFonts.regular(size: 15), 
            .foregroundColor: AppColors.placeholderText 
        ]))
        themeButtonConfig.background.backgroundColor = AppColors.textFieldBackgroundDark 
        themeButtonConfig.background.cornerRadius = AppConstants.cornerRadiusM 
        themeButtonConfig.background.strokeColor = AppColors.textFieldBorderDark 
        themeButtonConfig.background.strokeWidth = AppConstants.borderWidth 
        themeButtonConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: AppConstants.paddingM, bottom: 10, trailing: AppConstants.paddingM) 
        selectThemeButton.configuration = themeButtonConfig
        selectThemeButton.contentHorizontalAlignment = .left
        
        selectThemeButton.snp.makeConstraints { make in
            make.top.equalTo(nameField.snp.bottom).offset(verticalSpacing)
            make.leading.trailing.equalTo(nameField)
            make.height.equalTo(fieldHeight)
        }
        
        peopleField.snp.makeConstraints { make in
            make.top.equalTo(selectThemeButton.snp.bottom).offset(verticalSpacing)
            make.leading.trailing.equalTo(nameField)
            make.height.equalTo(fieldHeight)
        }
        
        getCurrentLocationButton.snp.makeConstraints { make in
            make.top.equalTo(peopleField.snp.bottom).offset(verticalSpacing)
            make.trailing.equalToSuperview().inset(sidePadding)
            make.height.equalTo(fieldHeight)
            make.width.equalTo(fieldHeight) // Квадратна кнопка
        }

        locationField.snp.makeConstraints { make in
            make.top.equalTo(peopleField.snp.bottom).offset(verticalSpacing)
            make.leading.equalToSuperview().offset(sidePadding)
            make.trailing.equalTo(getCurrentLocationButton.snp.leading).offset(-AppConstants.paddingS) 
            make.height.equalTo(fieldHeight)
        }

        addressSuggestionsTableView.snp.makeConstraints { make in
            make.top.equalTo(locationField.snp.bottom).offset(AppConstants.paddingXS) 
            make.leading.equalTo(locationField.snp.leading)
            make.trailing.equalTo(getCurrentLocationButton.snp.trailing) // Розтягуємо до кінця кнопки геолокації
            make.height.equalTo(0) // Початкова висота 0, буде оновлюватися
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(locationField.snp.bottom).offset(verticalSpacing).priority(.high)
            // Переконаємося, що descriptionLabel завжди нижче таблиці пропозицій, якщо вона видима
            make.top.greaterThanOrEqualTo(addressSuggestionsTableView.snp.bottom).offset(verticalSpacing).priority(.required)
            make.leading.equalToSuperview().offset(sidePadding)
            make.trailing.equalToSuperview().inset(sidePadding)
        }
        
        descriptionTextView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(AppConstants.paddingXS) 
            make.leading.equalToSuperview().offset(sidePadding)
            make.trailing.equalToSuperview().inset(sidePadding)
            make.height.equalTo(85) // Висота поля опису
        }
        
        dateField.snp.makeConstraints { make in
            make.top.equalTo(descriptionTextView.snp.bottom).offset(verticalSpacing)
            make.leading.equalToSuperview().offset(sidePadding)
            make.trailing.equalToSuperview().inset(sidePadding)
            make.height.equalTo(fieldHeight)
        }
        
        primaryActionButton.snp.makeConstraints { make in
            make.top.equalTo(dateField.snp.bottom).offset(AppConstants.paddingXL) 
            make.leading.equalToSuperview().offset(sidePadding + AppConstants.paddingXL) 
            make.trailing.equalToSuperview().inset(sidePadding + AppConstants.paddingXL) 
            make.height.equalTo(AppConstants.buttonHeight) 
        }
        
        actionsStackView.snp.makeConstraints { make in
            make.top.equalTo(primaryActionButton.snp.top) // Розміщуємо на тому ж рівні, що і primaryActionButton
            make.leading.trailing.equalTo(primaryActionButton)
        }
        
        // Прив'язка низу contentView до останнього видимого елемента
        contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            let lastElement: UIView
            if !primaryActionButton.isHidden { lastElement = primaryActionButton }
            else if !actionsStackView.isHidden { lastElement = actionsStackView }
            else { lastElement = dateField } // Якщо всі кнопки приховані, прив'язуємось до dateField
            make.bottom.equalTo(lastElement.snp.bottom).offset(AppConstants.paddingS).priority(.high) 
        }
    }
    
    // MARK: - Configuration and Updates
    func configureForMode(isCreating: Bool, event: Event? = nil, descriptionPlaceholder: String = "Опис події...") {
        let headerTitle = isCreating ? "Створити подію" : (event?.name ?? "Деталі події")
        headerRibbonLabel.text = headerTitle
        titleLabel.text = "Основна інформація"

        primaryActionButton.isHidden = true
        actionsStackView.isHidden = true
        editButton.isHidden = true
        deleteButton.isHidden = true
        joinLeaveButton.isHidden = true
        viewParticipantsButton.isHidden = true
        rateEventButton.isHidden = true
        addPhotoButton.isHidden = true
        getCurrentLocationButton.isHidden = true

        if isCreating {
            AppAppearance.styleButton(primaryActionButton, title: "Створити подію", backgroundColor: AppColors.actionGreen) 
            primaryActionButton.isHidden = false
            addPhotoButton.isHidden = false
            getCurrentLocationButton.isHidden = false
            
            [nameField, peopleField, locationField, dateField].forEach { $0.text = nil }
            updateSelectThemeButtonAppearance(selectedThemeNames: nil) // Скидаємо теми
            descriptionTextView.text = "" // Очищуємо поле опису
            photoPreview.image = UIImage(systemName: "photo.on.rectangle.angled") // Іконка-заглушка
            photoPreview.tintColor = AppColors.primaryText.withAlphaComponent(0.4) 
            setFieldsEditable(true)

        } else if let event = event {
            addPhotoButton.isHidden = true // Зазвичай не показуємо для існуючих подій в режимі перегляду
            getCurrentLocationButton.isHidden = true

            nameField.text = event.name
            updateSelectThemeButtonAppearance(selectedThemeNames: event.themes)
            peopleField.text = "\(event.maxPeople)"
            descriptionTextView.text = event.description.isEmpty ? descriptionPlaceholder : event.description
            locationField.text = event.location
            let formatter = DateFormatter(); formatter.dateFormat = "dd MMMM HH:mm"; formatter.locale = Locale(identifier: "uk_UA")
            dateField.text = formatter.string(from: event.date)
            
            if let photoURLString = event.photoURL, !photoURLString.isEmpty, let url = URL(string: photoURLString) {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.photoPreview.image = image
                            self.photoPreview.tintColor = .clear // Забираємо tint, якщо було фото
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.photoPreview.image = UIImage(systemName: "photo.fill") // Інша іконка, якщо фото не завантажилось
                            self.photoPreview.tintColor = AppColors.primaryText 
                        }
                    }
                }
            } else {
                photoPreview.image = UIImage(systemName: "photo") // Іконка-заглушка, якщо URL немає
                photoPreview.tintColor = AppColors.primaryText.withAlphaComponent(0.4) 
            }
            setFieldsEditable(false) // Поля нередаговані в режимі перегляду
        }
        updateContentViewBottomConstraint() // Оновлюємо констрейнти для правильного розміру scroll view
    }

    func updateSelectThemeButtonAppearance(selectedThemeNames: [String]?) {
        guard var currentConfig = selectThemeButton.configuration else { return }
        if let names = selectedThemeNames, !names.isEmpty {
            let themesText = names.joined(separator: ", ")
            let buttonTitle = themesText.count > 35 ? "Обрано (\(names.count)) тем" : themesText
            currentConfig.attributedTitle = AttributedString(buttonTitle, attributes: AttributeContainer([
                .font: AppFonts.regular(size: 15), .foregroundColor: AppColors.primaryText 
            ]))
        } else {
            currentConfig.attributedTitle = AttributedString("Обрати тему (до 3-х)", attributes: AttributeContainer([
                .font: AppFonts.regular(size: 15), .foregroundColor: AppColors.placeholderText 
            ]))
        }
        selectThemeButton.configuration = currentConfig
    }

    func updateContentViewBottomConstraint() {
        let lastVisibleInteractiveElement: UIView
        if !primaryActionButton.isHidden { lastVisibleInteractiveElement = primaryActionButton }
        else if !actionsStackView.isHidden { lastVisibleInteractiveElement = actionsStackView }
        else { lastVisibleInteractiveElement = dateField } // Якщо всі кнопки дій приховані

        contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalTo(lastVisibleInteractiveElement.snp.bottom).offset(AppConstants.paddingL).priority(.high) 
        }
    }
    
    func setFieldsEditable(_ editable: Bool) {
        let fieldsToToggle: [UITextField] = [nameField, peopleField, locationField, dateField]
        fieldsToToggle.forEach { field in
            field.isEnabled = editable
            if let placeholder = field.placeholder {
                AppAppearance.styleTextFieldForDarkBackground(field, placeholder: placeholder) 
                field.alpha = editable ? 1.0 : 0.7 // Змінюємо прозорість для візуального ефекту
            }
        }
        selectThemeButton.isEnabled = editable
        selectThemeButton.alpha = editable ? 1.0 : 0.7

        descriptionTextView.isEditable = editable
        AppAppearance.styleTextViewForDarkBackground(descriptionTextView) 
        descriptionTextView.alpha = editable ? 1.0 : 0.7
        
        addPhotoButton.isEnabled = editable
        addPhotoButton.alpha = editable ? 1.0 : 0.5
        
        getCurrentLocationButton.isEnabled = editable
        getCurrentLocationButton.alpha = editable ? 1.0 : 0.5
    }

    func updateSuggestionsTableHeight(suggestionCount: Int) {
        let rowHeight: CGFloat = AppConstants.textFieldHeight 
        let maxHeight: CGFloat = rowHeight * 4.5 // Максимум 4.5 рядки
        let newHeight = min(CGFloat(suggestionCount) * rowHeight, maxHeight)
        
        addressSuggestionsTableView.snp.updateConstraints { make in
            make.height.equalTo(newHeight)
        }
        
        let shouldHide = suggestionCount == 0 || newHeight == 0
        addressSuggestionsTableView.isHidden = shouldHide
        
        // Анімація зміни висоти
        UIView.animate(withDuration: AppConstants.defaultAnimationDuration) { 
            self.contentView.layoutIfNeeded() // Або self.layoutIfNeeded(), якщо таблиця поза contentView
        }
    }
}
