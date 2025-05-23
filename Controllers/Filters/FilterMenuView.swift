import UIKit
import SnapKit

// MARK: - Data Structure for Filter State
struct FilterState: Codable, Equatable {
    var startDate: Date?
    var endDate: Date?
    var peopleCount: Float?
    var selectedThemeNames: [String]?

    static func == (lhs: FilterState, rhs: FilterState) -> Bool {
        return lhs.startDate == rhs.startDate &&
               lhs.endDate == rhs.endDate &&
               lhs.peopleCount == rhs.peopleCount &&
               lhs.selectedThemeNames == rhs.selectedThemeNames
    }
}

// MARK: - View for Filters Menu
class FiltersMenuView: UIView {

    // MARK: - UI Elements - Header
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Фільтри"
        label.font = AppFonts.drawerTitle 
        label.textColor = AppColors.primaryText 
        label.textAlignment = .center
        return label
    }()

    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        if let closeImage = UIImage(systemName: "xmark.circle.fill") {
            button.setImage(closeImage, for: .normal)
        } else {
            button.setTitle("X", for: .normal)
        }
        button.tintColor = AppColors.primaryText 
        return button
    }()
    
    // MARK: - UI Elements - Content
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        return view
    }()

    // MARK: - UI Elements - Date Section
    private let dateSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Період проведення події"
        label.font = AppFonts.semibold(size: 16) 
        label.textColor = AppColors.primaryText 
        return label
    }()

    let startDateTextField: UITextField = {
        let textField = UITextField()
        return textField
    }()

    let endDateTextField: UITextField = {
        let textField = UITextField()
        return textField
    }()
    
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()

    // MARK: - UI Elements - People Count Section
    private let peopleCountSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Кількість людей"
        label.font = AppFonts.semibold(size: 16) 
        label.textColor = AppColors.primaryText 
        return label
    }()

    let peopleCountSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 1
        slider.maximumValue = 1000
        slider.tintColor = AppColors.accentYellow 
        slider.thumbTintColor = AppColors.accentYellow 
        return slider
    }()

    let peopleCountValueLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.regular(size: 15) 
        label.textColor = AppColors.secondaryText 
        label.textAlignment = .right
        return label
    }()

    // MARK: - UI Elements - Theme Section
    private let themeSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Теми подій"
        label.font = AppFonts.semibold(size: 16) 
        label.textColor = AppColors.primaryText 
        return label
    }()

    let selectThemeButton: UIButton = {
        let button = UIButton(type: .system)
        return button
    }()
    
    let selectedThemesLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.regular(size: 14) 
        label.textColor = AppColors.secondaryText 
        label.numberOfLines = 0
        return label
    }()

    let themesTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = AppColors.primaryDeepRed.withAlphaComponent(0.9) 
        tableView.layer.borderColor = AppColors.primaryText.withAlphaComponent(0.5).cgColor 
        tableView.layer.borderWidth = AppConstants.borderWidth 
        tableView.layer.cornerRadius = AppConstants.cornerRadiusM 
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ThemeCell")
        tableView.allowsMultipleSelection = true
        tableView.clipsToBounds = true
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = AppColors.primaryText.withAlphaComponent(0.3) 
        return tableView
    }()
    
    var themesTableViewIsVisible: Bool = false
    
    // MARK: - Data Properties
    private let allThemes = ThemeManager.eventThemes
    var selectedThemes: Set<EventTheme> = []

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        AppAppearance.applyPrimaryBackground(to: self) 
        self.clipsToBounds = false
        
        setupViewLayout()
        setupDatePickers()
        setupActions()
        
        configure(with: nil)

        themesTableView.delegate = self
        themesTableView.dataSource = self
        themesTableView.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Hit Testing for Overlapping Views
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !themesTableView.isHidden && themesTableView.alpha > 0 && themesTableViewIsVisible {
            let pointInTableView = convert(point, to: themesTableView)
            if themesTableView.bounds.contains(pointInTableView) {
                return themesTableView.hitTest(pointInTableView, with: event)
            }
        }
        return super.hitTest(point, with: event)
    }

    // MARK: - Setup Methods
    private func setupViewLayout() {
        layer.cornerRadius = AppConstants.cornerRadiusL 
        layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        addSubview(titleLabel)
        addSubview(closeButton)

        contentView.addSubview(dateSectionLabel)
        contentView.addSubview(startDateTextField)
        contentView.addSubview(endDateTextField)
        contentView.addSubview(peopleCountSectionLabel)
        contentView.addSubview(peopleCountSlider)
        contentView.addSubview(peopleCountValueLabel)
        contentView.addSubview(themeSectionLabel)
        contentView.addSubview(selectThemeButton)
        contentView.addSubview(selectedThemesLabel)

        AppAppearance.styleTextFieldForDarkBackground(startDateTextField, placeholder: "Дата початку") 
        AppAppearance.styleTextFieldForDarkBackground(endDateTextField, placeholder: "Дата завершення") 
        
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.attributedTitle = AttributedString("Обрати теми...", attributes: AttributeContainer([
            .font: AppFonts.regular(size: 15), 
            .foregroundColor: AppColors.placeholderText 
        ]))
        buttonConfig.background.backgroundColor = AppColors.textFieldBackgroundDark 
        buttonConfig.background.cornerRadius = AppConstants.cornerRadiusM 
        buttonConfig.background.strokeColor = AppColors.textFieldBorderDark 
        buttonConfig.background.strokeWidth = AppConstants.borderWidth 
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: AppConstants.paddingM, bottom: 10, trailing: AppConstants.paddingM) 
        selectThemeButton.configuration = buttonConfig
        selectThemeButton.contentHorizontalAlignment = .left

        // --- Constraints ---
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppConstants.paddingL) 
            make.trailing.equalToSuperview().inset(AppConstants.paddingL) 
            make.width.height.equalTo(30)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton.snp.centerY)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualTo(closeButton.snp.trailing).offset(AppConstants.paddingS) 
        }
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppConstants.paddingM) 
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.snp.edges)
            make.width.equalTo(scrollView.snp.width)
        }
        dateSectionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppConstants.paddingM) 
            make.leading.equalToSuperview().offset(AppConstants.paddingL) 
            make.trailing.equalToSuperview().inset(AppConstants.paddingL) 
        }
        startDateTextField.snp.makeConstraints { make in
            make.top.equalTo(dateSectionLabel.snp.bottom).offset(AppConstants.paddingS) 
            make.leading.equalTo(dateSectionLabel)
            make.trailing.equalTo(contentView.snp.centerX).inset(AppConstants.paddingXS) 
            make.height.equalTo(AppConstants.textFieldHeight) 
        }
        endDateTextField.snp.makeConstraints { make in
            make.top.equalTo(startDateTextField)
            make.leading.equalTo(contentView.snp.centerX).offset(AppConstants.paddingXS) 
            make.trailing.equalTo(dateSectionLabel)
            make.height.equalTo(AppConstants.textFieldHeight) 
        }
        peopleCountSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(startDateTextField.snp.bottom).offset(AppConstants.paddingL) 
            make.leading.trailing.equalTo(dateSectionLabel)
        }
        peopleCountValueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(dateSectionLabel)
            make.centerY.equalTo(peopleCountSlider)
            make.width.equalTo(50)
        }
        peopleCountSlider.snp.makeConstraints { make in
            make.top.equalTo(peopleCountSectionLabel.snp.bottom).offset(AppConstants.paddingS) 
            make.leading.equalTo(dateSectionLabel)
            make.trailing.equalTo(peopleCountValueLabel.snp.leading).inset(-AppConstants.paddingS) 
            make.height.equalTo(30)
        }
        themeSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(peopleCountSlider.snp.bottom).offset(AppConstants.paddingL) 
            make.leading.trailing.equalTo(dateSectionLabel)
        }
        selectThemeButton.snp.makeConstraints { make in
            make.top.equalTo(themeSectionLabel.snp.bottom).offset(AppConstants.paddingS) 
            make.leading.trailing.equalTo(dateSectionLabel)
            make.height.equalTo(AppConstants.textFieldHeight) 
        }
        selectedThemesLabel.snp.makeConstraints { make in
            make.top.equalTo(selectThemeButton.snp.bottom).offset(AppConstants.paddingS) 
            make.leading.trailing.equalTo(dateSectionLabel)
            make.bottom.equalToSuperview().inset(AppConstants.paddingL)
        }
    }

    private func setupDatePickers() {
        configureDatePicker(startDatePicker, for: startDateTextField, action: #selector(startDateChanged))
        configureDatePicker(endDatePicker, for: endDateTextField, action: #selector(endDateChanged))

        let toolbar = UIToolbar(); toolbar.sizeToFit()
        toolbar.barStyle = .default
        toolbar.tintColor = AppColors.accentBlue 
        toolbar.isTranslucent = true

        let doneButton = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(dismissDatePicker))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)

        startDateTextField.inputAccessoryView = toolbar
        endDateTextField.inputAccessoryView = toolbar
    }

    private func configureDatePicker(_ datePicker: UIDatePicker, for textField: UITextField, action: Selector) {
        datePicker.datePickerMode = .date
        if #available(iOS 13.4, *) { datePicker.preferredDatePickerStyle = .wheels }
        datePicker.tintColor = AppColors.accentBlue 
        datePicker.setValue(AppColors.primaryText, forKeyPath: "textColor") 
        datePicker.addTarget(self, action: action, for: .valueChanged)
        textField.inputView = datePicker
    }

    private func setupActions() {
        peopleCountSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        selectThemeButton.addTarget(self, action: #selector(toggleThemesList), for: .touchUpInside)
    }
    
    // MARK: - Actions and Event Handlers
    enum DatePickerType { case start, end }
    
    @objc private func startDateChanged() {
        updateTextField(startDateTextField, with: startDatePicker.date, forPicker: .start)
        if let startDate = getCurrentFilterState().startDate {
            endDatePicker.minimumDate = startDate
            if let currentEndDate = getCurrentFilterState().endDate, currentEndDate < startDate {
                endDatePicker.date = startDate
                updateTextField(endDateTextField, with: startDate, forPicker: .end)
            }
        }
    }

    @objc private func endDateChanged() {
        updateTextField(endDateTextField, with: endDatePicker.date, forPicker: .end)
        if let endDate = getCurrentFilterState().endDate {
            startDatePicker.maximumDate = endDate
            if let currentStartDate = getCurrentFilterState().startDate, currentStartDate > endDate {
                startDatePicker.date = endDate
                updateTextField(startDateTextField, with: endDate, forPicker: .start)
            }
        }
    }
    
    @objc private func dismissDatePicker() {
        if startDateTextField.isFirstResponder {
            startDateChanged()
        } else if endDateTextField.isFirstResponder {
            endDateChanged()
        }
        endEditing(true)
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        updatePeopleCountLabel(value: sender.value)
    }
    
    @objc private func toggleThemesList() {
        if themesTableViewIsVisible {
            hideThemesList()
        } else {
            showThemesList()
        }
    }

    // MARK: - UI Update Methods
    private func updateTextField(_ textField: UITextField, with date: Date?, forPicker type: DatePickerType) {
        guard let date = date else {
            textField.text = nil
            if type == .start { endDatePicker.minimumDate = nil }
            else { startDatePicker.maximumDate = nil }
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        textField.text = dateFormatter.string(from: date)
    }
    
    private func updatePeopleCountLabel(value: Float) {
        peopleCountValueLabel.text = "\(Int(value))"
    }
    
    private func updateSelectedThemesLabel() {
        var configToUpdate: UIButton.Configuration
        if let existingConfig = selectThemeButton.configuration {
            configToUpdate = existingConfig
        } else {
            configToUpdate = UIButton.Configuration.plain()
            configToUpdate.background.backgroundColor = AppColors.textFieldBackgroundDark 
            configToUpdate.background.cornerRadius = AppConstants.cornerRadiusM 
            configToUpdate.background.strokeColor = AppColors.textFieldBorderDark 
            configToUpdate.background.strokeWidth = AppConstants.borderWidth 
            configToUpdate.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: AppConstants.paddingM, bottom: 10, trailing: AppConstants.paddingM) 
        }

        if selectedThemes.isEmpty {
            selectedThemesLabel.text = "Теми не обрано"
            selectedThemesLabel.textColor = AppColors.secondaryText 
            
            configToUpdate.attributedTitle = AttributedString("Обрати теми...", attributes: AttributeContainer([
                .font: AppFonts.regular(size: 15), 
                .foregroundColor: AppColors.placeholderText 
            ]))
        } else {
            let themesText = selectedThemes.map { $0.name }.joined(separator: ", ")
            selectedThemesLabel.text = "Обрано: \(themesText)"
            selectedThemesLabel.textColor = AppColors.primaryText 
            
            let buttonTitle = themesText.count > 30 ? "Обрано (\(selectedThemes.count))" : themesText
            configToUpdate.attributedTitle = AttributedString(buttonTitle, attributes: AttributeContainer([
                .font: AppFonts.regular(size: 15), 
                .foregroundColor: AppColors.primaryText 
            ]))
        }
        selectThemeButton.configuration = configToUpdate
        selectThemeButton.contentHorizontalAlignment = .left
    }
    
    // MARK: - Themes List Show/Hide
    private func showThemesList() {
        guard !themesTableViewIsVisible else { return }
        themesTableViewIsVisible = true
        
        if themesTableView.superview == nil {
            self.addSubview(themesTableView)
        }
        themesTableView.reloadData()
        
        self.bringSubviewToFront(themesTableView)
        themesTableView.isUserInteractionEnabled = true

        let buttonFrameInSelf = selectThemeButton.convert(selectThemeButton.bounds, to: self)
        let count = CGFloat(allThemes.count)
        let rowHeight = AppConstants.textFieldHeight 
        let tableMaxHeight = rowHeight * 7.5
        let tableHeight = min(count * rowHeight, tableMaxHeight)

        themesTableView.snp.remakeConstraints { make in
            make.top.equalTo(buttonFrameInSelf.maxY + AppConstants.paddingXS) 
            make.leading.equalTo(selectThemeButton.snp.leading)
            make.trailing.equalTo(selectThemeButton.snp.trailing)
            make.height.equalTo(tableHeight)
        }
        
        themesTableView.alpha = 0
        themesTableView.isHidden = false

        UIView.animate(withDuration: AppConstants.defaultAnimationDuration, animations: { 
            self.themesTableView.alpha = 1
        })
    }

    @objc func hideThemesList() {
        guard themesTableViewIsVisible else { return }
        
        UIView.animate(withDuration: AppConstants.defaultAnimationDuration, animations: { 
            self.themesTableView.alpha = 0
        }) { completed in
            if completed {
                self.themesTableView.isHidden = true
                self.themesTableViewIsVisible = false
            }
        }
    }
    
    // MARK: - Public Configuration
    func configure(with filters: FilterState?) {
        if let startDate = filters?.startDate {
            startDatePicker.date = startDate
            updateTextField(startDateTextField, with: startDate, forPicker: .start)
        } else {
            startDatePicker.date = Date()
            updateTextField(startDateTextField, with: nil, forPicker: .start)
        }
        
        if let endDate = filters?.endDate {
            endDatePicker.date = endDate
            updateTextField(endDateTextField, with: endDate, forPicker: .end)
        } else {
            endDatePicker.date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            updateTextField(endDateTextField, with: nil, forPicker: .end)
        }
        
        // Update picker limits based on current dates
        if let currentStartDate = getCurrentFilterState().startDate {
            endDatePicker.minimumDate = currentStartDate
        } else { endDatePicker.minimumDate = nil }
        if let currentEndDate = getCurrentFilterState().endDate {
            startDatePicker.maximumDate = currentEndDate
        } else { startDatePicker.maximumDate = nil }

        // People count
        let peopleCount = filters?.peopleCount ?? 1000.0
        peopleCountSlider.setValue(peopleCount, animated: false)
        updatePeopleCountLabel(value: peopleCount)

        // Themes
        selectedThemes.removeAll()
        if let themeNames = filters?.selectedThemeNames {
            for name in themeNames {
                if let themeObject = allThemes.first(where: { $0.name == name }) {
                    selectedThemes.insert(themeObject)
                }
            }
        }
        updateSelectedThemesLabel()
        if themesTableView.superview != nil {
             themesTableView.reloadData()
        }
    }

    func getCurrentFilterState() -> FilterState {
        let finalStartDate = startDateTextField.text?.isEmpty ?? true ? nil : startDatePicker.date
        let finalEndDate = endDateTextField.text?.isEmpty ?? true ? nil : endDatePicker.date
        let themeNames = selectedThemes.map { $0.name }
        
        return FilterState(
            startDate: finalStartDate,
            endDate: finalEndDate,
            peopleCount: peopleCountSlider.value,
            selectedThemeNames: themeNames.isEmpty ? nil : themeNames
        )
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource for Themes
extension FiltersMenuView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return allThemes.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ThemeCell", for: indexPath)
        let theme = allThemes[indexPath.row]
        cell.textLabel?.text = theme.displayName
        cell.textLabel?.font = AppFonts.regular(size: 15) 
        cell.textLabel?.textColor = AppColors.primaryText 
        cell.backgroundColor = .clear
        cell.tintColor = AppColors.accentYellow
        
        let selectionView = UIView()
        selectionView.backgroundColor = AppColors.accentYellow.withAlphaComponent(0.3) 
        cell.selectedBackgroundView = selectionView
        
        cell.accessoryType = selectedThemes.contains(theme) ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let theme = allThemes[indexPath.row]
        if selectedThemes.contains(theme) {
            selectedThemes.remove(theme)
        } else {
            selectedThemes.insert(theme)
        }
        tableView.reloadRows(at: [indexPath], with: .none) 
        updateSelectedThemesLabel()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AppConstants.textFieldHeight 
    }
}
