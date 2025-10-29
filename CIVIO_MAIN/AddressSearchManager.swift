import Foundation
import SwiftUI
import MapKit
import CoreLocation

class AddressSearchManager: NSObject, ObservableObject {
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var selectedAddress: String = ""
    
    private let completer = MKLocalSearchCompleter()
    private let localSearchRequest = MKLocalSearch.Request()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        
        // FIXED: Set region to entire USA for nationwide search
        // This allows searching for addresses anywhere in the United States
        let usaCenter = CLLocationCoordinate2D(latitude: 35.7915, longitude: -98.5795) // Center of USA
        let usaSpan = MKCoordinateSpan(latitudeDelta: 50.0, longitudeDelta: 60.0) // Cover entire USA
        completer.region = MKCoordinateRegion(center: usaCenter, span: usaSpan)
        
        print("🌎 AddressSearchManager initialized for NATIONWIDE search")
    }
    
    func searchAddress(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        print("🔍 Searching for: \(query)")
        completer.queryFragment = query
    }
    
    func selectAddress(_ completion: MKLocalSearchCompletion) {
        localSearchRequest.naturalLanguageQuery = completion.title + " " + completion.subtitle
        
        // FIXED: Also set the search request region to USA for nationwide results
        let usaCenter = CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
        let usaSpan = MKCoordinateSpan(latitudeDelta: 50.0, longitudeDelta: 60.0)
        localSearchRequest.region = MKCoordinateRegion(center: usaCenter, span: usaSpan)
        
        let search = MKLocalSearch(request: localSearchRequest)
        
        search.start { [weak self] response, error in
            guard let self = self,
                  let response = response,
                  let firstResult = response.mapItems.first else {
                print("❌ Address search failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self.selectedCoordinate = firstResult.placemark.coordinate
                self.selectedAddress = completion.title + " " + completion.subtitle
                self.searchResults = []
                print("✅ Found address: \(self.selectedAddress)")
                print("📍 Coordinates: \(firstResult.placemark.coordinate.latitude), \(firstResult.placemark.coordinate.longitude)")
            }
        }
    }
    
    func clearSearch() {
        searchResults = []
        selectedCoordinate = nil
        selectedAddress = ""
    }
}

extension AddressSearchManager: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results
            print("📋 Found \(completer.results.count) search results")
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("❌ Address search error: \(error.localizedDescription)")
    }
}
