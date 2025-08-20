import Foundation
import SwiftUI

class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    private var services: [String: Any] = [:]
    
    private init() {}
    
    func register<T>(_ type: T.Type, _ service: T) {
        let key = String(describing: type)
        services[key] = service
    }
    
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return services[key] as? T
    }
}