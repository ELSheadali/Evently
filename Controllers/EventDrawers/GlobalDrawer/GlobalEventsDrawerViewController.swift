import UIKit
import FirebaseAuth
import FirebaseFirestore

// MARK: - View Controller for Displaying Global Events
class GlobalEventsDrawerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, EventTableViewCellDelegate {

    // MARK: - Properties
    private var globalEventsDrawerView: GlobalEventsDrawerView { return self.view as! GlobalEventsDrawerView }
    private let backgroundDimmingView = UIView()
    
    private var displayedEvents: [Event] = []
    
    private var eventListener: ListenerRegistration?
    private let targetDimAlpha: CGFloat = 0.6
    
    private var activeFilters: FilterState?

    // MARK: - Initialization
    init(activeFilters: FilterState?) {
        self.activeFilters = activeFilters
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle Methods
    override func loadView() {
        self.view = GlobalEventsDrawerView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        setupDimmingView()
        setupGestures()

        globalEventsDrawerView.tableView.dataSource = self
        globalEventsDrawerView.tableView.delegate = self
        globalEventsDrawerView.closeButton.addTarget(self, action: #selector(closeDrawerWithAnimation), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchAllEventsWithListener()

        let screenWidth = UIScreen.main.bounds.width
        let containerWidth = screenWidth * 0.85
        globalEventsDrawerView.container.alpha = 0.0
        globalEventsDrawerView.container.transform = CGAffineTransform(translationX: -containerWidth, y: 0)
        
        backgroundDimmingView.frame = self.view.bounds
        backgroundDimmingView.alpha = 0.0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        eventListener?.remove()
    }

    deinit {
        eventListener?.remove()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundDimmingView.frame = self.view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.globalEventsDrawerView.container.transform = .identity
            self.globalEventsDrawerView.container.alpha = 1.0
            self.backgroundDimmingView.alpha = self.targetDimAlpha
        }, completion: nil)
    }

    // MARK: - Setup Methods
    private func setupDimmingView() {
        backgroundDimmingView.backgroundColor = UIColor.black
        backgroundDimmingView.alpha = 0.0
        self.view.insertSubview(backgroundDimmingView, at: 0)
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOnBackground(_:)))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeToClose(_:)))
        swipeGesture.direction = .left
        self.globalEventsDrawerView.container.addGestureRecognizer(swipeGesture)
    }

    // MARK: - Data Fetching and Filtering
    private func fetchAllEventsWithListener() {
        eventListener?.remove()
        eventListener = Firestore.firestore().collection("events")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: Date()))
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                if error != nil {
                    self.displayedEvents = []
                    self.globalEventsDrawerView.tableView.reloadData()
                    return
                }
                guard let snapshot = querySnapshot else {
                    self.displayedEvents = []
                    self.globalEventsDrawerView.tableView.reloadData()
                    return
                }
                
                let allActiveEvents = snapshot.documents.compactMap { doc -> Event? in
                    let data = doc.data()
                    return Event(id: data["id"] as? String ?? doc.documentID,
                                 name: data["name"] as? String ?? "",
                                 themes: data["themes"] as? [String],
                                 description: data["description"] as? String ?? "",
                                 location: data["location"] as? String ?? "",
                                 date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                                 maxPeople: data["maxPeople"] as? Int ?? 0,
                                 createdBy: data["createdBy"] as? String ?? "",
                                 photoURL: data["photoURL"] as? String,
                                 latitude: data["latitude"] as? Double,
                                 longitude: data["longitude"] as? Double,
                                 participantUIDs: data["participantUIDs"] as? [String] ?? [])
                }
                
                guard let userID = Auth.auth().currentUser?.uid else {
                    self.displayedEvents = self.applyFilters(to: allActiveEvents, with: self.activeFilters)
                    self.displayedEvents.sort(by: { $0.date < $1.date })
                    DispatchQueue.main.async { self.globalEventsDrawerView.tableView.reloadData() }
                    return
                }
                
                let userJoinedEvents = allActiveEvents.filter { $0.createdBy != userID && $0.participantUIDs?.contains(userID) == true }
                let discoverEvents = allActiveEvents.filter { $0.createdBy != userID && !($0.participantUIDs?.contains(userID) ?? false) }

                let filteredDiscoverEvents = self.applyFilters(to: discoverEvents, with: self.activeFilters)
                
                self.displayedEvents = userJoinedEvents + filteredDiscoverEvents
                self.displayedEvents.sort(by: { $0.date < $1.date })
            
                DispatchQueue.main.async {
                    self.globalEventsDrawerView.tableView.reloadData()
                }
            }
    }
    
    private func applyFilters(to events: [Event], with filters: FilterState?) -> [Event] {
        guard let filters = filters else { return events }
        var filteredEvents = events
        let calendar = Calendar.current
        
        if let startDateFilter = filters.startDate {
            filteredEvents = filteredEvents.filter { $0.date >= calendar.startOfDay(for: startDateFilter) }
        } else {
            filteredEvents = filteredEvents.filter { $0.date >= calendar.startOfDay(for: Date()) }
        }

        if let endDateFilter = filters.endDate {
            let endOfDayFilter = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDateFilter) ?? endDateFilter
            filteredEvents = filteredEvents.filter { $0.date <= endOfDayFilter }
        }

        if let peopleCountFilter = filters.peopleCount {
             filteredEvents = filteredEvents.filter { $0.maxPeople <= Int(peopleCountFilter) }
        }

        if let selectedThemeNames = filters.selectedThemeNames, !selectedThemeNames.isEmpty {
            filteredEvents = filteredEvents.filter { event in
                guard let eventThemes = event.themes, !eventThemes.isEmpty else { return false }
                return !Set(eventThemes).isDisjoint(with: Set(selectedThemeNames))
            }
        }
        return filteredEvents
    }

    // MARK: - Actions and Navigation
    @objc private func handleTapOnBackground(_ gesture: UITapGestureRecognizer) {
        let locationInContainer = gesture.location(in: self.globalEventsDrawerView.container)
        if !self.globalEventsDrawerView.container.bounds.contains(locationInContainer) {
             let locationInSelfView = gesture.location(in: self.view)
             if !self.globalEventsDrawerView.container.frame.contains(locationInSelfView) {
                  closeDrawerWithAnimation()
             }
        }
    }
    
    @objc private func handleSwipeToClose(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .left {
            closeDrawerWithAnimation()
        }
    }

    @objc func closeDrawerWithAnimation() {
        let containerWidth = self.globalEventsDrawerView.container.frame.width
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
            self.globalEventsDrawerView.container.transform = CGAffineTransform(translationX: -containerWidth, y: 0)
            self.globalEventsDrawerView.container.alpha = 0.0
            self.backgroundDimmingView.alpha = 0.0
        }, completion: { _ in
            self.dismiss(animated: false, completion: nil)
        })
    }
    
    private func showAlert(title: String = "Помилка", message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        if let presentedVC = self.presentedViewController {
            presentedVC.present(alertController, animated: true)
        } else {
            self.present(alertController, animated: true)
        }
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedEvents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EventTableViewCell.identifier, for: indexPath) as? EventTableViewCell else {
            fatalError("Could not dequeue EventTableViewCell for identifier: \(EventTableViewCell.identifier)")
        }
        guard indexPath.row < displayedEvents.count else { return UITableViewCell() }
        let event = displayedEvents[indexPath.row]
        
        let currentUserID = Auth.auth().currentUser?.uid
        var cellType: EventCellType = .discover
        if let userID = currentUserID {
            if event.createdBy == userID {
                cellType = .created
            } else if event.participantUIDs?.contains(userID) == true {
                cellType = .joined
            }
        }
        
        cell.configure(with: event, cellType: cellType)
        cell.delegate = self
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 115
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < displayedEvents.count else { return }
        let selectedEvent = displayedEvents[indexPath.row]
        
        var context: EventViewContext = .discover
        if let currentUserID = Auth.auth().currentUser?.uid {
            if selectedEvent.createdBy == currentUserID { context = .created }
            else if selectedEvent.participantUIDs?.contains(currentUserID) == true { context = .joined }
        }

        let popupVC = EventPopupViewController(mode: .view(event: selectedEvent, context: context))
        self.present(popupVC, animated: false, completion: nil)
    }

    // MARK: - EventTableViewCellDelegate
    func didTapEditButton(on cell: EventTableViewCell) {  }
    func didTapUnjoinButton(on cell: EventTableViewCell) {  }
    func didTapJoinButton(on cell: EventTableViewCell) {  }
}
