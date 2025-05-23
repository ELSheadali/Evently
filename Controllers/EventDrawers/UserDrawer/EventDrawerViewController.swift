import UIKit
import FirebaseAuth

// MARK: - View Controller for Displaying User's Events (Joined/Created)
class EventsDrawerViewController: UIViewController {

    // MARK: - Properties
    private var eventsDrawerView: EventsDrawerView {
        return self.view as! EventsDrawerView
    }
    
    private let backgroundDimmingView = UIView()
    private var createdEvents: [Event] = []
    private var joinedEvents: [Event] = []
    private let targetDimAlpha: CGFloat = 0.5

    // MARK: - Lifecycle Methods
    override func loadView() {
        self.view = EventsDrawerView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        setupDimmingView()
        setupGestures()
        
        eventsDrawerView.tableView.dataSource = self
        eventsDrawerView.tableView.delegate = self
        eventsDrawerView.segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRefreshEventsNotification),
                                               name: .didCreateNewEvent,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .didCreateNewEvent, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshEvents()
        
        let screenWidth = UIScreen.main.bounds.width
        let containerWidthMultiplier: CGFloat = 0.85
        let calculatedContainerWidth = screenWidth * containerWidthMultiplier
        
        self.eventsDrawerView.container.alpha = 0.0
        self.eventsDrawerView.container.transform = CGAffineTransform(translationX: calculatedContainerWidth, y: 0)
        
        backgroundDimmingView.frame = self.view.bounds
        backgroundDimmingView.alpha = 0.0
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundDimmingView.frame = self.view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Animate drawer sliding in
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.eventsDrawerView.container.transform = .identity
            self.eventsDrawerView.container.alpha = 1.0
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
        swipeGesture.direction = .right
        self.eventsDrawerView.container.addGestureRecognizer(swipeGesture)
    }

    // MARK: - Data Fetching
    public func refreshEvents() {
        fetchUserCreatedEvents()
        fetchUserJoinedEvents()
    }

    private func fetchUserCreatedEvents() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.createdEvents = []; DispatchQueue.main.async { self.eventsDrawerView.tableView.reloadData() }
            return
        }
        FirestoreManager.shared.fetchUserEvents(userID: uid) { [weak self] events in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.createdEvents = events.sorted(by: { $0.date > $1.date })
                if self.eventsDrawerView.segmentedControl.selectedSegmentIndex == 1 {
                    self.eventsDrawerView.tableView.reloadData()
                }
            }
        }
    }

    private func fetchUserJoinedEvents() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.joinedEvents = []; DispatchQueue.main.async { self.eventsDrawerView.tableView.reloadData() }
            return
        }
        FirestoreManager.shared.fetchJoinedEvents(userID: uid) { [weak self] events in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let activeJoinedEvents = events.filter { event in
                    return !event.hasEnded && event.createdBy != uid
                }
                self.joinedEvents = activeJoinedEvents.sorted(by: { $0.date > $1.date })
                if self.eventsDrawerView.segmentedControl.selectedSegmentIndex == 0 { // "Joined"
                    self.eventsDrawerView.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Actions & Event Handlers
    @objc private func handleRefreshEventsNotification() {
        refreshEvents()
    }

    @objc private func handleTapOnBackground(_ gesture: UITapGestureRecognizer) {
        let locationInContainer = gesture.location(in: self.eventsDrawerView.container)
        if !self.eventsDrawerView.container.bounds.contains(locationInContainer) {
             let locationInSelfView = gesture.location(in: self.view)
             if !self.eventsDrawerView.container.frame.contains(locationInSelfView) { 
                  closeDrawerWithAnimation()
             }
        }
    }
    
    @objc private func handleSwipeToClose(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .right {
            closeDrawerWithAnimation()
        }
    }

    @objc private func segmentChanged() {
        self.eventsDrawerView.tableView.reloadData()
    }

    // MARK: - Navigation
    private func closeDrawerWithAnimation() {
        let containerActualWidth = self.eventsDrawerView.container.frame.width
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
            self.eventsDrawerView.container.transform = CGAffineTransform(translationX: containerActualWidth, y: 0)
            self.eventsDrawerView.container.alpha = 0.0
            self.backgroundDimmingView.alpha = 0.0
        }, completion: { _ in
            self.dismiss(animated: false, completion: nil)
        })
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension EventsDrawerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventsDrawerView.segmentedControl.selectedSegmentIndex == 0 ? joinedEvents.count : createdEvents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EventTableViewCell.identifier, for: indexPath) as? EventTableViewCell else {
            fatalError("Could not dequeue EventTableViewCell for identifier: \(EventTableViewCell.identifier)")
        }

        let event: Event
        let cellType: EventCellType
        let selectedSegmentIndex = eventsDrawerView.segmentedControl.selectedSegmentIndex

        if selectedSegmentIndex == 0 { // Joined
            guard indexPath.row < joinedEvents.count else { return UITableViewCell() }
            event = joinedEvents[indexPath.row]
            cellType = .joined
        } else { // Created
            guard indexPath.row < createdEvents.count else { return UITableViewCell() }
            event = createdEvents[indexPath.row]
            cellType = .created
        }

        cell.configure(with: event, cellType: cellType)
        cell.selectionStyle = .none
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedEvent: Event
        let context: EventViewContext
        let selectedSegmentIndex = eventsDrawerView.segmentedControl.selectedSegmentIndex

        if selectedSegmentIndex == 0 {
            guard indexPath.row < joinedEvents.count else { return }
            selectedEvent = joinedEvents[indexPath.row]
            context = .joined
        } else {
            guard indexPath.row < createdEvents.count else { return }
            selectedEvent = createdEvents[indexPath.row]
            context = .created
        }
        
        let popupVC = EventPopupViewController(mode: .view(event: selectedEvent, context: context))
        self.present(popupVC, animated: false, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// MARK: - EventTableViewCellDelegate
extension EventsDrawerViewController: EventTableViewCellDelegate {
    func didTapEditButton(on cell: EventTableViewCell) {
        guard let indexPath = eventsDrawerView.tableView.indexPath(for: cell) else { return }
        guard eventsDrawerView.segmentedControl.selectedSegmentIndex == 1,
              indexPath.row < createdEvents.count else { return }
              
        let eventToEdit = createdEvents[indexPath.row]
        guard eventToEdit.createdBy == Auth.auth().currentUser?.uid else {
            let alert = UIAlertController(title: "Дія заборонена", message: "Ви не можете редагувати цю подію.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true); return
        }

        let popupVC = EventPopupViewController(mode: .edit(event: eventToEdit))
        self.present(popupVC, animated: false, completion: nil)
    }
    
    func didTapUnjoinButton(on cell: EventTableViewCell) {
        guard let indexPath = eventsDrawerView.tableView.indexPath(for: cell) else { return }
        guard eventsDrawerView.segmentedControl.selectedSegmentIndex == 0,
              indexPath.row < joinedEvents.count else { return }
              
        let eventToUnjoin = joinedEvents[indexPath.row]
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let alert = UIAlertController(title: "Покинути подію?", message: "Ви впевнені, що хочете покинути подію \"\(eventToUnjoin.name)\"?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Так, покинути", style: .destructive, handler: { [weak self] _ in
            FirestoreManager.shared.unjoinEvent(eventID: eventToUnjoin.id, userID: userID) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        let errorAlert = UIAlertController(title: "Помилка", message: "Не вдалося покинути подію. Спробуйте ще раз. \(error.localizedDescription)", preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(errorAlert, animated: true)
                    } else {
                        self?.joinedEvents.remove(at: indexPath.row)
                        self?.eventsDrawerView.tableView.deleteRows(at: [indexPath], with: .automatic)

                    }
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    func didTapJoinButton(on cell: EventTableViewCell) {

    }
}
