import Foundation
import UserNotifications
import CoreLocation
import UIKit

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Permission Management
    
    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            await checkAuthorizationStatus()
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }
    
    private func checkAuthorizationStatus() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleNewOpportunityNotification(for opportunity: VolunteeringOpportunity) {
        guard isAuthorized else {
            print("Notifications not authorized")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🤝 New Volunteering Opportunity"
        content.body = "\(opportunity.title) at \(opportunity.organization)"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Add custom data
        content.userInfo = [
            "opportunityId": opportunity.id.uuidString,
            "type": "newOpportunity",
            "organizationName": opportunity.organization
        ]
        
        // Schedule for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "newOpportunity-\(opportunity.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("Scheduled notification for new opportunity: \(opportunity.title)")
            }
        }
    }
    
    func scheduleNearbyOpportunityNotification(for opportunity: VolunteeringOpportunity, distance: Double) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📍 Volunteer Opportunity Nearby"
        content.body = "\(opportunity.title) is \(String(format: "%.1f", distance)) miles away"
        content.sound = .default
        
        content.userInfo = [
            "opportunityId": opportunity.id.uuidString,
            "type": "nearbyOpportunity",
            "distance": distance
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "nearby-\(opportunity.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule nearby notification: \(error)")
            }
        }
    }
    
    func scheduleReminderNotification(for opportunity: VolunteeringOpportunity, reminderDate: Date) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ Volunteering Reminder"
        content.body = "Don't forget: \(opportunity.title) at \(opportunity.organization)"
        content.sound = .default
        
        content.userInfo = [
            "opportunityId": opportunity.id.uuidString,
            "type": "reminder"
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "reminder-\(opportunity.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule reminder notification: \(error)")
            }
        }
    }
    
    func scheduleEventSignUpNotification(eventTitle: String, userName: String) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "👋 New Volunteer Sign-Up"
        content.body = "\(userName) signed up for \(eventTitle)"
        content.sound = .default
        
        content.userInfo = [
            "type": "signUp",
            "eventTitle": eventTitle,
            "userName": userName
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "signUp-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule sign-up notification: \(error)")
            }
        }
    }
    
    // MARK: - Location-Based Notifications
    
    func scheduleLocationBasedNotification(for opportunity: VolunteeringOpportunity, radius: CLLocationDistance = 1609.34) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📍 You're near a volunteering opportunity!"
        content.body = "\(opportunity.title) at \(opportunity.organization)"
        content.sound = .default
        
        content.userInfo = [
            "opportunityId": opportunity.id.uuidString,
            "type": "locationBased"
        ]
        
        let center = CLLocationCoordinate2D(
            latitude: opportunity.latitude,
            longitude: opportunity.longitude
        )
        
        let region = CLCircularRegion(
            center: center,
            radius: radius,
            identifier: "opportunity-\(opportunity.id.uuidString)"
        )
        
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "location-\(opportunity.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        self.center.add(request) { error in
            if let error = error {
                print("Failed to schedule location-based notification: \(error)")
            }
        }
    }
    
    // MARK: - Notification Management
    
    func cancelNotification(withIdentifier identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    func getBadgeCount() async -> Int {
        let deliveredNotifications = await center.deliveredNotifications()
        return deliveredNotifications.count
    }
    
    func clearBadge() {
        Task {
            await MainActor.run {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
    
    // MARK: - Demo Notifications
    
    func sendTestNotification() {
        guard isAuthorized else {
            print("Notifications not authorized for test")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Notification"
        content.body = "Service for Society notifications are working!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule test notification: \(error)")
            } else {
                print("Test notification scheduled successfully")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
 
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {

        completionHandler([.banner, .sound, .badge])
    }
    
  
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
     
        if let type = userInfo["type"] as? String {
            switch type {
            case "newOpportunity", "nearbyOpportunity", "locationBased":
                if let opportunityId = userInfo["opportunityId"] as? String {
                    handleOpportunityNotificationTap(opportunityId: opportunityId)
                }
            case "reminder":
                if let opportunityId = userInfo["opportunityId"] as? String {
                    handleReminderNotificationTap(opportunityId: opportunityId)
                }
            case "signUp":
                handleSignUpNotificationTap(userInfo: userInfo)
            default:
                print("Unknown notification type: \(type)")
            }
        }
        
        completionHandler()
    }
    
    private nonisolated func handleOpportunityNotificationTap(opportunityId: String) {
      
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToOpportunity"),
            object: opportunityId
        )
    }
    
    private nonisolated func handleReminderNotificationTap(opportunityId: String) {
      
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowOpportunityReminder"),
            object: opportunityId
        )
    }
    
    private nonisolated func handleSignUpNotificationTap(userInfo: [AnyHashable: Any]) {
       
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowEventSignUps"),
            object: userInfo
        )
    }
}
