import Foundation
import CoreLocation
@preconcurrency import MapKit

@MainActor
class SearchService: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    
    func searchLocation(_ query: String) async {
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        // FIXED: Set to search entire USA
        let usaCenter = CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
        let usaSpan = MKCoordinateSpan(latitudeDelta: 50.0, longitudeDelta: 60.0)
        request.region = MKCoordinateRegion(center: usaCenter, span: usaSpan)
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            let results = response.mapItems.map { item in
                SearchResult(
                    name: item.name ?? "Unknown Location",
                    coordinate: item.placemark.coordinate,
                    address: formatAddress(item.placemark)
                )
            }
            
            searchResults = results
            isSearching = false
            print("✅ Found \(results.count) locations nationwide")
        } catch {
            searchResults = []
            isSearching = false
            print("❌ Search error: \(error.localizedDescription)")
        }
    }
    
    // Enhanced search for volunteering opportunities nationwide
    func searchVolunteeringOpportunities(_ query: String, near location: CLLocation? = nil) async -> [VolunteeringOpportunity] {
        var allOpportunities: [VolunteeringOpportunity] = []
        
        let searchTerms = getVolunteeringSearchTerms(for: query)
        
        for searchTerm in searchTerms {
            let opportunities = await searchForOpportunities(
                searchTerm: searchTerm,
                near: location,
                radius: location != nil ? 100.0 : 1000.0 // FIXED: Much larger radius for nationwide
            )
            allOpportunities.append(contentsOf: opportunities)
        }
        
        return removeDuplicateOpportunities(from: allOpportunities)
    }
    
    private func getVolunteeringSearchTerms(for query: String) -> [String] {
        let baseQuery = query.lowercased()
        var searchTerms: [String] = [query]
        
        if baseQuery.contains("food") || baseQuery.contains("hunger") {
            searchTerms.append(contentsOf: ["food bank", "soup kitchen", "food pantry", "community kitchen"])
        }
        
        if baseQuery.contains("homeless") || baseQuery.contains("shelter") {
            searchTerms.append(contentsOf: ["homeless shelter", "emergency shelter", "rescue mission"])
        }
        
        if baseQuery.contains("environment") || baseQuery.contains("clean") {
            searchTerms.append(contentsOf: ["environmental cleanup", "park cleanup", "beach cleanup"])
        }
        
        if baseQuery.contains("education") || baseQuery.contains("tutor") {
            searchTerms.append(contentsOf: ["tutoring", "after school program", "literacy program"])
        }
        
        if baseQuery.contains("elder") || baseQuery.contains("senior") {
            searchTerms.append(contentsOf: ["senior center", "elder care", "nursing home volunteer"])
        }
        
        if baseQuery.contains("community") || baseQuery.contains("outreach") {
            searchTerms.append(contentsOf: ["community center", "volunteer center", "nonprofit"])
        }
        
        return Array(Set(searchTerms))
    }
    
    private func searchForOpportunities(
        searchTerm: String,
        near location: CLLocation?,
        radius: Double
    ) async -> [VolunteeringOpportunity] {
        
        return await withCheckedContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = searchTerm
            
            // FIXED: Set search region based on whether location is provided
            if let location = location {
                request.region = MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: radius * 1609.34,
                    longitudinalMeters: radius * 1609.34
                )
            } else {
                // FIXED: Search entire USA if no location provided
                let usaCenter = CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
                let usaSpan = MKCoordinateSpan(latitudeDelta: 50.0, longitudeDelta: 60.0)
                request.region = MKCoordinateRegion(center: usaCenter, span: usaSpan)
                print("🌎 Searching NATIONWIDE for: \(searchTerm)")
            }
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                guard let response = response else {
                    continuation.resume(returning: [])
                    return
                }
                
                let opportunities = response.mapItems.compactMap { mapItem -> VolunteeringOpportunity? in
                    return self.createVolunteeringOpportunity(from: mapItem, searchTerm: searchTerm)
                }
                
                print("✅ Found \(opportunities.count) opportunities for '\(searchTerm)'")
                continuation.resume(returning: opportunities)
            }
        }
    }
    
    private func createVolunteeringOpportunity(from mapItem: MKMapItem, searchTerm: String) -> VolunteeringOpportunity? {
        guard let name = mapItem.name,
              let address = mapItem.placemark.title else { return nil }
        
        let coordinate = mapItem.placemark.coordinate
        let opportunityType = determineOpportunityType(from: searchTerm, name: name)
        
        return VolunteeringOpportunity.create(
            title: name,
            organization: name,
            description: generateDescription(for: opportunityType, name: name),
            type: opportunityType,
            address: address,
            coordinate: coordinate,
            timeCommitment: "2-4 hours",
            requirements: getDefaultRequirements(for: opportunityType),
            contactPhone: mapItem.phoneNumber,
            isOngoing: true
        )
    }
    
    private func determineOpportunityType(from searchTerm: String, name: String) -> OpportunityType {
        let combined = (searchTerm + " " + name).lowercased()
        
        if combined.contains("food") || combined.contains("kitchen") || combined.contains("pantry") {
            return .foodService
        } else if combined.contains("shelter") || combined.contains("homeless") || combined.contains("rescue") {
            return .shelterSupport
        } else if combined.contains("environment") || combined.contains("cleanup") || combined.contains("park") {
            return .environmentalCleanup
        } else if combined.contains("education") || combined.contains("tutor") || combined.contains("school") {
            return .education
        } else if combined.contains("elder") || combined.contains("senior") || combined.contains("nursing") {
            return .elderCare
        } else {
            return .communityOutreach
        }
    }
    
    private func generateDescription(for type: OpportunityType, name: String) -> String {
        switch type {
        case .foodService:
            return "\(name) provides food assistance to community members in need. Volunteers help with meal preparation, serving, and distribution."
        case .shelterSupport:
            return "\(name) offers shelter and support services for individuals experiencing homelessness. Volunteers assist with daily operations and provide companionship."
        case .environmentalCleanup:
            return "\(name) focuses on environmental conservation and community cleanup efforts. Volunteers help maintain clean and healthy community spaces."
        case .education:
            return "\(name) provides educational support and tutoring services. Volunteers help students with learning and academic development."
        case .elderCare:
            return "\(name) serves elderly community members with care and companionship. Volunteers provide social interaction and assistance with daily activities."
        case .communityOutreach:
            return "\(name) engages in community outreach and support programs. Volunteers help connect community members with resources and services."
        }
    }
    
    private func getDefaultRequirements(for type: OpportunityType) -> [String] {
        switch type {
        case .foodService:
            return ["Comfortable standing for long periods", "Food safety awareness preferred"]
        case .shelterSupport:
            return ["Compassionate attitude", "Background check may be required"]
        case .environmentalCleanup:
            return ["Wear comfortable clothes", "Bring water bottle"]
        case .education:
            return ["Background check required", "Experience with children preferred"]
        case .elderCare:
            return ["Patient and friendly demeanor", "Ability to engage in conversation"]
        case .communityOutreach:
            return ["Outgoing personality", "Good communication skills"]
        }
    }
    
    private func removeDuplicateOpportunities(from opportunities: [VolunteeringOpportunity]) -> [VolunteeringOpportunity] {
        var uniqueOpportunities: [VolunteeringOpportunity] = []
        var seenLocations: Set<String> = []
        
        for opportunity in opportunities {
            let locationKey = "\(opportunity.latitude),\(opportunity.longitude)"
            if !seenLocations.contains(locationKey) {
                seenLocations.insert(locationKey)
                uniqueOpportunities.append(opportunity)
            }
        }
        
        return uniqueOpportunities
    }
    
    private func formatAddress(_ placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let state = placemark.administrativeArea {
            components.append(state)
        }
        
        return components.joined(separator: ", ")
    }
}

struct SearchResult: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.address == rhs.address
    }
}
