import UIKit
import FirebaseAuth
import SnapKit

// MARK: - View Controller for Rating Event Participants
class RateParticipantsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Data Properties
    private let event: Event
    private let currentUserUID: String
    private var usersToRate: [UserProfile] = []
    private var ratedUsers: [String: Int] = [:] // [userID: rating]

    // MARK: - UI Properties
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        AppAppearance.applyPrimaryBackground(to: tv)
        tv.register(RatingTableViewCell.self, forCellReuseIdentifier: RatingTableViewCell.identifier)
        tv.separatorStyle = .none
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 80
        tv.allowsSelection = false
        return tv
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        AppAppearance.styleActivityIndicator(indicator) 
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var saveRatingsButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "Зберегти", style: .done, target: self, action: #selector(saveRatingsTapped))
    }()
    
    private var emptyStateLabel: UILabel?

    // MARK: - Initialization
    init(event: Event, currentUserUID: String) {
        self.event = event
        self.currentUserUID = currentUserUID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        AppAppearance.applyPrimaryBackground(to: view) 
        title = "Оцінити: \(event.name)"
        
        setupNavigation()
        setupLayout()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        loadParticipantsToRate()
    }

    // MARK: - Setup Methods
    private func setupNavigation() {
        AppAppearance.setupStandardNavigationBar(navigationController) 
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = saveRatingsButton
        saveRatingsButton.isEnabled = false
    }

    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    // MARK: - Data Loading and State Management
    private func loadParticipantsToRate() {
        activityIndicator.startAnimating()
        tableView.isHidden = true
        ensureEmptyStateLabelIsVisible(false)

        loadPreviouslyGivenRatings { [weak self] previouslyGivenRatings in
            guard let self = self else { return }
            self.ratedUsers = previouslyGivenRatings

            var uidsToFetchDetailsFor: Set<String> = []
            
            if self.event.createdBy != self.currentUserUID {
                uidsToFetchDetailsFor.insert(self.event.createdBy)
            }
            
            if let allParticipantUIDs = self.event.participantUIDs {
                for uid in allParticipantUIDs {
                    if uid != self.currentUserUID && uid != self.event.createdBy {
                        uidsToFetchDetailsFor.insert(uid)
                    }
                }
            }

            guard !uidsToFetchDetailsFor.isEmpty else {
                self.activityIndicator.stopAnimating()
                self.ensureEmptyStateLabelIsVisible(true, text: "Немає нових учасників для оцінювання.")
                self.saveRatingsButton.isEnabled = false
                return
            }
            
            var fetchedProfiles: [UserProfile] = []
            let group = DispatchGroup()

            for uid in uidsToFetchDetailsFor {
                group.enter()
                FirestoreManager.shared.fetchUserProfile(userID: uid) { result in
                    switch result {
                    case .success(var profile):
                        if profile.uid == nil { profile.uid = uid }
                        fetchedProfiles.append(profile)
                    case .failure(_):
                        let placeholderProfile = UserProfile(uid: uid, firstName: "Користувач", lastName: String(uid.prefix(6)) + "...")
                        fetchedProfiles.append(placeholderProfile)
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) { [weak self] in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                
                var organizerProfile: UserProfile?
                var otherParticipants: [UserProfile] = []

                for profile in fetchedProfiles {
                    if profile.uid == self.event.createdBy {
                        organizerProfile = profile
                    } else {
                        otherParticipants.append(profile)
                    }
                }
                
                self.usersToRate.removeAll()
                if let org = organizerProfile { self.usersToRate.append(org) }
                self.usersToRate.append(contentsOf: otherParticipants.sorted(by: {
                    ($0.firstName ?? "").lowercased() < ($1.firstName ?? "").lowercased()
                }))

                if self.usersToRate.isEmpty {
                    self.ensureEmptyStateLabelIsVisible(true, text: "Немає учасників для оцінювання.")
                    self.saveRatingsButton.isEnabled = false
                } else {
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
                    self.saveRatingsButton.isEnabled = !self.ratedUsers.values.filter({ $0 > 0 }).isEmpty
                }
            }
        }
    }

    private func loadPreviouslyGivenRatings(completion: @escaping ([String: Int]) -> Void) {
        FirestoreManager.shared.fetchRatingsGivenByUserForEvent(
            raterUID: self.currentUserUID,
            eventID: self.event.id
        ) { result in
            switch result {
            case .success(let fetchedRatings):
                completion(fetchedRatings)
            case .failure(_):
                completion([:])
            }
        }
    }
    
    private func ensureEmptyStateLabelIsVisible(_ visible: Bool, text: String = "Помилка завантаження.") {
        if visible {
            if emptyStateLabel == nil {
                emptyStateLabel = UILabel()
                guard let label = emptyStateLabel else { return }
                AppAppearance.styleEmptyStateLabel(label, text: text) 
                view.addSubview(label)
                label.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    make.leading.trailing.equalToSuperview().inset(AppConstants.paddingXL) 
                }
            }
            emptyStateLabel?.text = text
            emptyStateLabel?.isHidden = false
            tableView.isHidden = true
        } else {
            emptyStateLabel?.isHidden = true
        }
    }
    
    private func setUIEnabled(_ enabled: Bool) {
        tableView.isUserInteractionEnabled = enabled
        saveRatingsButton.isEnabled = enabled && !ratedUsers.values.filter({ $0 > 0 }).isEmpty
        navigationItem.leftBarButtonItem?.isEnabled = enabled
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        let unsavedRatingsExist = !ratedUsers.values.filter({ $0 > 0 }).isEmpty
        if unsavedRatingsExist {
            let alert = UIAlertController(title: "Незбережені оцінки", message: "Ви впевнені, що хочете вийти? Ваші оцінки не будуть збережені.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Так, вийти", style: .destructive, handler: { _ in
                self.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Залишитися", style: .cancel, handler: nil))
            present(alert, animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @objc private func saveRatingsTapped() {
        activityIndicator.startAnimating()
        setUIEnabled(false)

        let ratingsToSave = self.ratedUsers.filter { $0.value > 0 }
        guard !ratingsToSave.isEmpty else {
            showAlert(title: "Немає оцінок", message: "Будь ласка, виставте хоча б одну оцінку.")
            activityIndicator.stopAnimating(); setUIEnabled(true)
            return
        }

        let group = DispatchGroup()
        var saveErrors: [Error] = []

        for (ratedUserID, rating) in ratingsToSave {
            group.enter()
            let role: FirestoreManager.UserRole = (ratedUserID == event.createdBy) ? .organizer : .participant
            
            FirestoreManager.shared.addRating(
                forUserID: ratedUserID, asRole: role, ratingValue: rating,
                byUserID: self.currentUserUID, forEventID: self.event.id
            ) { error in
                if let error = error { saveErrors.append(error) }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating(); self.setUIEnabled(true)

            if saveErrors.isEmpty {
                self.showAlert(title: "Дякуємо!", message: "Ваші оцінки успішно збережено.") {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                self.showAlert(title: "Помилка збереження", message: "Не вдалося зберегти деякі оцінки. \(saveErrors.first?.localizedDescription ?? "")")
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        let hasOrganizerToRate = usersToRate.contains(where: { $0.uid == event.createdBy && $0.uid != currentUserUID })
        let hasOtherParticipantsToRate = usersToRate.contains(where: { $0.uid != event.createdBy && $0.uid != currentUserUID })
        var sections = 0
        if hasOrganizerToRate { sections += 1 }
        if hasOtherParticipantsToRate { sections += 1 }
        return sections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let organizer = usersToRate.first(where: { $0.uid == event.createdBy && $0.uid != currentUserUID })
        let otherParticipants = usersToRate.filter { $0.uid != event.createdBy && $0.uid != currentUserUID }
        let sectionCount = numberOfSections(in: tableView)

        if sectionCount == 2 {
            return section == 0 ? (organizer != nil ? 1 : 0) : otherParticipants.count
        } else if sectionCount == 1 {
            return organizer != nil ? 1 : otherParticipants.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let hasOrganizerToRate = usersToRate.contains(where: { $0.uid == event.createdBy && $0.uid != currentUserUID })
        let hasOtherParticipantsToRate = usersToRate.contains(where: { $0.uid != event.createdBy && $0.uid != currentUserUID })
        let sectionCount = numberOfSections(in: tableView)

        if sectionCount == 2 { return section == 0 ? "Організатор Події" : "Учасники" }
        else if sectionCount == 1 {
            if hasOrganizerToRate { return "Організатор Події" }
            if hasOtherParticipantsToRate { return "Учасники" }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RatingTableViewCell.identifier, for: indexPath) as? RatingTableViewCell else {
            fatalError("Could not dequeue RatingTableViewCell")
        }
        
        let userProfile: UserProfile
        let organizer = usersToRate.first(where: { $0.uid == event.createdBy && $0.uid != currentUserUID })
        let otherParticipants = usersToRate.filter { $0.uid != event.createdBy && $0.uid != currentUserUID }
        let sectionCount = numberOfSections(in: tableView)

        if sectionCount == 2 {
            if indexPath.section == 0 { guard let org = organizer else { fatalError("Organizer profile expected") }; userProfile = org }
            else { userProfile = otherParticipants[indexPath.row] }
        } else if sectionCount == 1 {
            if organizer != nil { guard let org = organizer else { fatalError("Organizer profile expected") }; userProfile = org }
            else { userProfile = otherParticipants[indexPath.row] }
        } else { return UITableViewCell() }
        
        let initialRating = (userProfile.uid != nil) ? ratedUsers[userProfile.uid!] : 0
        cell.configure(with: userProfile, currentRating: initialRating)
        
        cell.onRatingChanged = { [weak self] (userID: String, newRating: Int) in
            guard let self = self else { return }
            if newRating > 0 { self.ratedUsers[userID] = newRating }
            else { self.ratedUsers.removeValue(forKey: userID) }
            self.saveRatingsButton.isEnabled = !self.ratedUsers.values.filter({ $0 > 0 }).isEmpty
        }
        return cell
    }
        
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            AppAppearance.styleTableViewHeader(headerView, customBackgroundColor: AppColors.subtleBackground) 
        }
    }

    // MARK: - Helper Methods
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in completion?() }))
        DispatchQueue.main.async { self.present(alert, animated: true, completion: nil) }
    }
}
