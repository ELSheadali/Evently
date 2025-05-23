import Foundation
import FirebaseFirestore

// MARK: - Модель Профілю Користувача
struct UserProfile: Codable {
    var uid: String?
    var firstName: String?
    var lastName: String?
    var bio: String?
    var placeOfWork: String?
    var dateOfBirth: Date?
    var interests: [String]?
    var profilePhotoURL: String?

    var organizerRatingsSum: Int?
    var organizerRatingsCount: Int?
    var participantRatingsSum: Int?
    var participantRatingsCount: Int?

    // Ініціалізує новий екземпляр профілю користувача.
    init(uid: String? = nil,
         firstName: String? = nil,
         lastName: String? = nil,
         bio: String? = nil,
         placeOfWork: String? = nil,
         dateOfBirth: Date? = nil,
         interests: [String]? = nil,
         profilePhotoURL: String? = nil,
         organizerRatingsSum: Int? = 0,
         organizerRatingsCount: Int? = 0,
         participantRatingsSum: Int? = 0,
         participantRatingsCount: Int? = 0
    ) {
        self.uid = uid
        self.firstName = firstName
        self.lastName = lastName
        self.bio = bio
        self.placeOfWork = placeOfWork
        self.dateOfBirth = dateOfBirth
        self.interests = interests
        self.profilePhotoURL = profilePhotoURL
        self.organizerRatingsSum = organizerRatingsSum
        self.organizerRatingsCount = organizerRatingsCount
        self.participantRatingsSum = participantRatingsSum
        self.participantRatingsCount = participantRatingsCount
    }

    // MARK: - Обчислювані Властивості Рейтингу

    // Обчислює середній рейтинг організатора.
    var averageOrganizerRating: Double? {
        guard let sum = organizerRatingsSum, let count = organizerRatingsCount, count > 0 else {
            return nil
        }
        return Double(sum) / Double(count)
    }

    // Обчислює середній рейтинг учасника.
    var averageParticipantRating: Double? {
        guard let sum = participantRatingsSum, let count = participantRatingsCount, count > 0 else {
            return nil
        }
        return Double(sum) / Double(count)
    }
}
