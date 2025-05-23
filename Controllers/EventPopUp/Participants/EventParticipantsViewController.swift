import UIKit
import FirebaseFirestore
import SnapKit

// MARK: - Контролер для відображення учасників події
class EventParticipantsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - UI Properties
    private let tableView = UITableView()
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        AppAppearance.styleActivityIndicator(indicator) 
        indicator.hidesWhenStopped = true
        return indicator
    }()
    private var emptyStateLabel: UILabel?

    // MARK: - Data Properties
    private var organizerUID: String?
    private var participantUIDs: [String] = []
    private var organizerProfile: UserProfile?
    private var participantProfiles: [UserProfile] = []

    // MARK: - Initialization
    init(organizerUID: String?, participantUIDs: [String]) {
        self.organizerUID = organizerUID
        self.participantUIDs = participantUIDs.filter { $0 != organizerUID } // Виключаємо організатора зі списку учасників
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        AppAppearance.applyPrimaryBackground(to: view) 
        title = "Учасники Події"
        
        setupNavigationThemed()
        setupTableView()
        setupActivityIndicatorLayout()

        if organizerUID == nil && participantUIDs.isEmpty {
            ensureEmptyStateLabelIsVisible(true, text: "Ще ніхто не приєднався")
            updateTitleCount()
        } else {
            loadAllProfiles()
        }
    }

    // MARK: - Setup Methods
    private func setupNavigationThemed() {
        AppAppearance.setupStandardNavigationBar(navigationController) 
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
    }
    
    private func setupActivityIndicatorLayout() {
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ParticipantTableViewCell.self, forCellReuseIdentifier: "ParticipantCell")
        tableView.backgroundColor = .clear // Theme consistent
        tableView.tableFooterView = UIView() // Прибирає зайві розділювачі
        tableView.separatorStyle = .none // Прибирає розділювачі між комірками

        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    // MARK: - Data Loading
    private func loadAllProfiles() {
        activityIndicator.startAnimating()
        ensureEmptyStateLabelIsVisible(false)

        let group = DispatchGroup()
        var tempOrganizerProfile: UserProfile?
        var tempParticipantProfiles: [UserProfile] = Array(repeating: UserProfile(), count: participantUIDs.count)
        var fetchErrors: [Error] = []

        if let orgUID = organizerUID {
            group.enter()
            FirestoreManager.shared.fetchUserProfile(userID: orgUID) { result in
                defer { group.leave() }
                switch result {
                case .success(var profile):
                    profile.uid = orgUID
                    tempOrganizerProfile = profile
                case .failure(_):
                    fetchErrors.append(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch organizer"]))
                    tempOrganizerProfile = UserProfile(uid: orgUID, firstName: "Організатор", lastName: "(недоступний)")
                }
            }
        }

        for (index, uid) in participantUIDs.enumerated() {
            group.enter()
            FirestoreManager.shared.fetchUserProfile(userID: uid) { result in
                defer { group.leave() }
                switch result {
                case .success(var profile):
                    profile.uid = uid
                    tempParticipantProfiles[index] = profile
                case .failure(_):
                    fetchErrors.append(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch participant \(uid)"]))
                    tempParticipantProfiles[index] = UserProfile(uid: uid, firstName: "Учасник", lastName: uid.prefix(6) + "...")
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()

            self.organizerProfile = tempOrganizerProfile
            self.participantProfiles = tempParticipantProfiles.filter { $0.uid != nil }
                                                            .sorted { ($0.firstName ?? "Z") < ($1.firstName ?? "Z") }

            self.updateTitleCount()

            if self.organizerProfile == nil && self.participantProfiles.isEmpty {
                self.ensureEmptyStateLabelIsVisible(true, text: fetchErrors.isEmpty ? "Ще ніхто не приєднався" : "Не вдалося завантажити частину даних.")
            } else {
                self.ensureEmptyStateLabelIsVisible(false)
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - UI Update Methods
    private func updateTitleCount() {
        let organizerCount = (organizerProfile != nil ? 1 : 0)
        let participantsCount = participantProfiles.count
        let totalCount = organizerCount + participantsCount
        title = "Учасники Події (\(totalCount))"
    }

    private func ensureEmptyStateLabelIsVisible(_ visible: Bool, text: String = "Ще ніхто не приєднався") {
        if visible {
            if emptyStateLabel == nil {
                let label = UILabel()
                AppAppearance.styleEmptyStateLabel(label, text: text) 
                view.addSubview(label)
                label.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    make.leading.trailing.equalToSuperview().inset(AppConstants.paddingXL) 
                }
                emptyStateLabel = label
            }
            emptyStateLabel?.isHidden = false
            emptyStateLabel?.text = text
            tableView.isHidden = true
        } else {
            emptyStateLabel?.isHidden = true
            tableView.isHidden = false
        }
    }

    // MARK: - Actions
    @objc private func doneButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Секція для організатора та секція для учасників
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { // Організатор
            return organizerProfile != nil ? 1 : 0
        } else { // Учасники
            return participantProfiles.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantCell", for: indexPath) as? ParticipantTableViewCell else {
            return UITableViewCell()
        }
        
        var userToDisplay: UserProfile?

        if indexPath.section == 0 {
            userToDisplay = organizerProfile
        } else {
            if indexPath.row < participantProfiles.count {
                userToDisplay = participantProfiles[indexPath.row]
            }
        }
        
        if let user = userToDisplay {
            cell.configure(with: user)
        } else {
             // Запасний варіант, якщо дані користувача не вдалося отримати
             cell.nameLabel.text = "Дані користувача недоступні"
             cell.profileImageView.image = UIImage(systemName: "person.crop.circle.badge.exclamationmark.fill")?.withTintColor(AppColors.secondaryText, renderingMode: .alwaysOriginal) 
        }
        
        cell.backgroundColor = .clear // Theme consistent
        cell.selectionStyle = .default
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return organizerProfile != nil ? "Організатор" : nil
        } else {
            return !participantProfiles.isEmpty ? "Учасники" : nil
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            AppAppearance.styleTableViewHeader(headerView) 
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Приховуємо заголовок, якщо секція порожня
        if section == 0 && organizerProfile == nil { return CGFloat.leastNormalMagnitude }
        if section == 1 && participantProfiles.isEmpty { return CGFloat.leastNormalMagnitude }
        return 35 // Стандартна висота заголовка
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60 // Стандартна висота комірки
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var selectedProfile: UserProfile?
        if indexPath.section == 0 {
            selectedProfile = organizerProfile
        } else if indexPath.row < participantProfiles.count {
            selectedProfile = participantProfiles[indexPath.row]
        }

        guard let profile = selectedProfile, let userId = profile.uid else {
            let alert = UIAlertController(title: "Помилка", message: "Не вдалося завантажити дані цього користувача.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let userProfilePopupVC = UserProfilePopupViewController(userID: userId)
        let navController = UINavigationController(rootViewController: userProfilePopupVC)
        AppAppearance.setupStandardNavigationBar(navController) 
        
        if #available(iOS 15.0, *) {
            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(navController, animated: true)
    }
}
