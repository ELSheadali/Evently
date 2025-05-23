import UIKit
import MapKit
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

// MARK: - Контролер Головного Екрану з Картою
class HomeViewController: UIViewController {

    // MARK: - Properties
    private var homeView: HomeView!
    var activeFilters: FilterState? = nil {
        didSet {
            if oldValue != activeFilters {
                fetchAndDisplayEvents()
            }
        }
    }

    private var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }

    private var mapEventsListener: ListenerRegistration?
    
    private var userCreatedEvents: [Event] = []
    private var userJoinedEvents: [Event] = []
    private var discoverEvents: [Event] = []

    private let defaultLocationCoordinate = CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234) // Київ
    private let initialZoomLevel: CLLocationDistance = 25000
    var pinSelectedZoomLevel: CLLocationDistance = 700
    private let userLocationZoomLevel: CLLocationDistance = 500

    private let popupPresentationDelay: TimeInterval = 0.5
    let nearbyAnnotationsThreshold: CLLocationDegrees = 0.00015

    private let locationManager = CLLocationManager()
    private let clusterTapMaxLatitudeDeltaForList: CLLocationDegrees = 0.005

    // MARK: - Lifecycle Methods
    override func loadView() {
        let homeViewInstance = HomeView()
        self.homeView = homeViewInstance
        self.view = homeViewInstance
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard homeView != nil else {
            fatalError("HomeView не було ініціалізовано.")
        }
        
        setupMapView()
        setupButtonActions()
        setupNotificationObservers()
        setupLocationManager()
        
        fetchAndDisplayEvents()
    }

    deinit {
        mapEventsListener?.remove()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup Methods
    
    private func setupMapView() {
        let initialRegion = MKCoordinateRegion(center: defaultLocationCoordinate, latitudinalMeters: initialZoomLevel, longitudinalMeters: initialZoomLevel)
        homeView.mapView.setRegion(initialRegion, animated: false)
        homeView.mapView.delegate = self
        
        homeView.mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        homeView.mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }

    private func setupButtonActions() {
        homeView.menuButton.addTarget(self, action: #selector(openGlobalEventsDrawer), for: .touchUpInside)
        homeView.addButton.addTarget(self, action: #selector(openCreateEvent), for: .touchUpInside)
        homeView.profileButton.addTarget(self, action: #selector(openProfileSettings), for: .touchUpInside)
        homeView.myEventsButton.addTarget(self, action: #selector(openMyEventsDrawer), for: .touchUpInside)
        homeView.filterButton.addTarget(self, action: #selector(openFiltersMenu), for: .touchUpInside)
        homeView.homeButton.addTarget(self, action: #selector(resetMapToUserLocation), for: .touchUpInside)
        homeView.locateMeButton.addTarget(self, action: #selector(locateMeButtonTapped), for: .touchUpInside)
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleEventChanges), name: .didCreateNewEvent, object: nil)
    }

    private func setupLocationManager() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationAuthorization()
    }

    // MARK: - Event Handling
    
    @objc private func handleEventChanges() {
        fetchAndDisplayEvents()
    }

    // MARK: - Data Fetching & Annotation Updates
    
    private func fetchAndDisplayEvents() {
        FirestoreManager.shared.fetchEvents { [weak self] fetchedEvents in
            guard let self = self, let userID = self.currentUserID else { return }

            let activeEvents = fetchedEvents.filter { !$0.hasEnded }

            self.userCreatedEvents.removeAll()
            self.userJoinedEvents.removeAll()
            self.discoverEvents.removeAll()

            for event in activeEvents {
                if event.createdBy == userID {
                    self.userCreatedEvents.append(event)
                } else if event.participantUIDs?.contains(userID) == true {
                    self.userJoinedEvents.append(event)
                } else {
                    self.discoverEvents.append(event)
                }
            }
            
            let filteredDiscoverEvents = self.applyFilters(to: self.discoverEvents, with: self.activeFilters)
            
            let eventsToDisplay = self.userCreatedEvents + self.userJoinedEvents + filteredDiscoverEvents
            
            self.updateMapAnnotations(with: eventsToDisplay)
        }
    }
    
    private func applyFilters(to events: [Event], with filters: FilterState?) -> [Event] {
        guard let filters = filters else {
            return events
        }

        var filteredEvents = events
        let calendar = Calendar.current
        let startDateFilter = filters.startDate
        let endDateFilter = filters.endDate?.endOfDay

        filteredEvents = filteredEvents.filter { event in
            let isAfterStartDate: Bool
            if let start = startDateFilter {
                isAfterStartDate = event.date >= calendar.startOfDay(for: start)
            } else {
                isAfterStartDate = event.date >= calendar.startOfDay(for: Date())
            }

            let isBeforeEndDate: Bool
            if let end = endDateFilter {
                isBeforeEndDate = event.date <= end
            } else {
                isBeforeEndDate = true
            }
            return isAfterStartDate && isBeforeEndDate
        }

        if let peopleCountFilter = filters.peopleCount {
             filteredEvents = filteredEvents.filter { $0.maxPeople <= Int(peopleCountFilter) }
        }

        if let selectedThemeNames = filters.selectedThemeNames, !selectedThemeNames.isEmpty {
            filteredEvents = filteredEvents.filter { event in
                guard let eventThemes = event.themes, !eventThemes.isEmpty else {
                    return false
                }
                return !Set(eventThemes).isDisjoint(with: Set(selectedThemeNames))
            }
        }
        return filteredEvents
    }

    private func updateMapAnnotations(with eventsToDisplay: [Event]) {
        let existingAnnotations = homeView.mapView.annotations.compactMap { $0 as? EventAnnotation }
        let annotationsToRemove = existingAnnotations.filter { ann in
            !eventsToDisplay.contains(where: { $0.id == ann.event.id })
        }
        homeView.mapView.removeAnnotations(annotationsToRemove)

        let existingAnnotationIDs = Set(existingAnnotations.map { $0.event.id })
        let eventsToAdd = eventsToDisplay.filter { !existingAnnotationIDs.contains($0.id) }
        
        for event in eventsToAdd {
            var pinType: EventPinType = .general
            if let currentUserID = self.currentUserID {
                if event.createdBy == currentUserID { pinType = .createdByUser }
                else if event.participantUIDs?.contains(currentUserID) == true { pinType = .joinedByUser }
            }
            
            let displayPriorityForPin: MKFeatureDisplayPriority = .defaultHigh

            if let lat = event.latitude, let lon = event.longitude, (lat != 0.0 || lon != 0.0) {
                let annotation = EventAnnotation(event: event, pinType: pinType, displayPriority: displayPriorityForPin)
                homeView.mapView.addAnnotation(annotation)
            } else {
                geocodeAddressAndAddAnnotation(for: event, pinType: pinType, displayPriority: displayPriorityForPin)
            }
        }
    }
    
    private func geocodeAddressAndAddAnnotation(for event: Event, pinType: EventPinType, displayPriority: MKFeatureDisplayPriority) {
        guard !event.location.isEmpty else { return }
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(event.location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if error != nil { return }
            
            if let coordinate = placemarks?.first?.location?.coordinate {
                let annotation = EventAnnotation(event: Event(id: event.id, name: event.name, themes: event.themes, description: event.description, location: event.location, date: event.date, maxPeople: event.maxPeople, createdBy: event.createdBy, photoURL: event.photoURL, latitude: coordinate.latitude, longitude: coordinate.longitude, participantUIDs: event.participantUIDs), pinType: pinType, displayPriority: displayPriority)
                
                let isAlreadyOnMap = self.homeView.mapView.annotations.contains {
                    ($0 as? EventAnnotation)?.event.id == event.id
                }

                if !isAlreadyOnMap {
                    self.homeView.mapView.addAnnotation(annotation)
                }
            }
        }
    }

    // MARK: - Actions
    
    @objc private func locateMeButtonTapped() {
        let status = self.locationManager.authorizationStatus

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            if homeView.mapView.showsUserLocation, let userCoordinate = homeView.mapView.userLocation.location?.coordinate {
                let region = MKCoordinateRegion(center: userCoordinate,
                                                latitudinalMeters: self.userLocationZoomLevel,
                                                longitudinalMeters: self.userLocationZoomLevel)
                homeView.mapView.setRegion(region, animated: true)
            } else {
                showAlert(title: "Місцезнаходження", message: "Ваше поточне місцезнаходження ще визначається. Будь ласка, зачекайте або перевірте налаштування геолокації.")
                if CLLocationManager.locationServicesEnabled() && (status == .notDetermined || status == .authorizedWhenInUse || status == .authorizedAlways) {
                    self.locationManager.startUpdatingLocation()
                } else if status == .notDetermined {
                     self.locationManager.requestWhenInUseAuthorization()
                }
            }
        } else if status == .denied || status == .restricted {
            showLocationAccessDeniedAlert()
        } else if status == .notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    @objc private func resetMapToUserLocation() {
        if homeView.mapView.showsUserLocation, let userLocation = homeView.mapView.userLocation.location {
            let region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: initialZoomLevel / 2, longitudinalMeters: initialZoomLevel / 2)
            homeView.mapView.setRegion(region, animated: true)
        } else {
            showAlert(title: "Геолокація недоступна", message: "Ваше місцезнаходження не визначено. Показано карту Києва.")
            let region = MKCoordinateRegion(center: defaultLocationCoordinate, latitudinalMeters: initialZoomLevel, longitudinalMeters: initialZoomLevel)
            homeView.mapView.setRegion(region, animated: true)
        }
    }

    @objc private func openGlobalEventsDrawer() {
        let drawer = GlobalEventsDrawerViewController(activeFilters: self.activeFilters)
        drawer.modalPresentationStyle = .overCurrentContext
        present(drawer, animated: false, completion: nil)
    }

    @objc private func openMyEventsDrawer() {
        let drawer = EventsDrawerViewController()
        drawer.modalPresentationStyle = .overCurrentContext
        present(drawer, animated: false, completion: nil)
    }

    @objc private func openCreateEvent() {
        let vc = EventPopupViewController(mode: .create)
        self.present(vc, animated: false, completion: nil)
    }

    @objc private func openProfileSettings() {
        let vc = UserListViewController()
        let navController = UINavigationController(rootViewController: vc)
        present(navController, animated: true)
    }

    @objc func openFiltersMenu() {
        let filtersVC = FiltersMenuViewController(initialFilters: activeFilters, delegate: self)
        filtersVC.modalPresentationStyle = .overFullScreen
        present(filtersVC, animated: false, completion: nil)
    }
    
    // MARK: - Helpers
    
    private func showAlert(title: String, message: String) {
         let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
         present(alert, animated: true, completion: nil)
    }
     
    private func showLocationAccessDeniedAlert() {
        let alert = UIAlertController(title: "Доступ до геолокації заборонено", message: "Щоб використовувати цю функцію, будь ласка, увімкніть служби геолокації для цього додатка в Налаштуваннях.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "До Налаштувань", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func displayEventDetails(_ event: Event, on mapView: MKMapView) {
        guard let coordinate = event.getCoordinate() else {
            return
        }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: pinSelectedZoomLevel, longitudinalMeters: pinSelectedZoomLevel)
        mapView.setRegion(region, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + popupPresentationDelay) { [weak self] in
            guard let self = self else { return }
            var context: EventViewContext = .discover
            if let userId = self.currentUserID {
                if event.createdBy == userId {
                    context = .created
                } else if event.participantUIDs?.contains(userId) == true {
                    context = .joined
                }
            }
            let popupVC = EventPopupViewController(mode: .view(event: event, context: context))
            self.present(popupVC, animated: false, completion: nil)
        }
    }
     
    private func checkLocationAuthorization() {
        switch self.locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            homeView.mapView.showsUserLocation = true
            self.locationManager.startUpdatingLocation()
        case .denied, .restricted:
            break
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
 }

// MARK: - MKMapViewDelegate
extension HomeViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }

        if let eventAnnotation = annotation as? EventAnnotation {
            let identifier = MKMapViewDefaultAnnotationViewReuseIdentifier
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: eventAnnotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = eventAnnotation
            }
            annotationView?.markerTintColor = eventAnnotation.pinType.pinColor(fromCustomRedColor: homeView.redColorForPins)
            annotationView?.glyphImage = UIImage(systemName: "mappin.and.ellipse")
            annotationView?.clusteringIdentifier = eventAnnotation.clusteringIdentifier
            annotationView?.displayPriority = eventAnnotation.displayPriority
            return annotationView
        }
        
        if let clusterAnnotation = annotation as? MKClusterAnnotation {
            let identifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier
            var clusterView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if clusterView == nil {
                clusterView = MKMarkerAnnotationView(annotation: clusterAnnotation, reuseIdentifier: identifier)
                clusterView?.canShowCallout = false
            } else {
                clusterView?.annotation = clusterAnnotation
            }
            clusterView?.markerTintColor = AppColors.accentBlue
            clusterView?.glyphText = "\(clusterAnnotation.memberAnnotations.count)"
            return clusterView
        }
        return nil
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        guard let selectedAnnotation = view.annotation else { return }

        if selectedAnnotation is MKUserLocation { return }
        
        var eventsToShowInList: [Event] = []

        if let cluster = selectedAnnotation as? MKClusterAnnotation {
            if mapView.region.span.latitudeDelta > clusterTapMaxLatitudeDeltaForList {
                return
            }
            eventsToShowInList = cluster.memberAnnotations.compactMap { ($0 as? EventAnnotation)?.event }
        } else if let eventAnn = selectedAnnotation as? EventAnnotation {
            let tapCoord = eventAnn.coordinate
            var nearbyEventAnnotations: [EventAnnotation] = []
            
            for annOnMap in mapView.annotations {
                guard let currentEventAnn = annOnMap as? EventAnnotation,
                      currentEventAnn.event.getCoordinate() != nil else { continue }
                
                let distLat = abs(currentEventAnn.coordinate.latitude - tapCoord.latitude)
                let distLon = abs(currentEventAnn.coordinate.longitude - tapCoord.longitude)
                
                if distLat < nearbyAnnotationsThreshold && distLon < nearbyAnnotationsThreshold {
                    nearbyEventAnnotations.append(currentEventAnn)
                }
            }
            let uniqueNearbyEventIds = Set(nearbyEventAnnotations.map { $0.event.id })
            eventsToShowInList = uniqueNearbyEventIds.compactMap { id in
                nearbyEventAnnotations.first { $0.event.id == id }?.event
            }
        } else {
            return
        }

        eventsToShowInList.sort(by: { $0.name < $1.name })

        if eventsToShowInList.count == 1 {
            displayEventDetails(eventsToShowInList[0], on: mapView)
        } else if eventsToShowInList.count > 1 {
            let actionSheet = UIAlertController(title: "Оберіть подію",
                                                message: "Декілька подій знаходяться поруч.",
                                                preferredStyle: .actionSheet)
            
            for eventInList in eventsToShowInList {
                let action = UIAlertAction(title: eventInList.name, style: .default) { [weak self] _ in
                    self?.displayEventDetails(eventInList, on: mapView)
                }
                actionSheet.addAction(action)
            }
            
            actionSheet.addAction(UIAlertAction(title: "Скасувати", style: .cancel, handler: nil))
            
            if let popoverController = actionSheet.popoverPresentationController {
                popoverController.sourceView = view
                popoverController.sourceRect = view.bounds
                popoverController.permittedArrowDirections = .any
            }
            
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
}

 // MARK: - CLLocationManagerDelegate
extension HomeViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}

// MARK: - FiltersMenuDelegate
extension HomeViewController: FiltersMenuDelegate {
    func filtersMenuDidApply(filters: FilterState?) {
        self.activeFilters = filters
    }
}

// MARK: - Допоміжне Розширення для Date
extension Date {
    var endOfDay: Date {
        return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self)!
    }
}
