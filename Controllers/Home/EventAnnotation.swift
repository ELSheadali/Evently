import MapKit
import UIKit

// MARK: - Тип піна для події на карті
enum EventPinType {
    case general
    case createdByUser
    case joinedByUser

    func pinColor(fromCustomRedColor redColor: UIColor? = nil) -> UIColor {
        switch self {
        case .general:
            return redColor ?? AppColors.actionRed 
        case .createdByUser:
            return AppColors.accentYellow 
        case .joinedByUser:
            return AppColors.actionGreen 
        }
    }
}

// MARK: - Анотація для події на карті
class EventAnnotation: NSObject, MKAnnotation {
    let event: Event
    let coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    var pinType: EventPinType = .general
    var clusteringIdentifier: String? = "EventCluster" // Ідентифікатор для групування
    var displayPriority: MKFeatureDisplayPriority = .defaultLow // Пріоритет для кластеризації

    // MARK: - Initialization
    init(event: Event) {
        self.event = event
        self.coordinate = CLLocationCoordinate2D(latitude: event.latitude ?? 0.0, longitude: event.longitude ?? 0.0)
        self.title = event.name
        if let themesArray = event.themes, !themesArray.isEmpty {
            self.subtitle = themesArray.joined(separator: ", ")
        } else {
            self.subtitle = nil
        }
        super.init()
    }

    convenience init(event: Event, pinType: EventPinType, displayPriority: MKFeatureDisplayPriority = .defaultLow) {
        self.init(event: event)
        self.pinType = pinType
        self.displayPriority = displayPriority
    }
}
