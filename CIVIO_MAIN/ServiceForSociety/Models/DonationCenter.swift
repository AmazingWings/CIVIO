import Foundation
import CoreLocation
import SwiftUI

// MARK: - CenterType Enum
enum CenterType: String, CaseIterable, Codable {
    case foodBank = "Food Bank"
    case homelessShelter = "Homeless Shelter"
    case recyclingCenter = "Recycling Center"
    case compostFacility = "Compost Facility"
    
    var icon: String {
        switch self {
        case .foodBank:
            return "cart.fill"
        case .homelessShelter:
            return "house.fill"
        case .recyclingCenter:
            return "arrow.3.trianglepath"
        case .compostFacility:
            return "leaf.fill"
        }
    }
}

// MARK: - DonationCenter Model
struct DonationCenter: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let address: String
    let type: CenterType
    let phone: String?
    let website: String?
    let hours: String
    let acceptedItems: [String]
    let latitude: Double
    let longitude: Double
    let description: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func distance(from location: CLLocation) -> CLLocationDistance {
        let centerLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: centerLocation)
    }
    
    func distanceInMiles(from location: CLLocation) -> Double {
        let distanceInMeters = distance(from: location)
        return distanceInMeters / 1609.34
    }
    
    static func == (lhs: DonationCenter, rhs: DonationCenter) -> Bool {
        lhs.id == rhs.id
    }
    

}
