import UIKit
import FirebaseFirestore
import FirebaseAuth
import SnapKit

// MARK: - View Controller for Displaying User's Past Events
class UserPastEventsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - UI Elements
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Історія ваших подій"
        label.font = AppFonts.drawerTitle 
        label.textColor = AppColors.primaryText 
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.register(EventTableViewCell.self, forCellReuseIdentifier: EventTableViewCell.identifier)
        tv.isScrollEnabled = true
        tv.alwaysBounceVertical = true
        return tv
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        AppAppearance.styleActivityIndicator(indicator) 
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private var emptyStateLabel: UILabel?

    // MARK: - Data Properties
    private var pastEvents: [Event] = []

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        AppAppearance.applyPrimaryBackground(to: view) 
        setupNavigation()
        setupLayout()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        loadPastUserEvents()
    }
    
    // MARK: - Setup Methods
    private func setupNavigation() {
        navigationItem.title = "Історія Подій"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        AppAppearance.setupStandardNavigationBar(navigationController) 
    }

    private func setupLayout() {
        view.addSubview(headerLabel)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        headerLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppConstants.paddingXL) 
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(AppConstants.paddingXL) 
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(AppConstants.paddingL) 
            make.leading.equalTo(view.safeAreaLayoutGuide)
            make.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    // MARK: - UI Update Methods
    private func ensureEmptyStateLabelIsVisible(_ visible: Bool, text: String = "У вас ще немає минулих подій.") {
        if visible {
            tableView.isHidden = true
            
            if emptyStateLabel == nil {
                emptyStateLabel = UILabel()
                guard let label = emptyStateLabel else { return }
                AppAppearance.styleEmptyStateLabel(label, text: text) 
                view.addSubview(label)
                label.snp.makeConstraints { make in
                    make.top.equalTo(headerLabel.snp.bottom).offset(AppConstants.paddingXXL) 
                    make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(AppConstants.paddingXL) 
                    make.centerY.equalTo(tableView)
                }
            }
            emptyStateLabel?.text = text
            emptyStateLabel?.isHidden = false
        } else {
            emptyStateLabel?.isHidden = true
            tableView.isHidden = false
        }
    }

    // MARK: - Data Loading
    private func loadPastUserEvents() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            ensureEmptyStateLabelIsVisible(true, text: "Потрібна авторизація для перегляду історії.")
            return
        }

        activityIndicator.startAnimating()
        ensureEmptyStateLabelIsVisible(false)

        let db = Firestore.firestore()
        let eventsCollection = db.collection("events")
        
        var fetchedEvents: [Event] = []
        let dispatchGroup = DispatchGroup()
        let now = Date()

        dispatchGroup.enter()
        eventsCollection.whereField("createdBy", isEqualTo: currentUserID).getDocuments { snapshot, error in
            defer { dispatchGroup.leave() }
            if error != nil { return }
            if let snapshot = snapshot {
                let createdEvents = snapshot.documents.compactMap { doc -> Event? in try? doc.data(as: Event.self) }.filter { $0.date < now }
                fetchedEvents.append(contentsOf: createdEvents)
            }
        }
        
        dispatchGroup.enter()
        eventsCollection.whereField("participantUIDs", arrayContains: currentUserID).getDocuments { snapshot, error in
            defer { dispatchGroup.leave() }
            if error != nil { return }
            if let snapshot = snapshot {
                let joinedEvents = snapshot.documents.compactMap { doc -> Event? in try? doc.data(as: Event.self) }.filter { $0.date < now }
                fetchedEvents.append(contentsOf: joinedEvents)
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            
            // Remove duplicates by ID and then sort
            let uniqueEvents = Array(Set(fetchedEvents.map { $0.id })).compactMap { id in fetchedEvents.first { $0.id == id } }
            self.pastEvents = uniqueEvents.sorted { $0.date > $1.date }
            if self.pastEvents.isEmpty {
                self.ensureEmptyStateLabelIsVisible(true)
            } else {
                self.ensureEmptyStateLabelIsVisible(false)
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Actions
    @objc private func doneButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pastEvents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EventTableViewCell.identifier, for: indexPath) as? EventTableViewCell else {
            fatalError("Could not dequeue EventTableViewCell")
        }
        let event = pastEvents[indexPath.row]
        cell.configure(with: event, cellType: .history)
        cell.selectionStyle = .none
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedEvent = pastEvents[indexPath.row]
        let popupVC = EventPopupViewController(mode: .view(event: selectedEvent, context: .discover))
        self.present(popupVC, animated: true, completion: nil)
    }
}
