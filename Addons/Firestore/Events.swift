import Foundation
import CoreLocation
import FirebaseFirestore

// MARK: - Модель Події
struct Event: Codable, Equatable {
    let id: String
    let name: String
    var themes: [String]?
    let description: String
    let location: String
    let date: Date
    let maxPeople: Int
    let createdBy: String
    var photoURL: String?
    let latitude: Double?
    let longitude: Double?
    var participantUIDs: [String]?

    // Ініціалізує новий екземпляр події.
    init(id: String,
         name: String,
         themes: [String]?,
         description: String,
         location: String,
         date: Date,
         maxPeople: Int,
         createdBy: String,
         photoURL: String? = nil,
         latitude: Double? = nil,
         longitude: Double? = nil,
         participantUIDs: [String]? = []) {
        self.id = id
        self.name = name
        self.themes = themes
        self.description = description
        self.location = location
        self.date = date
        self.maxPeople = maxPeople
        self.createdBy = createdBy
        self.photoURL = photoURL
        self.latitude = latitude
        self.longitude = longitude
        self.participantUIDs = participantUIDs
    }
    
    // Ключі для кодування/декодування даних.
    enum CodingKeys: String, CodingKey {
        case id, name, themes, description, location, date, maxPeople, createdBy, photoURL, latitude, longitude
        case participantUIDs
    }

    // Порівнює два екземпляри Event на рівність за їх ID.
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Перевіряє, чи подія вже завершилася.
    var hasEnded: Bool {
        return date < Date()
    }
}

// MARK: - Розширення Event
extension Event {
    // Повертає координати події, якщо вони доступні.
    func getCoordinate() -> CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
