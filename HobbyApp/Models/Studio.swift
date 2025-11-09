import Foundation

struct Studio: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let phone: String?
    let address: String
    let city: String
    let province: String
    let postalCode: String
    let isActive: Bool
    
    init(id: String, name: String, email: String, phone: String?, address: String, city: String, province: String, postalCode: String, isActive: Bool) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.city = city
        self.province = province
        self.postalCode = postalCode
        self.isActive = isActive
    }
}