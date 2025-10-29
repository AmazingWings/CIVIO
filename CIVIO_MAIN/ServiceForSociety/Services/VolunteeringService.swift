import Foundation
import CoreLocation
import Combine
import UserNotifications

@MainActor
class VolunteeringService: ObservableObject {
    static let shared = VolunteeringService()
    
    @Published var opportunities: [VolunteeringOpportunity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let opportunitiesKey = "savedOpportunities"
    
    private init() {
        loadOpportunities()
        // Users will start with an empty list and can add their own events
    }
    
    // MARK: - Public Methods
    
    func addOpportunity(_ opportunity: VolunteeringOpportunity) {
        opportunities.append(opportunity)
        saveOpportunities()
        
        // Send notification for new opportunity
        NotificationCenter.default.post(
            name: NSNotification.Name("NewVolunteeringOpportunity"),
            object: opportunity
        )
    }
    
    func removeOpportunity(_ opportunity: VolunteeringOpportunity) {
        opportunities.removeAll { $0.id == opportunity.id }
        saveOpportunities()
    }
    
    func updateOpportunity(_ updatedOpportunity: VolunteeringOpportunity) {
        if let index = opportunities.firstIndex(where: { $0.id == updatedOpportunity.id }) {
            opportunities[index] = updatedOpportunity
            saveOpportunities()
        }
    }
    
    func getOpportunitiesNear(location: CLLocation, radius: Double) -> [VolunteeringOpportunity] {
        return opportunities.filter { opportunity in
            let opportunityLocation = CLLocation(
                latitude: opportunity.latitude,
                longitude: opportunity.longitude
            )
            let distance = location.distance(from: opportunityLocation) / 1609.34 // Convert to miles
            return distance <= radius
        }
    }
    
    func getOpportunitiesByType(_ type: OpportunityType) -> [VolunteeringOpportunity] {
        return opportunities.filter { $0.type == type }
    }
    
    func searchOpportunities(query: String) -> [VolunteeringOpportunity] {
        let lowercaseQuery = query.lowercased()
        return opportunities.filter { opportunity in
            opportunity.title.lowercased().contains(lowercaseQuery) ||
            opportunity.organization.lowercased().contains(lowercaseQuery) ||
            opportunity.description.lowercased().contains(lowercaseQuery) ||
            opportunity.type.rawValue.lowercased().contains(lowercaseQuery)
        }
    }
    
    // MARK: - Persistence
    
    private func loadOpportunities() {
        guard let data = userDefaults.data(forKey: opportunitiesKey) else {
            // Start with empty array if no saved data
            opportunities = []
            return
        }
        
        do {
            opportunities = try JSONDecoder().decode([VolunteeringOpportunity].self, from: data)
        } catch {
            print("Failed to load opportunities: \(error)")
            opportunities = []
        }
    }
    
    private func saveOpportunities() {
        do {
            let data = try JSONEncoder().encode(opportunities)
            userDefaults.set(data, forKey: opportunitiesKey)
        } catch {
            print("Failed to save opportunities: \(error)")
        }
    }
    
    // MARK: - Notifications Helper
    
    func sendNewOpportunityNotification(for opportunity: VolunteeringOpportunity) {
        Task {
            // Implementation can be added here if needed
        }
    }
}
