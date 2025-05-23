import UIKit
import FirebaseStorage
import FirebaseAuth
import CoreLocation
import MapKit

// MARK: - Контекст перегляду події
enum EventViewContext: Equatable {
    case discover
    case joined
    case created
}

// MARK: - Режим роботи спливаючого вікна
enum PopupMode: Equatable {
    case create
    case view(event: Event, context: EventViewContext)
    case edit(event: Event)
}

// MARK: - Контролер для спливаючого вікна події
class EventPopupViewController: UIViewController {
    
    // MARK: - Properties
    private var popupView: EventPopupView {
        return self.view as! EventPopupView
    }
    
    private let backgroundDimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black // Стандартний колір для затемнення
        view.alpha = 0.0 // Початкова прозорість
        return view
    }()

    var currentMode: PopupMode
    private var eventForPopup: Event?
    private var originalEventDataForEdit: Event? // Для відстеження змін при редагуванні
    
    private var selectedImage: UIImage?
    private var selectedEventDate: Date?
    internal let descriptionPlaceholder = "Розкажіть більше про вашу подію..."
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = AppColors.activityIndicator 
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // Location Services
    private let locationManager = CLLocationManager()
    private var searchCompleter = MKLocalSearchCompleter()
    private var searchResults = [MKLocalSearchCompletion]()
    private var selectedCoordinates: CLLocationCoordinate2D?
    private var isFetchingLocationForButtonTap = false
    private var isSettingTextFromSuggestion = false // Прапорець для уникнення рекурсивного пошуку

    // Themes Selection
    private var selectedEventThemesForPopup: Set<EventTheme> = []
    private let allThemesForPopup = ThemeManager.eventThemes
    private let maxSelectedThemes = 3

    // MARK: - Initialization
    init(mode: PopupMode) {
        self.currentMode = mode
        switch mode {
        case .view(let event, _):
            self.eventForPopup = event
            self.selectedEventDate = event.date
            if let lat = event.latitude, let lon = event.longitude {
                self.selectedCoordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        case .edit(let event):
            self.eventForPopup = event
            self.originalEventDataForEdit = event
            self.selectedEventDate = event.date
            if let lat = event.latitude, let lon = event.longitude {
                self.selectedCoordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        case .create:
            self.eventForPopup = nil
        }

        super.init(nibName: nil, bundle: nil)
        
        // Завантаження тем після super.init
        switch mode {
        case .view(let event, _), .edit(let event):
            if let themeNames = event.themes {
                self.selectedEventThemesForPopup = Set(themeNames.compactMap { name in
                    self.allThemesForPopup.first { $0.name == name }
                })
            }
        case .create:
            self.selectedEventThemesForPopup = []
        }
        self.modalPresentationStyle = .overCurrentContext
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods
    override func loadView() {
        let mainView = EventPopupView()
        mainView.insertSubview(backgroundDimmingView, at: 0)
        backgroundDimmingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundDimmingView.topAnchor.constraint(equalTo: mainView.topAnchor),
            backgroundDimmingView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor),
            backgroundDimmingView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
            backgroundDimmingView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor)
        ])
        mainView.bringSubviewToFront(mainView.popupContainerView) // popupContainer має бути над затемненням
        self.view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDelegates()
        setupDatePicker()
        setupTapGestures()
        setupButtonActions()
        setupActivityIndicator()
        setupLocationServices()
        setupSearchCompleter()
        setupAddressSuggestionsTableView()
        setupThemesSelectionTable()

        if let date = selectedEventDate {
            popupView.datePicker.setDate(date, animated: false)
            updateDateField(with: date)
        } else if case .create = currentMode {
            let defaultDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            selectedEventDate = defaultDate
            popupView.datePicker.setDate(defaultDate, animated: false)
            updateDateField(with: defaultDate)
        }
        
        configureUIForCurrentMode()
        popupView.locationField.addTarget(self, action: #selector(locationFieldDidChange(_:)), for: .editingChanged)
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }

    // MARK: - Setup Methods
    private func setupDelegates() {
        popupView.nameField.delegate = self
        popupView.peopleField.delegate = self
        popupView.descriptionTextView.delegate = self
        popupView.locationField.delegate = self
        popupView.dateField.delegate = self
    }

    private func setupDatePicker() {
        let datePicker = popupView.datePicker
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.datePickerMode = .dateAndTime
        
        if case .create = currentMode {
            datePicker.minimumDate = Date()
        } else if case .edit(let event) = currentMode {
            if event.date > Date() {
                datePicker.minimumDate = Date()
            } else {
                datePicker.minimumDate = nil
            }
        } else {
             datePicker.minimumDate = nil
        }

        let toolbar = UIToolbar(); toolbar.sizeToFit()
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.tintColor = AppColors.accentBlue 

        let doneButton = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(doneDatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Скасувати", style: .plain, target: self, action: #selector(cancelDatePicker))
        toolbar.setItems([cancelButton, spaceButton, doneButton], animated: false)

        popupView.dateField.inputAccessoryView = toolbar
        popupView.dateField.inputView = datePicker
    }
    
    private func setupDescriptionTextViewPlaceholder() {
        let textView = popupView.descriptionTextView
        if textView.text.isEmpty || textView.text == descriptionPlaceholder {
            textView.text = descriptionPlaceholder
            textView.textColor = AppColors.tertiaryText 
        } else {
            textView.textColor = AppColors.primaryText 
        }
    }
    
    private func setupTapGestures() {
        let tapGestureContent = UITapGestureRecognizer(target: self, action: #selector(handleTapOnContent(_:)))
        tapGestureContent.cancelsTouchesInView = false
        tapGestureContent.delegate = self
        tapGestureContent.name = "tapGestureContentOnScrollView"
        popupView.scrollView.addGestureRecognizer(tapGestureContent)

        let tapGestureBackground = UITapGestureRecognizer(target: self, action: #selector(handleTapOnBackground(_:)))
        backgroundDimmingView.addGestureRecognizer(tapGestureBackground)
    }
    
    private func setupActivityIndicator() {
        popupView.popupContainerView.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func setupThemesSelectionTable() {
        popupView.themesSelectionTableView.dataSource = self
        popupView.themesSelectionTableView.delegate = self
        popupView.selectThemeButton.addTarget(self, action: #selector(selectThemeButtonTapped), for: .touchUpInside)
    }

    private func setupLocationServices() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
        let kyivCenter = CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234)
        searchCompleter.region = MKCoordinateRegion(center: kyivCenter, latitudinalMeters: 200000, longitudinalMeters: 200000)
    }
    
    private func setupAddressSuggestionsTableView() {
        popupView.addressSuggestionsTableView.dataSource = self
        popupView.addressSuggestionsTableView.delegate = self
        popupView.addressSuggestionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "suggestionCell")
    }
    
    // MARK: - UI Configuration and Animation
    private func configureUIForCurrentMode() {
        let currentUserID = Auth.auth().currentUser?.uid
        
        popupView.primaryActionButton.isHidden = true
        popupView.actionsStackView.isHidden = true
        popupView.editButton.isHidden = true
        popupView.deleteButton.isHidden = true
        popupView.joinLeaveButton.isHidden = true
        popupView.viewParticipantsButton.isHidden = true
        popupView.rateEventButton.isHidden = true
        popupView.addPhotoButton.isHidden = true
        popupView.getCurrentLocationButton.isHidden = true

        var atLeastOneActionInStackVisible = false

        switch currentMode {
        case .create:
            popupView.headerRibbonLabel.text = "Створення нової події"
            popupView.configureForMode(isCreating: true, event: nil, descriptionPlaceholder: self.descriptionPlaceholder)
            popupView.getCurrentLocationButton.isHidden = false
            setupDescriptionTextViewPlaceholder()
            selectedEventThemesForPopup = []
            popupView.updateSelectThemeButtonAppearance(selectedThemeNames: [])
            
        case .view(let event, _):
            popupView.headerRibbonLabel.text = event.name
            popupView.configureForMode(isCreating: false, event: event, descriptionPlaceholder: self.descriptionPlaceholder)
            popupView.updateSelectThemeButtonAppearance(selectedThemeNames: Array(selectedEventThemesForPopup.map { $0.name }))

            let isEventPast = event.hasEnded
            let isCurrentUserParticipantOrCreator = event.createdBy == currentUserID || (event.participantUIDs?.contains(currentUserID ?? "") ?? false)

            popupView.viewParticipantsButton.isHidden = false; atLeastOneActionInStackVisible = true

            if isEventPast {
                if isCurrentUserParticipantOrCreator {
                    popupView.rateEventButton.isHidden = false; atLeastOneActionInStackVisible = true
                }
            } else {
                if let userID = currentUserID, event.createdBy == userID {
                    popupView.editButton.isHidden = false; atLeastOneActionInStackVisible = true
                    popupView.deleteButton.isHidden = false; atLeastOneActionInStackVisible = true
                } else {
                    configureJoinLeaveButton(for: event, currentUserID: currentUserID)
                    if !popupView.joinLeaveButton.isHidden { atLeastOneActionInStackVisible = true }
                }
            }
            
            if popupView.descriptionTextView.text == self.descriptionPlaceholder || popupView.descriptionTextView.text.isEmpty {
                popupView.descriptionTextView.textColor = AppColors.tertiaryText 
                if popupView.descriptionTextView.text.isEmpty { popupView.descriptionTextView.text = self.descriptionPlaceholder }
            } else {
                popupView.descriptionTextView.textColor = AppColors.primaryText 
            }

        case .edit(let event):
            if event.hasEnded {
                self.currentMode = .view(event: event, context: .created)
                configureUIForCurrentMode()
                showAlert(title: "Подія завершилась", message: "Цю подію вже неможливо редагувати, оскільки вона відбулася.")
                return
            }
            
            popupView.headerRibbonLabel.text = "Редагування: \(event.name)"
            popupView.configureForMode(isCreating: false, event: event, descriptionPlaceholder: self.descriptionPlaceholder)
            AppAppearance.styleButton(popupView.primaryActionButton, title: "Зберегти зміни", backgroundColor: AppColors.warningButtonBackground) 
            popupView.primaryActionButton.isHidden = false
            popupView.addPhotoButton.isHidden = false
            popupView.getCurrentLocationButton.isHidden = false
            popupView.setFieldsEditable(true)
            setupDescriptionTextViewPlaceholder()
            popupView.updateSelectThemeButtonAppearance(selectedThemeNames: Array(selectedEventThemesForPopup.map { $0.name }))

            if let photoURLString = event.photoURL, let url = URL(string: photoURLString) {
               DispatchQueue.global().async {
                   if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                       DispatchQueue.main.async {
                           self.popupView.photoPreview.image = image
                           self.selectedImage = image
                           self.popupView.photoPreview.tintColor = .clear
                       }
                   }
               }
           }
        }
        
        popupView.actionsStackView.isHidden = !atLeastOneActionInStackVisible
        popupView.updateContentViewBottomConstraint()
        DispatchQueue.main.async {
            self.popupView.layoutIfNeeded()
        }
    }
    
    private func configureJoinLeaveButton(for event: Event, currentUserID: String?) {
        var buttonConfig = popupView.joinLeaveButton.configuration ?? UIButton.Configuration.filled()
        var isButtonHidden = false

        if event.date < Date() {
            popupView.joinLeaveButton.isHidden = true
            return
        }

        guard let currentUserID = currentUserID else {
            if (event.participantUIDs?.count ?? 0) >= event.maxPeople {
                buttonConfig.title = "Заповнено"
                buttonConfig.baseBackgroundColor = AppColors.warningButtonBackground 
                popupView.joinLeaveButton.isEnabled = false
                buttonConfig.image = UIImage(systemName: "person.2.slash.fill")
            } else {
                buttonConfig.title = "Приєднатися"
                buttonConfig.baseBackgroundColor = AppColors.actionGreen 
                popupView.joinLeaveButton.isEnabled = true
                buttonConfig.image = UIImage(systemName: "person.crop.circle.badge.plus.fill")
            }
            popupView.joinLeaveButton.configuration = buttonConfig
            popupView.joinLeaveButton.isHidden = isButtonHidden
            return
        }

        if event.createdBy == currentUserID {
            isButtonHidden = true
        } else if event.participantUIDs?.contains(currentUserID) == true {
            buttonConfig.title = "Покинути подію"
            buttonConfig.baseBackgroundColor = AppColors.warningButtonBackground 
            popupView.joinLeaveButton.isEnabled = true
            buttonConfig.image = UIImage(systemName: "person.crop.circle.badge.xmark.fill")
        } else if (event.participantUIDs?.count ?? 0) >= event.maxPeople {
            buttonConfig.title = "Заповнено"
            buttonConfig.baseBackgroundColor = AppColors.secondaryText 
            popupView.joinLeaveButton.isEnabled = false
            buttonConfig.image = UIImage(systemName: "person.2.slash.fill")
        } else {
            buttonConfig.title = "Приєднатися"
            buttonConfig.baseBackgroundColor = AppColors.actionGreen 
            popupView.joinLeaveButton.isEnabled = true
            buttonConfig.image = UIImage(systemName: "person.crop.circle.badge.plus.fill")
        }
        
        popupView.joinLeaveButton.configuration = buttonConfig
        popupView.joinLeaveButton.isHidden = isButtonHidden
    }

    private func animateIn() {
        popupView.popupContainerView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        popupView.popupContainerView.alpha = 0
        self.backgroundDimmingView.alpha = 0

        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.backgroundDimmingView.alpha = 0.6
            self.popupView.popupContainerView.transform = .identity
            self.popupView.popupContainerView.alpha = 1
        })
    }

    @objc private func animateOutAndDismiss() {
        if popupView.isThemesListVisible { hideThemesListForPopup() }
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
            self.backgroundDimmingView.alpha = 0
            self.popupView.popupContainerView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            self.popupView.popupContainerView.alpha = 0
        }) { _ in
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    private func setUIEnabled(_ isEnabled: Bool) {
        if case .view(let event, _) = currentMode, event.date < Date() {
            popupView.closeButton.isEnabled = isEnabled
            popupView.viewParticipantsButton.isEnabled = isEnabled
            popupView.rateEventButton.isEnabled = isEnabled
            
            popupView.primaryActionButton.isEnabled = false
            popupView.addPhotoButton.isEnabled = false
            [popupView.nameField, popupView.selectThemeButton, popupView.peopleField, popupView.locationField, popupView.dateField].forEach { $0.isEnabled = false }
            popupView.descriptionTextView.isEditable = false
            popupView.editButton.isEnabled = false
            popupView.deleteButton.isEnabled = false
            popupView.joinLeaveButton.isEnabled = false
            popupView.getCurrentLocationButton.isEnabled = false
            return
        }

        popupView.primaryActionButton.isEnabled = isEnabled
        popupView.addPhotoButton.isEnabled = isEnabled
        popupView.closeButton.isEnabled = isEnabled
        [popupView.nameField, popupView.selectThemeButton, popupView.peopleField, popupView.locationField, popupView.dateField].forEach { $0.isEnabled = isEnabled }
        popupView.descriptionTextView.isEditable = isEnabled
        
        popupView.editButton.isEnabled = isEnabled
        popupView.deleteButton.isEnabled = isEnabled
        popupView.viewParticipantsButton.isEnabled = isEnabled
        popupView.getCurrentLocationButton.isEnabled = isEnabled
        popupView.rateEventButton.isEnabled = isEnabled

        if !isEnabled {
            popupView.joinLeaveButton.isEnabled = false
        } else {
            if let event = eventForPopup {
                configureJoinLeaveButton(for: event, currentUserID: Auth.auth().currentUser?.uid)
            } else {
                 popupView.joinLeaveButton.isEnabled = false
            }
        }
    }

    // MARK: - Actions
    private func setupButtonActions() {
        popupView.closeButton.addTarget(self, action: #selector(animateOutAndDismiss), for: .touchUpInside)
        popupView.primaryActionButton.addTarget(self, action: #selector(handlePrimaryActionTap), for: .touchUpInside)
        popupView.addPhotoButton.addTarget(self, action: #selector(handleAddPhotoButtonTap), for: .touchUpInside)
        popupView.editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        popupView.deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        popupView.joinLeaveButton.addTarget(self, action: #selector(joinLeaveButtonTapped), for: .touchUpInside)
        popupView.viewParticipantsButton.addTarget(self, action: #selector(viewParticipantsButtonTapped), for: .touchUpInside)
        popupView.getCurrentLocationButton.addTarget(self, action: #selector(getCurrentLocationTapped), for: .touchUpInside)
        popupView.rateEventButton.addTarget(self, action: #selector(rateEventButtonTapped), for: .touchUpInside)
    }
    
    @objc private func doneDatePicker() {
        let newSelectedDate = popupView.datePicker.date
        if (currentMode == .create) || (currentMode != .create && (originalEventDataForEdit?.date ?? Date()) >= Date()) {
            if newSelectedDate < Date() {
                showAlert(title: "Некоректна дата", message: "Дата події не може бути в минулому.")
                popupView.datePicker.setDate(selectedEventDate ?? Date(), animated: true)
                popupView.dateField.resignFirstResponder()
                return
            }
        }
        selectedEventDate = newSelectedDate
        updateDateField(with: selectedEventDate!)
        popupView.dateField.resignFirstResponder()
    }

    @objc private func cancelDatePicker() {
        popupView.dateField.resignFirstResponder()
    }
    
    @objc private func handleTapOnContent(_ gesture: UITapGestureRecognizer) {
        if popupView.isThemesListVisible {
            let locationInThemesTable = gesture.location(in: popupView.themesSelectionTableView)
            if !popupView.themesSelectionTableView.bounds.contains(locationInThemesTable) {
                hideThemesListForPopup()
            }
        }
        if !popupView.addressSuggestionsTableView.isHidden {
            let locationInSuggestionsTable = gesture.location(in: popupView.addressSuggestionsTableView)
            if !popupView.addressSuggestionsTableView.bounds.contains(locationInSuggestionsTable) {
                hideAddressSuggestions()
            }
        }
    }

    @objc private func dismissKeyboardAndSuggestions() {
        popupView.endEditing(true)
        hideAddressSuggestions()
    }

    @objc private func handleTapOnBackground(_ gesture: UITapGestureRecognizer) {
        if popupView.isThemesListVisible { hideThemesListForPopup() }
        if !popupView.addressSuggestionsTableView.isHidden { hideAddressSuggestions() }
        animateOutAndDismiss()
    }

    @objc private func locationFieldDidChange(_ textField: UITextField) {
        guard !isSettingTextFromSuggestion, let query = textField.text, !query.isEmpty else {
            if !isSettingTextFromSuggestion { // Тільки якщо це не програмна зміна
                searchResults = []
                popupView.addressSuggestionsTableView.reloadData()
                popupView.updateSuggestionsTableHeight(suggestionCount: 0)
                selectedCoordinates = nil
            }
            return
        }
        selectedCoordinates = nil
        searchCompleter.queryFragment = query
    }
        
    @objc private func handlePrimaryActionTap() {
        if popupView.isThemesListVisible { hideThemesListForPopup() }
        if !popupView.addressSuggestionsTableView.isHidden { hideAddressSuggestions() }

        if case .create = currentMode, selectedCoordinates == nil {
            showAlert(message: "Будь ласка, виберіть адресу зі списку пропозицій або вкажіть її на карті.")
            return
        }
        if case .edit(let event) = currentMode,
           popupView.locationField.text != event.location,
           selectedCoordinates == nil || (selectedCoordinates?.latitude == event.latitude && selectedCoordinates?.longitude == event.longitude) {
            if let originalEvent = originalEventDataForEdit, popupView.locationField.text != originalEvent.location && selectedCoordinates == nil {
                 showAlert(message: "Якщо ви змінили адресу, будь ласка, виберіть її зі списку пропозицій для оновлення координат, або використайте кнопку геолокації.")
                 return
            }
        }

        switch currentMode {
        case .create:
            handleSaveEvent(isUpdating: false)
        case .edit(let event):
            if event.date < Date() {
                showAlert(title: "Подія завершилась", message: "Неможливо зберегти зміни для події, яка вже відбулася.")
                self.currentMode = .view(event: event, context: .created)
                configureUIForCurrentMode()
                return
            }
            handleSaveEvent(isUpdating: true)
        default:
            break
        }
    }

    @objc private func handleAddPhotoButtonTap() {
        if popupView.isThemesListVisible { hideThemesListForPopup() }
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            showAlert(title: "Помилка", message: "Фотогалерея недоступна.")
            return
        }
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }

    @objc private func editButtonTapped() {
        if popupView.isThemesListVisible { hideThemesListForPopup() }
        guard case .view(let event, _) = currentMode else { return }

        if event.date < Date() {
            showAlert(title: "Подія завершилась", message: "Цю подію вже неможливо редагувати.")
            return
        }

        self.currentMode = .edit(event: event)
        self.originalEventDataForEdit = event
        self.selectedEventDate = event.date
        if let lat = event.latitude, let lon = event.longitude {
            self.selectedCoordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        if let themeNames = event.themes {
            self.selectedEventThemesForPopup = Set(themeNames.compactMap { name in
                allThemesForPopup.first { $0.name == name }
            })
        } else {
            self.selectedEventThemesForPopup = []
        }
        
        popupView.datePicker.setDate(event.date, animated: false)
        updateDateField(with: event.date)
        
        configureUIForCurrentMode()
    }

    @objc private func deleteButtonTapped() {
        if popupView.isThemesListVisible { hideThemesListForPopup() }
        guard let eventToDelete = eventForPopup, let currentUserID = Auth.auth().currentUser?.uid, eventToDelete.createdBy == currentUserID else {
            showAlert(title: "Помилка", message: "Ви не можете видалити цю подію.")
            return
        }

        if eventToDelete.date < Date() {
            showAlert(title: "Подія завершилась", message: "Неможливо видалити подію, яка вже відбулася.")
            return
        }

        let confirmAlert = UIAlertController(title: "Видалити подію?", message: "Ви впевнені, що хочете видалити \"\(eventToDelete.name)\"?", preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: "Так, видалити", style: .destructive, handler: { [weak self] _ in
            self?.activityIndicator.startAnimating()
            FirestoreManager.shared.deleteEvent(eventID: eventToDelete.id) { error in
                self?.activityIndicator.stopAnimating()
                if let error = error {
                    self?.showAlert(title: "Помилка видалення", message: error.localizedDescription)
                } else {
                    NotificationCenter.default.post(name: .didCreateNewEvent, object: nil)
                    self?.animateOutAndDismiss()
                }
            }
        }))
        confirmAlert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(confirmAlert, animated: true)
    }

    @objc private func joinLeaveButtonTapped() {
        if popupView.isThemesListVisible { hideThemesListForPopup() }
        guard let event = eventForPopup else {
            showAlert(title: "Помилка", message: "Подія не завантажена."); return
        }

        if event.date < Date() {
            showAlert(title: "Подія завершилась", message: "Неможливо приєднатися або покинути подію, яка вже відбулася.")
            configureJoinLeaveButton(for: event, currentUserID: Auth.auth().currentUser?.uid)
            return
        }

        guard let currentUserID = Auth.auth().currentUser?.uid else {
             showAlert(title: "Авторизація", message: "Будь ласка, увійдіть в акаунт, щоб взаємодіяти з подіями."); return
        }

        activityIndicator.startAnimating(); setUIEnabled(false)

        let isCurrentlyJoined = event.participantUIDs?.contains(currentUserID) == true

        if isCurrentlyJoined {
            FirestoreManager.shared.unjoinEvent(eventID: event.id, userID: currentUserID) { [weak self] error in
                self?.handleJoinLeaveCompletion(originalEvent: event, error: error, didJoin: false, userID: currentUserID)
            }
        } else {
            if (event.participantUIDs?.count ?? 0) >= event.maxPeople {
                self.activityIndicator.stopAnimating(); self.setUIEnabled(true)
                self.showAlert(title: "Немає місць", message: "На жаль, на цю подію вже немає вільних місць.")
                self.configureJoinLeaveButton(for: event, currentUserID: currentUserID)
                return
            }
            FirestoreManager.shared.joinEvent(eventID: event.id, userID: currentUserID) { [weak self] error in
                self?.handleJoinLeaveCompletion(originalEvent: event, error: error, didJoin: true, userID: currentUserID)
            }
        }
    }
    
    @objc private func viewParticipantsButtonTapped() {
        if popupView.isThemesListVisible { hideThemesListForPopup() }
        guard let event = eventForPopup else { return }
        let participantsVC = EventParticipantsViewController(organizerUID: event.createdBy, participantUIDs: event.participantUIDs ?? [])
        let navController = UINavigationController(rootViewController: participantsVC)
        if #available(iOS 15.0, *) {
            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(navController, animated: true)
    }

    @objc private func rateEventButtonTapped() {
        if popupView.isThemesListVisible { hideThemesListForPopup() }
        guard let event = eventForPopup, let currentUserID = Auth.auth().currentUser?.uid else {
            showAlert(title: "Помилка", message: "Неможливо оцінити подію."); return
        }
        guard event.date < Date() else {
            showAlert(title: "Зарано", message: "Оцінювати подію можна лише після її завершення."); return
        }
        let rateVC = RateParticipantsViewController(event: event, currentUserUID: currentUserID)
        let navController = UINavigationController(rootViewController: rateVC)
        if #available(iOS 15.0, *) {
            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(navController, animated: true, completion: nil)
    }
    
    @objc private func getCurrentLocationTapped() {
        dismissKeyboardAndSuggestions()
        if popupView.isThemesListVisible { hideThemesListForPopup() }

        self.isFetchingLocationForButtonTap = true
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            activityIndicator.startAnimating()
            popupView.getCurrentLocationButton.isEnabled = false
            locationManager.requestLocation()
        case .denied, .restricted:
            showAlert(title: "Доступ заборонено", message: "Будь ласка, надайте доступ до геолокації в налаштуваннях додатку.")
            self.isFetchingLocationForButtonTap = false
        @unknown default:
            self.isFetchingLocationForButtonTap = false
            break
        }
    }

    // MARK: - Helper Methods
    private func updateDateField(with date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM HH:mm"
        formatter.locale = Locale(identifier: "uk_UA")
        popupView.dateField.text = formatter.string(from: date)
    }
    
    private func handleJoinLeaveCompletion(originalEvent: Event, error: Error?, didJoin: Bool, userID: String) {
        activityIndicator.stopAnimating(); setUIEnabled(true)

        if let error = error {
            let action = didJoin ? "приєднатися до" : "покинути"
            showAlert(title: "Помилка", message: "Не вдалося \(action) подію: \(error.localizedDescription)")
        } else {
            var updatedEvent = originalEvent
            if didJoin {
                if updatedEvent.participantUIDs == nil { updatedEvent.participantUIDs = [] }
                if !(updatedEvent.participantUIDs?.contains(userID) ?? false) {
                    updatedEvent.participantUIDs?.append(userID)
                }
            } else {
                updatedEvent.participantUIDs?.removeAll(where: { $0 == userID })
            }
            self.eventForPopup = updatedEvent
            configureJoinLeaveButton(for: updatedEvent, currentUserID: Auth.auth().currentUser?.uid)
            NotificationCenter.default.post(name: .didCreateNewEvent, object: nil)
        }
    }

    private func validateCommonFields() -> (name: String, themes: [String], maxPeople: Int, description: String, eventDate: Date, location: String)? {
        dismissKeyboardAndSuggestions()
        if popupView.isThemesListVisible { hideThemesListForPopup() }

        guard let name = popupView.nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            showAlert(message: "Назва події не може бути порожньою."); return nil
        }
        guard name.count <= 30 else { showAlert(message: "Назва події має містити до 30 символів."); return nil }
        
        guard !selectedEventThemesForPopup.isEmpty else {
            showAlert(message: "Будь ласка, оберіть хоча б одну тему події."); return nil
        }
        guard selectedEventThemesForPopup.count <= maxSelectedThemes else {
            showAlert(message: "Можна обрати не більше \(maxSelectedThemes) тем."); return nil
        }
        let chosenThemeNames = selectedEventThemesForPopup.map { $0.name }
        
        guard let peopleText = popupView.peopleField.text, !peopleText.isEmpty,
              let maxPeople = Int(peopleText), (1...1000).contains(maxPeople) else {
            showAlert(message: "Кількість осіб має бути числом від 1 до 1000."); return nil
        }
        var description = popupView.descriptionTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if popupView.descriptionTextView.textColor == AppColors.tertiaryText && description == descriptionPlaceholder { description = "" } 
        guard description.count <= 200 else { showAlert(message: "Опис події має містити до 200 символів."); return nil }
        
        guard let locationText = popupView.locationField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !locationText.isEmpty else {
            showAlert(message: "Будь ласка, вкажіть адресу події."); return nil
        }
        
        if case .create = currentMode, selectedCoordinates == nil {
            // Дозволяємо продовжити, але handleSaveEvent зробить фінальну перевірку
        }
        
        guard let eventDate = selectedEventDate else {
            showAlert(message: "Будь ласка, оберіть дату та час події."); return nil
        }
        if (currentMode == .create) || (currentMode != .create && (originalEventDataForEdit?.date ?? Date()) >= Date()) {
             if eventDate < Date() {
                 showAlert(message: "Дата події не може бути в минулому."); return nil
             }
        }
        return (name, chosenThemeNames, maxPeople, description, eventDate, locationText)
    }
    
    private func handleSaveEvent(isUpdating: Bool) {
        guard let validatedData = validateCommonFields() else { return }
        
        if selectedCoordinates == nil {
            if isUpdating, let originalEvent = originalEventDataForEdit,
               popupView.locationField.text == originalEvent.location,
               let lat = originalEvent.latitude, let lon = originalEvent.longitude {
                self.selectedCoordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }

        guard let finalCoordinates = selectedCoordinates else {
            showAlert(message: "Будь ласка, виберіть дійсну адресу зі списку пропозицій або використайте кнопку геолокації, щоб визначити координати.")
            return
        }

        activityIndicator.startAnimating(); setUIEnabled(false)
        
        let eventId: String
        let createdByUserID: String
        var existingParticipantUIDs: [String]
        var existingPhotoURL: String?

        if isUpdating, let currentEvent = eventForPopup {
            if currentEvent.date < Date() {
                showAlert(title: "Подія завершилась", message: "Неможливо зберегти зміни для події, яка вже відбулася.")
                activityIndicator.stopAnimating(); setUIEnabled(true)
                self.currentMode = .view(event: currentEvent, context: (currentEvent.createdBy == Auth.auth().currentUser?.uid) ? .created : .discover)
                configureUIForCurrentMode()
                return
            }
            eventId = currentEvent.id
            createdByUserID = currentEvent.createdBy
            existingParticipantUIDs = currentEvent.participantUIDs ?? []
            existingPhotoURL = currentEvent.photoURL
        } else {
            eventId = UUID().uuidString
            guard let newCreatorID = Auth.auth().currentUser?.uid else {
                showAlert(message: "Помилка автентифікації користувача.")
                activityIndicator.stopAnimating(); setUIEnabled(true); return
            }
            createdByUserID = newCreatorID
            existingParticipantUIDs = [newCreatorID]
            existingPhotoURL = nil
        }

        func proceedWithSaving(photoURLString: String?) {
            let eventToSave = Event(
                id: eventId, name: validatedData.name, themes: validatedData.themes,
                description: validatedData.description, location: validatedData.location,
                date: validatedData.eventDate, maxPeople: validatedData.maxPeople,
                createdBy: createdByUserID, photoURL: photoURLString,
                latitude: finalCoordinates.latitude, longitude: finalCoordinates.longitude,
                participantUIDs: existingParticipantUIDs
            )

            let completionHandler: (Error?) -> Void = { [weak self] error in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating(); self.setUIEnabled(true)

                if let error = error {
                    self.showAlert(message: "Не вдалося зберегти подію: \(error.localizedDescription)")
                } else {
                    NotificationCenter.default.post(name: .didCreateNewEvent, object: nil)
                    let message = isUpdating ? "Подію успішно оновлено." : "Подію успішно створено."

                    if isUpdating {
                        self.eventForPopup = eventToSave
                        self.currentMode = .view(event: eventToSave, context: (eventToSave.createdBy == Auth.auth().currentUser?.uid) ? .created : .discover)
                        self.configureUIForCurrentMode()
                        self.showAlert(title: "Успіх!", message: message)
                    } else {
                        self.showAlert(title: "Успіх!", message: message) { self.animateOutAndDismiss() }
                    }
                }
            }

            if isUpdating {
                FirestoreManager.shared.updateEvent(eventToSave, completion: completionHandler)
            } else {
                FirestoreManager.shared.createEvent(eventToSave, completion: completionHandler)
            }
        }

        if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.75) {
            let filename = "event_photos/\(eventId)_\(Date().timeIntervalSince1970).jpg"
            let storageRef = Storage.storage().reference().child(filename)

            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    self.activityIndicator.stopAnimating(); self.setUIEnabled(true)
                    self.showAlert(title: "Помилка завантаження фото", message: error.localizedDescription)
                    return
                }
                storageRef.downloadURL { url, error in
                    if let error = error {
                        self.activityIndicator.stopAnimating(); self.setUIEnabled(true)
                        self.showAlert(title: "Помилка отримання URL фото", message: error.localizedDescription)
                        proceedWithSaving(photoURLString: existingPhotoURL)
                        return
                    }
                    proceedWithSaving(photoURLString: url?.absoluteString)
                }
            }
        } else {
            proceedWithSaving(photoURLString: existingPhotoURL)
        }
    }
            
    private func showAlert(title: String = "Помилка", message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completion?() }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func hideAddressSuggestions() {
        popupView.updateSuggestionsTableHeight(suggestionCount: 0)
    }

    @objc private func selectThemeButtonTapped() {
        popupView.endEditing(true)
        hideAddressSuggestions()

        if popupView.isThemesListVisible {
            hideThemesListForPopup()
        } else {
            showThemesListForPopup()
        }
    }

    private func showThemesListForPopup() {
        guard !popupView.isThemesListVisible else { return }
        popupView.popupContainerView.layoutIfNeeded()
        popupView.isThemesListVisible = true
        popupView.themesSelectionTableView.reloadData()
        popupView.popupContainerView.bringSubviewToFront(popupView.themesSelectionTableView)
        popupView.themesSelectionTableView.isUserInteractionEnabled = true

        let buttonFrameInContainer = popupView.selectThemeButton.convert(popupView.selectThemeButton.bounds, to: popupView.popupContainerView)
        let availableHeightBelowButton = popupView.popupContainerView.bounds.height - buttonFrameInContainer.maxY - AppConstants.paddingM 
        let numberOfRows = CGFloat(allThemesForPopup.count)
        let rowHeight = AppConstants.textFieldHeight 
        let desiredMaxContentHeight = rowHeight * 4.5
        var calculatedTableHeight = min(numberOfRows * rowHeight, desiredMaxContentHeight)
        calculatedTableHeight = min(calculatedTableHeight, availableHeightBelowButton)
        calculatedTableHeight = max(0, calculatedTableHeight)

        let buttonWidth = buttonFrameInContainer.width
        let maxDropdownWidth: CGFloat = 280.0
        let finalTableWidth = min(buttonWidth, maxDropdownWidth)

        popupView.themesSelectionTableView.snp.remakeConstraints { make in
            make.top.equalTo(buttonFrameInContainer.maxY + AppConstants.paddingXS) 
            make.width.equalTo(finalTableWidth)
            make.centerX.equalTo(buttonFrameInContainer.midX)
            make.height.equalTo(calculatedTableHeight)
        }
        popupView.themesSelectionTableView.alpha = 0
        popupView.themesSelectionTableView.isHidden = (calculatedTableHeight <= 0)

        if calculatedTableHeight > 0 {
            UIView.animate(withDuration: AppConstants.defaultAnimationDuration) { 
                self.popupView.themesSelectionTableView.alpha = 1
                self.popupView.popupContainerView.layoutIfNeeded()
            }
        }
    }

    private func hideThemesListForPopup() {
        guard popupView.isThemesListVisible else { return }
        UIView.animate(withDuration: AppConstants.defaultAnimationDuration, animations: { 
            self.popupView.themesSelectionTableView.alpha = 0
        }) { completed in
            if completed {
                self.popupView.themesSelectionTableView.isHidden = true
                self.popupView.isThemesListVisible = false
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension EventPopupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var chosenImage: UIImage?
        if let editedImage = info[.editedImage] as? UIImage {
            chosenImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            chosenImage = originalImage
        }

        if let image = chosenImage {
            selectedImage = image
            popupView.photoPreview.image = image
            popupView.photoPreview.tintColor = .clear
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITextFieldDelegate
extension EventPopupViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

        if textField == popupView.nameField { return updatedText.count <= 30 }
        if textField == popupView.peopleField {
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet) && updatedText.count <= 4
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        hideAddressSuggestions()
        if textField == popupView.nameField { popupView.peopleField.becomeFirstResponder() }
        else if textField == popupView.peopleField { popupView.locationField.becomeFirstResponder() }
        else if textField == popupView.locationField { popupView.descriptionTextView.becomeFirstResponder() }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == popupView.locationField {
            if !searchResults.isEmpty { popupView.updateSuggestionsTableHeight(suggestionCount: searchResults.count) }
        }
        if popupView.isThemesListVisible { hideThemesListForPopup() }
    }
}

// MARK: - UITextViewDelegate
extension EventPopupViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == popupView.descriptionTextView && textView.textColor == AppColors.tertiaryText { 
            textView.text = nil
            textView.textColor = AppColors.primaryText 
        }
        if popupView.isThemesListVisible { hideThemesListForPopup() }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == popupView.descriptionTextView && textView.text.isEmpty {
            setupDescriptionTextViewPlaceholder()
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView == popupView.descriptionTextView {
            let currentText = textView.textColor == AppColors.tertiaryText ? "" : textView.text ?? "" 
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
            return updatedText.count <= 200
        }
        return true
    }
}

// MARK: - CLLocationManagerDelegate
extension EventPopupViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        activityIndicator.stopAnimating()
        popupView.getCurrentLocationButton.isEnabled = true

        guard self.isFetchingLocationForButtonTap, let currentLocation = locations.first else {
            self.isFetchingLocationForButtonTap = false
            return
        }
        self.isFetchingLocationForButtonTap = false
        selectedCoordinates = currentLocation.coordinate

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(currentLocation) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let error = error {
                self.showAlert(message: "Не вдалося отримати адресу: \(error.localizedDescription)")
                if case .create = self.currentMode {
                    self.popupView.locationField.text = String(format: "%.5f, %.5f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
                }
                return
            }

            if let placemark = placemarks?.first {
                var addressString = ""
                if let street = placemark.thoroughfare { addressString += street }
                if let number = placemark.subThoroughfare { addressString += ", \(number)" }
                if let city = placemark.locality { if !addressString.isEmpty { addressString += ", " }; addressString += city }
                else if let administrativeArea = placemark.administrativeArea { if !addressString.isEmpty { addressString += ", " }; addressString += administrativeArea }

                if addressString.isEmpty {
                    if let name = placemark.name, name != addressString { addressString = name }
                    else { addressString = String(format: "%.4f, %.4f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude) }
                }
                
                self.isSettingTextFromSuggestion = true
                self.popupView.locationField.text = addressString
                self.isSettingTextFromSuggestion = false
                
                self.searchResults = []
                self.popupView.addressSuggestionsTableView.reloadData()
                self.popupView.updateSuggestionsTableHeight(suggestionCount: 0)
            } else {
                 if case .create = self.currentMode {
                    self.popupView.locationField.text = String(format: "%.5f, %.5f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude)
                 }
                self.showAlert(message: "Не вдалося знайти детальну адресу для поточного місця.")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        activityIndicator.stopAnimating()
        popupView.getCurrentLocationButton.isEnabled = true
        self.isFetchingLocationForButtonTap = false
        if let clError = error as? CLError, clError.code == .locationUnknown { return }
        showAlert(message: "Не вдалося отримати вашу геолокацію: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            if self.isFetchingLocationForButtonTap {
                activityIndicator.startAnimating()
                popupView.getCurrentLocationButton.isEnabled = false
                locationManager.requestLocation()
            }
        } else if status == .denied || status == .restricted {
            if self.isFetchingLocationForButtonTap {
                activityIndicator.stopAnimating()
                popupView.getCurrentLocationButton.isEnabled = true
                self.isFetchingLocationForButtonTap = false
                showAlert(title: "Доступ заборонено", message: "Будь ласка, надайте доступ до геолокації в налаштуваннях.")
            }
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension EventPopupViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results.filter { !$0.title.isEmpty }
        popupView.addressSuggestionsTableView.reloadData()
        popupView.updateSuggestionsTableHeight(suggestionCount: searchResults.count)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        searchResults = []
        popupView.addressSuggestionsTableView.reloadData()
        popupView.updateSuggestionsTableHeight(suggestionCount: 0)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate (For Themes and Address Suggestions)
extension EventPopupViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == popupView.themesSelectionTableView { return allThemesForPopup.count }
        return searchResults.count // For addressSuggestionsTableView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == popupView.themesSelectionTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PopupThemeCell", for: indexPath)
            let theme = allThemesForPopup[indexPath.row]
            cell.textLabel?.text = theme.displayName
            cell.textLabel?.font = AppFonts.regular(size: 15) 
            cell.textLabel?.textColor = AppColors.primaryText 
            cell.backgroundColor = .clear
            cell.tintColor = AppColors.accentYellow 
            cell.accessoryType = selectedEventThemesForPopup.contains(theme) ? .checkmark : .none
            let selectionView = UIView(); selectionView.backgroundColor = AppColors.accentYellow.withAlphaComponent(0.3); cell.selectedBackgroundView = selectionView 
            return cell
        }
        
        // For addressSuggestionsTableView
        let cell = tableView.dequeueReusableCell(withIdentifier: "suggestionCell", for: indexPath)
        let suggestion = searchResults[indexPath.row]
        cell.textLabel?.text = suggestion.title
        cell.textLabel?.textColor = AppColors.primaryText 
        cell.textLabel?.font = AppFonts.regular(size: 14) 
        cell.backgroundColor = .clear
        let selectionView = UIView(); selectionView.backgroundColor = AppColors.darkSubtleBackground; cell.selectedBackgroundView = selectionView 
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == popupView.themesSelectionTableView {
            tableView.deselectRow(at: indexPath, animated: true)
            let theme = allThemesForPopup[indexPath.row]
            if selectedEventThemesForPopup.contains(theme) {
                selectedEventThemesForPopup.remove(theme)
            } else {
                if selectedEventThemesForPopup.count < maxSelectedThemes {
                    selectedEventThemesForPopup.insert(theme)
                } else {
                    showAlert(title: "Ліміт тем", message: "Ви можете обрати до \(maxSelectedThemes) тем.")
                }
            }
            tableView.reloadData()
            popupView.updateSelectThemeButtonAppearance(selectedThemeNames: Array(selectedEventThemesForPopup.map { $0.name }))
            if selectedEventThemesForPopup.count == maxSelectedThemes { hideThemesListForPopup() }
        } else if tableView == popupView.addressSuggestionsTableView {
            tableView.deselectRow(at: indexPath, animated: true)
            guard indexPath.row < searchResults.count else { return }

            let selectedSuggestion = searchResults[indexPath.row]
            let newAddressText = selectedSuggestion.title
            popupView.locationField.resignFirstResponder()
            self.isSettingTextFromSuggestion = true
            popupView.locationField.text = newAddressText
            self.isSettingTextFromSuggestion = false
            hideAddressSuggestions()

            let searchRequest = MKLocalSearch.Request(completion: selectedSuggestion)
            let search = MKLocalSearch(request: searchRequest)
            activityIndicator.startAnimating(); setUIEnabled(false)

            search.start { [weak self] (response, error) in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating(); self.setUIEnabled(true)
                if let error = error {
                    self.showAlert(message: "Не вдалося отримати координати для адреси '\(newAddressText)': \(error.localizedDescription)")
                    self.selectedCoordinates = nil
                    return
                }
                if let mapItem = response?.mapItems.first {
                    self.selectedCoordinates = mapItem.placemark.coordinate
                } else {
                    self.showAlert(message: "Не вдалося знайти точні координати для вибраної адреси: '\(newAddressText)'.")
                    self.selectedCoordinates = nil
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AppConstants.textFieldHeight 
    }
}

// MARK: - UIGestureRecognizerDelegate
extension EventPopupViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.name == "tapGestureContentOnScrollView" {
            if let touchedView = touch.view {
                if touchedView.isDescendant(of: popupView.themesSelectionTableView) ||
                   touchedView.isDescendant(of: popupView.addressSuggestionsTableView) ||
                   touchedView.isDescendant(of: popupView.datePicker) {
                    return false
                }
            }
        }
        return true
    }
}
