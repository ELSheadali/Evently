import Foundation
import FirebaseStorage
import UIKit

// MARK: - Менеджер для Роботи з Firebase Storage
class StorageManager {
    static let shared = StorageManager()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - Фото Подій

    // Завантажує фото для події.
    func uploadEventPhoto(_ image: UIImage, eventID: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "StorageManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot convert event image."])))
            return
        }

        let ref = storage.reference().child("event_photos/\(eventID).jpg")

        ref.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            ref.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                } else {
                    completion(.failure(NSError(domain: "StorageManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown downloadURL error for event photo."])))
                }
            }
        }
    }

    // Видаляє фото події.
    func deleteEventPhoto(eventID: String, completion: @escaping (Error?) -> Void) {
        let storageRef = storage.reference().child("event_photos/\(eventID).jpg")

        storageRef.delete { error in
            if let error = error {
                let nsError = error as NSError
                if nsError.domain == StorageErrorDomain && nsError.code == StorageErrorCode.objectNotFound.rawValue {
                    completion(nil)
                } else {
                    completion(error)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Фото Профілю Користувача

    // Завантажує фото профілю користувача.
    func uploadUserProfilePhoto(_ image: UIImage, userID: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(.failure(NSError(domain: "StorageManagerUser", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot convert user profile image."])))
            return
        }

        let ref = storage.reference().child("user_profile_photos/\(userID).jpg")

        ref.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            ref.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                } else {
                    completion(.failure(NSError(domain: "StorageManagerUser", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unknown downloadURL error for user profile photo."])))
                }
            }
        }
    }

    // Видаляє фото профілю користувача.
    func deleteUserProfilePhoto(userID: String, completion: @escaping (Error?) -> Void) {
        let storageRef = storage.reference().child("user_profile_photos/\(userID).jpg")

        storageRef.delete { error in
            if let error = error {
                let nsError = error as NSError
                if nsError.domain == StorageErrorDomain && nsError.code == StorageErrorCode.objectNotFound.rawValue {
                    completion(nil)
                } else {
                    completion(error)
                }
            } else {
                completion(nil)
            }
        }
    }
}
