//
//  EventsDrawerViewController.swift
//  PinPoint
//
//  Created by Denys Makarenko on 28.05.2025.
//
import UIKit
import FirebaseAuth

class EventsDrawerViewController: UIViewController {

    private var eventsDrawerView: EventsDrawerView {
        return self.view as! EventsDrawerView
    }
    
    private let backgroundDimmingView = UIView()
    private var createdEvents: [Event] = []
    private var joinedEvents: [Event] = []
    private let targetDimAlpha: CGFloat = 0.5

    override func loadView() {
        self.view = EventsDrawerView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        setupDimmingView()
        setupGestures()
        fetchUserEvents()
    }

    private func setupDimmingView() {
        backgroundDimmingView.backgroundColor = UIColor.black
        backgroundDimmingView.alpha = 0.0
        self.view.insertSubview(backgroundDimmingView, at: 0)
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOnBackground(_:)))
        self.view.addGestureRecognizer(tapGesture)

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeToClose(_:)))
        swipeGesture.direction = .right
        self.view.addGestureRecognizer(swipeGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let screenWidth = UIScreen.main.bounds.width
        
        self.eventsDrawerView.container.alpha = 0.0
        self.eventsDrawerView.container.transform = CGAffineTransform(translationX: screenWidth, y: 0)

        backgroundDimmingView.frame = self.view.bounds
        backgroundDimmingView.transform = CGAffineTransform(translationX: screenWidth, y: 0)
        backgroundDimmingView.alpha = 0.0
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundDimmingView.frame = self.view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let containerWidth = self.eventsDrawerView.container.frame.width
        let initialContainerX = containerWidth > 0 ? containerWidth : UIScreen.main.bounds.width
        
        self.eventsDrawerView.container.transform = CGAffineTransform(translationX: initialContainerX, y: 0)
        self.eventsDrawerView.container.alpha = 1.0
        
        let screenWidthForTransform = self.view.bounds.width
        self.backgroundDimmingView.transform = CGAffineTransform(translationX: screenWidthForTransform, y: 0)
        self.backgroundDimmingView.alpha = 0.0

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.eventsDrawerView.container.transform = .identity
            
            self.backgroundDimmingView.transform = .identity
            self.backgroundDimmingView.alpha = self.targetDimAlpha
        }, completion: nil)
    }

    @objc private func handleTapOnBackground(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self.view)
        if !self.eventsDrawerView.container.frame.contains(location) {
            closeDrawerWithAnimation()
        }
    }
    
    @objc private func handleSwipeToClose(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .right {
            closeDrawerWithAnimation()
        }
    }

    private func closeDrawerWithAnimation() {
        let containerWidth = self.eventsDrawerView.container.frame.width
        let finalContainerX = containerWidth > 0 ? containerWidth : UIScreen.main.bounds.width
        let viewWidth = self.view.bounds.width

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
            self.eventsDrawerView.container.transform = CGAffineTransform(translationX: finalContainerX, y: 0)
            self.eventsDrawerView.container.alpha = 0.0
            
            self.backgroundDimmingView.transform = CGAffineTransform(translationX: viewWidth, y: 0)
            self.backgroundDimmingView.alpha = 0.0
        }, completion: { _ in
            self.dismiss(animated: false, completion: nil)
        })
    }

    @objc private func segmentChanged() {
        self.eventsDrawerView.tableView.reloadData()
    }

    private func fetchUserEvents() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        FirestoreManager.shared.fetchUserEvents(userID: uid) { [weak self] events in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.createdEvents = events
                self.eventsDrawerView.tableView.reloadData()
            }
        }
    }
}

extension EventsDrawerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventsDrawerView.segmentedControl.selectedSegmentIndex == 0 ? joinedEvents.count : createdEvents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event: Event
        if eventsDrawerView.segmentedControl.selectedSegmentIndex == 0 {
            guard indexPath.row < joinedEvents.count else { return UITableViewCell() }
            event = joinedEvents[indexPath.row]
        } else {
            guard indexPath.row < createdEvents.count else { return UITableViewCell() }
            event = createdEvents[indexPath.row]
        }

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = .clear
        cell.textLabel?.text = event.name
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.text = event.theme
        cell.detailTextLabel?.textColor = .lightGray
        return cell
    }
}
