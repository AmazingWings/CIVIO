import Foundation
import CoreLocation

enum OpportunityType: String, CaseIterable, Codable {
    case foodService = "Food Service"
    case shelterSupport = "Shelter Support"
    case environmentalCleanup = "Environmental Cleanup"
    case communityOutreach = "Community Outreach"
    case education = "Education"
    case elderCare = "Elder Care"
    
    var icon: String {
        switch self {
        case .foodService:
            return "hands.sparkles.fill"
        case .shelterSupport:
            return "heart.circle.fill"
        case .environmentalCleanup:
            return "leaf.arrow.circlepath"
        case .communityOutreach:
            return "person.3.fill"
        case .education:
            return "book.fill"
        case .elderCare:
            return "heart.text.square.fill"
        }
    }
}

struct VolunteeringOpportunity: Identifiable, Codable {
    let id: UUID
    let title: String
    let organization: String
    let description: String
    let type: OpportunityType
    let address: String
    let latitude: Double
    let longitude: Double
    let timeCommitment: String
    let requirements: [String]
    let contactEmail: String?
    let contactPhone: String?
    let isOngoing: Bool
    let startDate: Date?
    let endDate: Date?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func distance(from userLocation: CLLocation) -> CLLocationDistance {
        let opportunityLocation = CLLocation(latitude: latitude, longitude: longitude)
        return userLocation.distance(from: opportunityLocation)
    }
    
    func distanceInMiles(from userLocation: CLLocation?) -> Double {
        guard let userLocation = userLocation else { return .infinity }
        let distanceInMeters = distance(from: userLocation)
        return distanceInMeters / 1609.34 // Convert meters to miles
    }
    
    // Static method to create new opportunity with coordinate
    static func create(
        id: UUID = UUID(),
        title: String,
        organization: String,
        description: String,
        type: OpportunityType,
        address: String,
        coordinate: CLLocationCoordinate2D,
        timeCommitment: String,
        requirements: [String] = [],
        contactEmail: String? = nil,
        contactPhone: String? = nil,
        isOngoing: Bool = true,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> VolunteeringOpportunity {
        return VolunteeringOpportunity(
            id: id,
            title: title,
            organization: organization,
            description: description,
            type: type,
            address: address,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timeCommitment: timeCommitment,
            requirements: requirements,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            isOngoing: isOngoing,
            startDate: startDate,
            endDate: endDate
        )
    }
}

// Sample data for volunteering opportunities
extension VolunteeringOpportunity {
    static let sampleData: [VolunteeringOpportunity] = [
       
    ]
}
