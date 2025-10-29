import SwiftUI
import CoreLocation

struct FavoritesView: View {
    @Binding var favorites: Set<UUID>
    @State private var selectedCenter: DonationCenter?
    
    // FIXED: Get favorite centers from the actual service instead of sample data
    @StateObject private var donationService = DynamicDonationCenterService.shared
    
    var favoriteCenters: [DonationCenter] {
        // Filter donation centers that are in favorites
        donationService.donationCenters.filter { favorites.contains($0.id) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.backgroundGradient
                    .ignoresSafeArea()
                
                if favoriteCenters.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(favoriteCenters) { center in
                                FavoriteCenterCard(center: center) {
                                    selectedCenter = center
                                } onRemove: {
                                    favorites.remove(center.id)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedCenter) { center in
                DonationCenterDetailView(
                    center: center,
                    isFavorite: favorites.contains(center.id)
                ) { isFav in
                    if isFav {
                        favorites.insert(center.id)
                    } else {
                        favorites.remove(center.id)
                    }
                }
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.slash")
                .font(.system(size: 80))
                .foregroundColor(ColorTheme.secondaryText)
            
            VStack(spacing: 12) {
                Text("No Favorites Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text("Tap the heart icon on donation centers in the map to save them here for easy access.")
                    .font(.body)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    FavoritesFeatureIcon(icon: "map.fill", color: ColorTheme.primaryGreen, text: "Explore Map")
                    FavoritesFeatureIcon(icon: "heart.fill", color: ColorTheme.success, text: "Save Favorites")
                }
                
                HStack(spacing: 16) {
                    FavoritesFeatureIcon(icon: "location.fill", color: ColorTheme.primaryBlue, text: "Find Nearby")
                    FavoritesFeatureIcon(icon: "arrow.3.trianglepath", color: ColorTheme.accent, text: "Recycle & Donate")
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Feature Icon (Scoped to Favorites)
private struct FavoritesFeatureIcon: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Favorite Center Card
struct FavoriteCenterCard: View {
    let center: DonationCenter
    let onTap: () -> Void
    let onRemove: () -> Void
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: center.type.icon)
                            .font(.title2)
                            .foregroundColor(getColorForType(center.type))
                            .frame(width: 40, height: 40)
                            .background(getColorForType(center.type).opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(center.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(ColorTheme.primaryText)
                                .multilineTextAlignment(.leading)
                            
                            Text(center.type.rawValue)
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                        
                        Spacer()
                    }
                    
                    Button(action: onRemove) {
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .foregroundColor(ColorTheme.success)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Address and distance
                HStack {
                    Label(center.address, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if let userLocation = locationManager.location {
                        let distance = center.distanceInMiles(from: userLocation)
                        Text("\(distance, specifier: "%.1f") mi")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(ColorTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ColorTheme.accent.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // Hours
                Label(center.hours, systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
                
                // Accepted items preview
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(center.acceptedItems.prefix(3), id: \.self) { item in
                            Text(item)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(ColorTheme.lightGreen.opacity(0.2))
                                .foregroundColor(ColorTheme.primaryText)
                                .cornerRadius(6)
                        }
                        
                        if center.acceptedItems.count > 3 {
                            Text("+\(center.acceptedItems.count - 3) more")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(ColorTheme.secondaryText.opacity(0.1))
                                .foregroundColor(ColorTheme.secondaryText)
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            .padding(16)
            .background(ColorTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: ColorTheme.shadow, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            locationManager.startLocationUpdates()
        }
    }
    
    private func getColorForType(_ type: CenterType) -> Color {
        switch type {
        case .foodBank:
            return ColorTheme.primaryGreen
        case .homelessShelter:
            return ColorTheme.primaryBlue
        case .recyclingCenter:
            return ColorTheme.accent
        case .compostFacility:
            return ColorTheme.success
        }
    }
}

// MARK: - Preview
#Preview {
    FavoritesView(favorites: .constant(Set<UUID>()))
}
