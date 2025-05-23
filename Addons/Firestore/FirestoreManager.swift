import Foundation
import FirebaseFirestore

// MARK: - Менеджер для Роботи з Firestore
class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    private let eventsCollection = "events"
    private let ratingsCollection = "ratings"

    // MARK: - Типи Ролей Користувача
    enum UserRole {
        case organizer
        case participant
    }

    // MARK: - Методи Профілю Користувача
    
    // Отримує профіль користувача за його ID.
    func fetchUserProfile(userID: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        db.collection(usersCollection).document(userID).getDocument { documentSnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let document = documentSnapshot, document.exists else {
                let emptyProfile = UserProfile(uid: userID)
                completion(.success(emptyProfile))
                return
            }

            do {
                var userProfile = try document.data(as: UserProfile.self)
                if userProfile.uid == nil {
                    userProfile.uid = document.documentID
                }
                userProfile.organizerRatingsSum = userProfile.organizerRatingsSum ?? 0
                userProfile.organizerRatingsCount = userProfile.organizerRatingsCount ?? 0
                userProfile.participantRatingsSum = userProfile.participantRatingsSum ?? 0
                userProfile.participantRatingsCount = userProfile.participantRatingsCount ?? 0
                
                completion(.success(userProfile))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // Оновлює профіль користувача.
    func updateUserProfile(userID: String, profile: UserProfile, completion: @escaping (Error?) -> Void) {
        do {
            var profileToSave = profile
            profileToSave.organizerRatingsSum = profile.organizerRatingsSum ?? 0
            profileToSave.organizerRatingsCount = profile.organizerRatingsCount ?? 0
            profileToSave.participantRatingsSum = profile.participantRatingsSum ?? 0
            profileToSave.participantRatingsCount = profile.participantRatingsCount ?? 0
            try db.collection(usersCollection).document(userID).setData(from: profileToSave, merge: true, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    // MARK: - Методи Рейтингу

    // Додає рейтинг для користувача.
    func addRating(forUserID ratedUserID: String,
                       asRole: UserRole,
                       ratingValue: Int,
                       byUserID raterUID: String,
                       forEventID eventID: String,
                       completion: @escaping (Error?) -> Void) {
            
            let userProfileRef = db.collection(usersCollection).document(ratedUserID)
            let ratingDocID = "\(raterUID)_\(ratedUserID)_\(eventID)"
            let individualRatingRef = db.collection(ratingsCollection).document(ratingDocID)

            db.runTransaction { (transaction, errorPointer) -> Any? in
                
                let userProfileSnapshot: DocumentSnapshot
                do {
                    try userProfileSnapshot = transaction.getDocument(userProfileRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                var oldRatingValue = 0
                var isNewIndividualRating = true
                
                do {
                    let doc = try transaction.getDocument(individualRatingRef)
                    if doc.exists {
                        oldRatingValue = doc.data()?["ratingValue"] as? Int ?? 0
                        isNewIndividualRating = false
                    }
                } catch let fetchError as NSError {
                    if !(fetchError.domain == FirestoreErrorDomain && fetchError.code == FirestoreErrorCode.notFound.rawValue) {
                        errorPointer?.pointee = fetchError
                        return nil
                    }
                }

                var newSum: Int
                var newCount: Int
                let sumFieldKey: String
                let countFieldKey: String

                switch asRole {
                case .organizer:
                    sumFieldKey = "organizerRatingsSum"
                    countFieldKey = "organizerRatingsCount"
                case .participant:
                    sumFieldKey = "participantRatingsSum"
                    countFieldKey = "participantRatingsCount"
                }

                if userProfileSnapshot.exists {
                    let currentSum = userProfileSnapshot.data()?[sumFieldKey] as? Int ?? 0
                    let currentCount = userProfileSnapshot.data()?[countFieldKey] as? Int ?? 0

                    if isNewIndividualRating {
                        newSum = currentSum + ratingValue
                        newCount = currentCount + 1
                    } else {
                        newSum = currentSum - oldRatingValue + ratingValue
                        newCount = currentCount
                    }
                    
                    var profileUpdateData: [String: Any] = [:]
                    profileUpdateData[sumFieldKey] = newSum
                    profileUpdateData[countFieldKey] = newCount
                    transaction.updateData(profileUpdateData, forDocument: userProfileRef)
                    
                } else {
                    var newUserProfile = UserProfile(uid: ratedUserID)
                    
                    if asRole == .organizer {
                        newUserProfile.organizerRatingsSum = ratingValue
                        newUserProfile.organizerRatingsCount = 1
                    } else {
                        newUserProfile.participantRatingsSum = ratingValue
                        newUserProfile.participantRatingsCount = 1
                    }
                    
                    do {
                        try transaction.setData(from: newUserProfile, forDocument: userProfileRef)
                    } catch let setDataError as NSError {
                        errorPointer?.pointee = setDataError
                        return nil
                    }
                }

                let individualRatingData: [String: Any] = [
                    "ratedUserID": ratedUserID,
                    "raterUID": raterUID,
                    "eventID": eventID,
                    "roleOfRatedUser": (asRole == .organizer ? "organizer" : "participant"),
                    "ratingValue": ratingValue,
                    "timestamp": FieldValue.serverTimestamp()
                ]
                transaction.setData(individualRatingData, forDocument: individualRatingRef)
                
                return nil
            } completion: { (object, error) in
                completion(error)
            }
        }

    // Отримує рейтинги, виставлені користувачем для конкретної події.
    func fetchRatingsGivenByUserForEvent(raterUID: String, eventID: String, completion: @escaping (Result<[String: Int], Error>) -> Void) {
        db.collection(ratingsCollection)
          .whereField("raterUID", isEqualTo: raterUID)
          .whereField("eventID", isEqualTo: eventID)
          .getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            var ratingsMap: [String: Int] = [:]
            querySnapshot?.documents.forEach { document in
                if let ratedUserID = document.data()["ratedUserID"] as? String,
                   let ratingValue = document.data()["ratingValue"] as? Int {
                    ratingsMap[ratedUserID] = ratingValue
                }
            }
            completion(.success(ratingsMap))
        }
    }

    // MARK: - Методи Подій

    // Створює нову подію.
    func createEvent(_ event: Event, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "id": event.id,
            "name": event.name,
            "themes": event.themes ?? [],
            "description": event.description,
            "location": event.location,
            "date": Timestamp(date: event.date),
            "maxPeople": event.maxPeople,
            "createdBy": event.createdBy,
            "photoURL": event.photoURL ?? NSNull(),
            "latitude": event.latitude ?? NSNull(),
            "longitude": event.longitude ?? NSNull(),
            "participantUIDs": event.participantUIDs ?? []
        ]
        db.collection(eventsCollection).document(event.id).setData(data, completion: completion)
    }

    // Оновлює існуючу подію.
    func updateEvent(_ event: Event, completion: @escaping (Error?) -> Void) {
        var data: [String: Any] = [
            "name": event.name,
            "themes": event.themes ?? [],
            "description": event.description,
            "location": event.location,
            "date": Timestamp(date: event.date),
            "maxPeople": event.maxPeople,
            "latitude": event.latitude ?? NSNull(),
            "longitude": event.longitude ?? NSNull()
        ]
        if let photoURL = event.photoURL {
            data["photoURL"] = photoURL
        } else {
            data["photoURL"] = NSNull()
        }
        
        db.collection(eventsCollection).document(event.id).updateData(data, completion: completion)
    }

    // Оновлює координати події.
    func updateEventCoordinates(eventID: String, latitude: Double, longitude: Double, completion: @escaping (Error?) -> Void) {
        db.collection(eventsCollection).document(eventID).updateData([
            "latitude": latitude,
            "longitude": longitude
        ], completion: completion)
    }

    // Видаляє подію.
    func deleteEvent(eventID: String, completion: @escaping (Error?) -> Void) {
        db.collection(eventsCollection).document(eventID).delete(completion: completion)
    }
    
    // Дозволяє користувачеві приєднатися до події.
    func joinEvent(eventID: String, userID: String, completion: @escaping (Error?) -> Void) {
        db.collection(eventsCollection).document(eventID).updateData([
            "participantUIDs": FieldValue.arrayUnion([userID])
        ], completion: completion)
    }
    
    // Дозволяє користувачеві покинути подію.
    func unjoinEvent(eventID: String, userID: String, completion: @escaping (Error?) -> Void) {
        db.collection(eventsCollection).document(eventID).updateData([
            "participantUIDs": FieldValue.arrayRemove([userID])
        ], completion: completion)
    }
    
    // Мапить документи Firestore на об'єкти Event.
    private func mapDocumentsToEvents(documents: [QueryDocumentSnapshot]) -> [Event] {
        return documents.compactMap { doc -> Event? in
            let data = doc.data()
            let id = data["id"] as? String ?? doc.documentID
            let name = data["name"] as? String ?? "Назва відсутня"
            let themesArray = data["themes"] as? [String]
            let descriptionText = data["description"] as? String ?? "Опис відсутній"
            let locationName = data["location"] as? String ?? "Місцезнаходження не вказано"
            let eventCompletionDate = (data["date"] as? Timestamp)?.dateValue() ?? Date()
            let maxPeople = data["maxPeople"] as? Int ?? 0
            let createdBy = data["createdBy"] as? String ?? ""
            let photoURLString = data["photoURL"] as? String
            let latitude = data["latitude"] as? Double
            let longitude = data["longitude"] as? Double
            let participantUIDs = data["participantUIDs"] as? [String] ?? []

            guard !id.isEmpty, !createdBy.isEmpty else {
                return nil
            }
            return Event(id: id,
                         name: name,
                         themes: themesArray,
                         description: descriptionText,
                         location: locationName,
                         date: eventCompletionDate,
                         maxPeople: maxPeople,
                         createdBy: createdBy,
                         photoURL: photoURLString,
                         latitude: latitude,
                         longitude: longitude,
                         participantUIDs: participantUIDs)
        }
    }
    
    // Отримує події, до яких приєднався користувач.
    func fetchJoinedEvents(userID: String, completion: @escaping ([Event]) -> Void) {
        db.collection(eventsCollection)
          .whereField("participantUIDs", arrayContains: userID)
          .getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            completion(self.mapDocumentsToEvents(documents: documents))
        }
    }

    // Отримує всі події.
    func fetchEvents(completion: @escaping ([Event]) -> Void) {
        db.collection(eventsCollection).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            completion(self.mapDocumentsToEvents(documents: documents))
        }
    }
    
    // Отримує події, створені користувачем.
    func fetchUserEvents(userID: String, completion: @escaping ([Event]) -> Void) {
        db.collection(eventsCollection)
          .whereField("createdBy", isEqualTo: userID)
          .getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            completion(self.mapDocumentsToEvents(documents: documents))
        }
    }
}
