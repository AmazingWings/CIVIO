import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    @Published var userState: String?
    @Published var userCity: String?
    
    private var hasPerformedInitialLocationUpdate = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func isLocationInRadius(_ centerLocation: CLLocation, radius: Double) -> Bool {
        guard let userLocation = location else { return false }
        let distance = userLocation.distance(from: centerLocation) / 1609.34 // Convert to miles
        return distance <= radius
    }
    
    // NEW METHODS FOR SEARCH FUNCTIONALITY
    func updateLocation(to coordinate: CLLocationCoordinate2D) {
        let newLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        self.location = newLocation
        
        // Update city and state for the new location
        reverseGeocodeLocation(newLocation)
    }
    
    func searchAndUpdateLocation(to coordinate: CLLocationCoordinate2D) {
        updateLocation(to: coordinate)
    }
    
    func resetToUserLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        locationManager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        locationError = nil
        
        // Perform reverse geocoding to get state and city (only on first location update)
        if !hasPerformedInitialLocationUpdate {
            hasPerformedInitialLocationUpdate = true
            reverseGeocodeLocation(location)
        }
    }
    
    private func reverseGeocodeLocation(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    self?.userState = placemark.administrativeArea
                    self?.userCity = placemark.locality
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            stopLocationUpdates()
            location = nil
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            break
        }
    }
}
