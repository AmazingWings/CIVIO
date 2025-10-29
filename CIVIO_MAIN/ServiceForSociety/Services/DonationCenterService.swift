
import Foundation
import CoreLocation
import MapKit
import Combine

// Make sure this class name doesn't conflict with existing ones
@MainActor
class DynamicDonationCenterService: ObservableObject {
    static let shared = DynamicDonationCenterService()
    
    @Published var donationCenters: [DonationCenter] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Main Method to Find Donation/volunteering Centers Near User
    func findDonationCenters(near location: CLLocation, radius: Double = 25) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            donationCenters = []
        }
        
        var allCenters: [DonationCenter] = []
        
        // Search for each type of donation center
        for centerType in CenterType.allCases {
            if let centers = await searchForCenterType(centerType, near: location, radius: radius) {
                allCenters.append(contentsOf: centers)
            }
            // Small delay to be respectful to MapKit
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        }
        
        // Sort by distance from user
        let sortedCenters = allCenters.sorted { center1, center2 in
            center1.distance(from: location) < center2.distance(from: location)
        }
        
        await MainActor.run {
            self.donationCenters = sortedCenters
            self.isLoading = false
        }
    }
    
    // MARK: - Search for specific center types using MapKit
    private func searchForCenterType(_ centerType: CenterType, near location: CLLocation, radius: Double) async -> [DonationCenter]? {
        
        let searchTerms = getSearchTerms(for: centerType)
        var foundCenters: [DonationCenter] = []
        
        for searchTerm in searchTerms {
            if let centers = await performMapKitSearch(
                searchTerm: searchTerm,
                centerType: centerType,
                location: location,
                radius: radius
            ) {
                foundCenters.append(contentsOf: centers)
            }
        }
        
        // Remove duplicates based on location (same place found with different search terms)
        return removeDuplicateCenters(from: foundCenters)
    }
    
    private func getSearchTerms(for centerType: CenterType) -> [String] {
        switch centerType {
        case .foodBank:
            return [
                "food bank",
                "food pantry",
                "soup kitchen",
                "community food center"
            ]
        case .homelessShelter:
            return [
                "homeless shelter",
                "emergency shelter",
                "rescue mission",
                "salvation army"
            ]
        case .recyclingCenter:
            return [
                "recycling center",
                "waste management",
                "drop off recycling"
            ]
        case .compostFacility:
            return [
                "compost facility",
                "composting center",
                "organic waste"
            ]
        }
    }
    
    private func performMapKitSearch(
        searchTerm: String,
        centerType: CenterType,
        location: CLLocation,
        radius: Double
    ) async -> [DonationCenter]? {
        
        return await withCheckedContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = searchTerm
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: radius * 1609.34, // Convert miles to meters
                longitudinalMeters: radius * 1609.34
            )
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                guard let response = response else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let centers = response.mapItems.compactMap { mapItem -> DonationCenter? in
                    return self.createDonationCenter(from: mapItem, type: centerType)
                }
                
                continuation.resume(returning: centers)
            }
        }
    }
    
    private func createDonationCenter(from mapItem: MKMapItem, type: CenterType) -> DonationCenter? {
        guard let name = mapItem.name,
              let address = mapItem.placemark.title else { return nil }
        
        let coordinate = mapItem.placemark.coordinate
        
        return DonationCenter(
            id: UUID(),
            name: name,
            address: address,
            type: type,
            phone: mapItem.phoneNumber,
            website: mapItem.url?.absoluteString,
            hours: getDefaultHours(for: type),
            acceptedItems: getAcceptedItems(for: type),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            description: getDefaultDescription(for: type, name: name)
        )
    }
    
    private func getDefaultHours(for centerType: CenterType) -> String {
        switch centerType {
        case .foodBank:
            return "Mon-Fri: 9AM-4PM, Sat: 9AM-2PM"
        case .homelessShelter:
            return "24/7 - Meals at specific times"
        case .recyclingCenter:
            return "Mon-Sat: 8AM-5PM"
        case .compostFacility:
            return "Mon-Fri: 8AM-4PM, Sat: 9AM-3PM"
        }
    }
    
    private func getAcceptedItems(for centerType: CenterType) -> [String] {
        switch centerType {
        case .foodBank:
            return ["Non-perishable food", "Canned goods", "Fresh produce", "Baby food"]
        case .homelessShelter:
            return ["Hot meals", "Prepared food", "Beverages", "Snacks"]
        case .recyclingCenter:
            return ["Paper", "Plastic", "Glass", "Metal", "Electronics"]
        case .compostFacility:
            return ["Food scraps", "Yard waste", "Coffee grounds", "Paper towels"]
        }
    }
    
    private func getDefaultDescription(for centerType: CenterType, name: String) -> String {
        switch centerType {
        case .foodBank:
            return "\(name) provides food assistance to community members in need."
        case .homelessShelter:
            return "\(name) offers shelter and support services for individuals experiencing homelessness."
        case .recyclingCenter:
            return "\(name) accepts recyclable materials to help protect the environment."
        case .compostFacility:
            return "\(name) processes organic waste into compost for sustainable gardening."
        }
    }
    
    private func removeDuplicateCenters(from centers: [DonationCenter]) -> [DonationCenter] {
        var uniqueCenters: [DonationCenter] = []
        var seenLocations: Set<String> = []
        
        for center in centers {
            let locationKey = "\(center.latitude),\(center.longitude)"
            if !seenLocations.contains(locationKey) {
                seenLocations.insert(locationKey)
                uniqueCenters.append(center)
            }
        }
        
        return uniqueCenters
    }
}
