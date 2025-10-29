
import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var favorites: Set<UUID> = []
    @State private var selectedRadius: Double = 25.0
    
    var body: some View {
        TabView {
            // Map Tab
            MapView(
                locationManager: locationManager,
                favorites: $favorites,
                selectedRadius: $selectedRadius
            )
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }
            
            // Volunteering Tab
            VolunteeringView()
                .tabItem {
                    Label("Volunteer", systemImage: "hands.sparkles.fill")
                }
            
            // Favorites Tab
            FavoritesView(favorites: $favorites)
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
        }
        .accentColor(ColorTheme.primaryGreen)
        .onAppear {
            locationManager.requestLocationPermission()
            loadFavorites()
        }
        .onChange(of: favorites) { _ in
            saveFavorites()
        }
    }
    
    // MARK: - Favorites Persistence
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "savedFavorites"),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            favorites = decoded
        }
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: "savedFavorites")
        }
    }
}

#Preview {
    ContentView()
}
