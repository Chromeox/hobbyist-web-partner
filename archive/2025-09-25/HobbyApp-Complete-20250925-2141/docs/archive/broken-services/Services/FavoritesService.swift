import Foundation
import Combine

// MARK: - FavoritesService
class FavoritesService: ObservableObject {
    static let shared = FavoritesService()
    
    @Published private(set) var favoriteClassIds: Set<String> = []
    
    var favoritesPublisher: AnyPublisher<Set<String>, Never> {
        $favoriteClassIds.eraseToAnyPublisher()
    }
    
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "user_favorite_classes"
    
    private init() {
        loadFavorites()
    }
    
    private func loadFavorites() {
        if let data = userDefaults.data(forKey: favoritesKey),
           let favorites = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoriteClassIds = favorites
        }
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteClassIds) {
            userDefaults.set(data, forKey: favoritesKey)
        }
    }
    
    func toggleFavorite(classId: String) async throws {
        if favoriteClassIds.contains(classId) {
            favoriteClassIds.remove(classId)
        } else {
            favoriteClassIds.insert(classId)
        }
        saveFavorites()
    }
    
    func isFavorite(classId: String) -> Bool {
        favoriteClassIds.contains(classId)
    }
    
    func addToFavorites(classId: String) async throws {
        favoriteClassIds.insert(classId)
        saveFavorites()
    }
    
    func removeFromFavorites(classId: String) async throws {
        favoriteClassIds.remove(classId)
        saveFavorites()
    }
    
    func clearAllFavorites() {
        favoriteClassIds.removeAll()
        saveFavorites()
    }
}