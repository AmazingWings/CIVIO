import SwiftUI
import CoreLocation
import MapKit

struct VolunteeringView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var volunteeringService = VolunteeringService.shared
    @StateObject private var searchService = SearchService()
    @State private var selectedRadius: Double = 25.0
    @State private var selectedTypes: Set<OpportunityType> = Set(OpportunityType.allCases)
    @State private var selectedOpportunity: VolunteeringOpportunity?
    @State private var showingFilters = false
    @State private var showingAddOpportunity = false
    @State private var searchText: String = ""
    @State private var isSearchingMaps = false
    @State private var searchResults: [VolunteeringOpportunity] = []
    @State private var favoriteOpportunities: Set<UUID> = []
    
    // NEW SEARCH FUNCTIONALITY
    @State private var selectedSearchLocation: CLLocationCoordinate2D?
    @State private var showingSearchSheet = false
    @State private var currentLocationName: String = "Current Location"
    
    private let radiusOptions: [Double] = [5, 10, 15, 25, 50, 100]
    
    var filteredOpportunities: [VolunteeringOpportunity] {
        // Combine user-created opportunities with search results
        let allOpportunities = volunteeringService.opportunities + searchResults
        
        let typeFiltered = filterByType(from: allOpportunities)
        let searchFiltered = applySearchFilter(to: typeFiltered)
        let distanceFiltered = applyDistanceFilter(to: searchFiltered)
        let sortedResults = applySorting(to: distanceFiltered)
        return sortedResults
    }
    
    private func filterByType(from opportunities: [VolunteeringOpportunity]) -> [VolunteeringOpportunity] {
        return opportunities.filter { opportunity in
            selectedTypes.contains(opportunity.type)
        }
    }
    
    private func applySearchFilter(to opportunities: [VolunteeringOpportunity]) -> [VolunteeringOpportunity] {
        guard !searchText.isEmpty else { return opportunities }
        
        let searchLower = searchText.lowercased()
        return opportunities.filter { opportunity in
            matchesSearchTerm(opportunity: opportunity, searchTerm: searchLower)
        }
    }
    
    private func matchesSearchTerm(opportunity: VolunteeringOpportunity, searchTerm: String) -> Bool {
        let titleMatch = opportunity.title.lowercased().contains(searchTerm)
        let orgMatch = opportunity.organization.lowercased().contains(searchTerm)
        let descMatch = opportunity.description.lowercased().contains(searchTerm)
        let typeMatch = opportunity.type.rawValue.lowercased().contains(searchTerm)
        return titleMatch || orgMatch || descMatch || typeMatch
    }
    
    private func applyDistanceFilter(to opportunities: [VolunteeringOpportunity]) -> [VolunteeringOpportunity] {
        let shouldApplyDistanceFilter = searchText.isEmpty && selectedRadius < 100
        guard shouldApplyDistanceFilter else { return opportunities }
        
        return opportunities.filter { opportunity in
            let distance = opportunity.distanceInMiles(from: locationManager.location)
            return distance <= selectedRadius
        }
    }
    
    private func applySorting(to opportunities: [VolunteeringOpportunity]) -> [VolunteeringOpportunity] {
        let hasLocationAndNotSearching = locationManager.location != nil && searchText.isEmpty
        
        if hasLocationAndNotSearching {
            return sortByDistance(opportunities, from: locationManager.location!)
        } else {
            return opportunities.sorted { $0.title < $1.title }
        }
    }
    
    private func sortByDistance(_ opportunities: [VolunteeringOpportunity], from userLocation: CLLocation) -> [VolunteeringOpportunity] {
        return opportunities.sorted { first, second in
            let firstDistance = first.distanceInMiles(from: userLocation)
            let secondDistance = second.distanceInMiles(from: userLocation)
            return firstDistance < secondDistance
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBarView
                mainContentView
            }
            .navigationTitle("Volunteer")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                locationManager.requestLocationPermission()
                loadFavoriteOpportunities()
            }
            .onChange(of: favoriteOpportunities) { _ in
                saveFavoriteOpportunities()
            }
            .sheet(item: $selectedOpportunity) { opportunity in
                VolunteeringDetailView(
                    opportunity: opportunity,
                    isFavorite: favoriteOpportunities.contains(opportunity.id)
                ) { isFav in
                    if isFav {
                        favoriteOpportunities.insert(opportunity.id)
                    } else {
                        favoriteOpportunities.remove(opportunity.id)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                VolunteeringFiltersView(selectedTypes: $selectedTypes)
            }
            .sheet(isPresented: $showingAddOpportunity) {
                AddOpportunityView()
            }
            .sheet(isPresented: $showingSearchSheet) {
                LocationSearchSheet(selectedLocation: $selectedSearchLocation)
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("LocationSelected"))) { notification in
                if let coordinate = notification.object as? CLLocationCoordinate2D {
                    selectedSearchLocation = coordinate
                    locationManager.searchAndUpdateLocation(to: coordinate)
                    updateLocationName(for: coordinate)
                    showingSearchSheet = false
                }
            }
        }
    }
    
    private var searchBarView: some View {
        HStack(spacing: 12) {
            searchTextField
            searchButton
            clearButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var searchTextField: some View {
        HStack {
            if isSearchingMaps {
                ProgressView()
                    .scaleEffect(0.8)
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
            }
            
            TextField("Search events (e.g., food drive)", text: $searchText)
                .font(.system(size: 16))
                .onSubmit {
                    performSearch()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var searchButton: some View {
        Button("Search") {
            performSearch()
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.green)
        .cornerRadius(12)
        .disabled(isSearchingMaps)
    }
    
    @ViewBuilder
    private var clearButton: some View {
        if !searchText.isEmpty {
            Button("Clear") {
                searchText = ""
                searchResults = []
            }
            .font(.system(size: 14))
            .foregroundColor(.blue)
        }
    }
    
    private var mainContentView: some View {
        ZStack {
            ColorTheme.backgroundGradient
                .ignoresSafeArea()
            
            if filteredOpportunities.isEmpty {
                EmptyVolunteeringView()
            } else {
                opportunitiesScrollView
            }
            
            floatingActionButton
        }
    }
    
    private var opportunitiesScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                controlsAndStatsView
                opportunityCards
            }
            .padding(.bottom, 100)
        }
    }
    
    private var controlsAndStatsView: some View {
        VStack(spacing: 16) {
            controlsRow
            statsRow
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var controlsRow: some View {
        HStack {
            // Current location display and search
            VStack(alignment: .leading, spacing: 4) {
                Text("Location")
                    .font(.caption)
                    .foregroundColor(ColorTheme.primaryText)
                
                HStack(spacing: 8) {
                    Text(currentLocationName)
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .lineLimit(1)
                        .frame(maxWidth: 100)
                    
                    Button {
                        showingSearchSheet = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundColor(ColorTheme.accent)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ColorTheme.cardBackground)
            .cornerRadius(8)
            
            Spacer()
            
            radiusSelector
            filtersButton
        }
    }
    
    private var radiusSelector: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Search Radius")
                .font(.caption)
                .foregroundColor(ColorTheme.primaryText)
            
            radiusMenu
        }
    }
    
    private var radiusMenu: some View {
        Menu {
            ForEach(radiusOptions, id: \.self) { radius in
                Button("\(Int(radius)) miles") {
                    selectedRadius = radius
                }
            }
        } label: {
            radiusLabel
        }
        .opacity(searchText.isEmpty ? 1.0 : 0.5)
        .disabled(!searchText.isEmpty)
    }
    
    private var radiusLabel: some View {
        HStack {
            Text("\(Int(selectedRadius)) mi")
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
            Image(systemName: "chevron.down")
                .font(.caption)
        }
        .foregroundColor(ColorTheme.primaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ColorTheme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ColorTheme.primaryGreen, lineWidth: 1)
        )
        .cornerRadius(8)
    }
    
    private var filtersButton: some View {
        Button {
            showingFilters.toggle()
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.title2)
                .foregroundColor(ColorTheme.primaryGreen)
        }
    }
    
    private var statsRow: some View {
        HStack(spacing: 20) {
            StatBox(title: "Available", value: "\(filteredOpportunities.count)", icon: "hands.sparkles.fill")
            StatBox(title: "Ongoing", value: "\(getOngoingCount())", icon: "clock.fill")
            additionalStatBox
        }
    }
    
    private func getOngoingCount() -> String {
        let count = filteredOpportunities.filter { $0.isOngoing }.count
        return "\(count)"
    }
    
    @ViewBuilder
    private var additionalStatBox: some View {
        if let userLocation = locationManager.location, searchText.isEmpty {
            let nearbyCount = getNearbyCount(userLocation: userLocation)
            StatBox(title: "Nearby", value: "\(nearbyCount)", icon: "location.fill")
        } else if !searchText.isEmpty {
            StatBox(title: "Found", value: "\(filteredOpportunities.count)", icon: "magnifyingglass")
        } else if !searchResults.isEmpty {
            StatBox(title: "Maps", value: "\(searchResults.count)", icon: "map.fill")
        }
    }
    
    private func getNearbyCount(userLocation: CLLocation) -> Int {
        return filteredOpportunities.filter { opportunity in
            opportunity.distanceInMiles(from: userLocation) <= 10
        }.count
    }
    
    private var opportunityCards: some View {
        ForEach(filteredOpportunities) { opportunity in
            VolunteeringCard(opportunity: opportunity, userLocation: locationManager.location) {
                selectedOpportunity = opportunity
            }
        }
    }
    
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button {
                    showingAddOpportunity = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(ColorTheme.primaryGreen)
                        .clipShape(Circle())
                        .shadow(color: ColorTheme.shadow.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
    }
    
    // Helper function to update location name display
    private func updateLocationName(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    var components: [String] = []
                    if let city = placemark.locality {
                        components.append(city)
                    }
                    if let state = placemark.administrativeArea {
                        components.append(state)
                    }
                    self.currentLocationName = components.isEmpty ? "Selected Location" : components.joined(separator: ", ")
                } else {
                    self.currentLocationName = "Selected Location"
                }
            }
        }
    }
    
    // Enhanced search functionality using Apple Maps
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearchingMaps = true
        
        Task {
            let results = await searchService.searchVolunteeringOpportunities(
                searchText,
                near: locationManager.location
            )
            
            await MainActor.run {
                searchResults = results
                isSearchingMaps = false
            }
        }
    }
    
    // Favorites persistence
    private func loadFavoriteOpportunities() {
        if let data = UserDefaults.standard.data(forKey: "favoriteOpportunities"),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            favoriteOpportunities = decoded
        }
    }
    
    private func saveFavoriteOpportunities() {
        if let data = try? JSONEncoder().encode(favoriteOpportunities) {
            UserDefaults.standard.set(data, forKey: "favoriteOpportunities")
        }
    }
}

// MARK: - Supporting Views

struct EmptyVolunteeringView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hands.sparkles")
                .font(.system(size: 80))
                .foregroundColor(ColorTheme.secondaryText)
            
            emptyStateText
            featureIcons
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateText: some View {
        VStack(spacing: 12) {
            Text("No Opportunities Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.primaryText)
            
            Text("Try expanding your search radius or changing your location filters to find volunteer opportunities near you.")
                .font(.body)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var featureIcons: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                FeatureIcon(icon: "hands.sparkles.fill", color: ColorTheme.primaryGreen, text: "Food Service")
                FeatureIcon(icon: "heart.circle.fill", color: ColorTheme.primaryBlue, text: "Shelter Support")
            }
            
            HStack(spacing: 16) {
                FeatureIcon(icon: "leaf.arrow.circlepath", color: ColorTheme.success, text: "Environmental")
                FeatureIcon(icon: "person.3.fill", color: ColorTheme.accent, text: "Community")
            }
        }
        .padding(.horizontal, 20)
    }
}

struct FeatureIcon: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(ColorTheme.cardBackground)
        .cornerRadius(8)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(ColorTheme.primaryGreen)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(ColorTheme.cardBackground)
        .cornerRadius(8)
    }
}

struct VolunteeringCard: View {
    let opportunity: VolunteeringOpportunity
    let userLocation: CLLocation?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader
                organizationInfo
                descriptionText
                footerInfo
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(12)
            .shadow(color: ColorTheme.shadow, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
    
    private var cardHeader: some View {
        HStack {
            HStack(spacing: 12) {
                opportunityIcon
                opportunityTitleInfo
                Spacer()
            }
            
            if opportunity.isOngoing {
                ongoingIndicator
            }
        }
    }
    
    private var opportunityIcon: some View {
        Image(systemName: opportunity.type.icon)
            .font(.title2)
            .foregroundColor(getColorForOpportunityType(opportunity.type))
            .frame(width: 40, height: 40)
            .background(getColorForOpportunityType(opportunity.type).opacity(0.1))
            .clipShape(Circle())
    }
    
    private var opportunityTitleInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(opportunity.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.primaryText)
                .multilineTextAlignment(.leading)
            
            Text(opportunity.type.rawValue)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
        }
    }
    
    private var ongoingIndicator: some View {
        Image(systemName: "clock.fill")
            .font(.caption)
            .foregroundColor(ColorTheme.success)
            .padding(4)
            .background(ColorTheme.success.opacity(0.1))
            .clipShape(Circle())
    }
    
    private var organizationInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(opportunity.organization)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primaryGreen)
            
            HStack {
                Label(opportunity.address, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
                    .lineLimit(2)
                
                Spacer()
                
                distanceLabel
            }
        }
    }
    
    @ViewBuilder
    private var distanceLabel: some View {
        if let userLocation = userLocation {
            let distance = opportunity.distanceInMiles(from: userLocation)
            if distance != .infinity {
                Text("\(distance, specifier: "%.1f") mi")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ColorTheme.accent.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }
    
    private var descriptionText: some View {
        Text(opportunity.description)
            .font(.caption)
            .foregroundColor(ColorTheme.primaryText)
            .lineLimit(2)
    }
    
    private var footerInfo: some View {
        HStack {
            Label(opportunity.timeCommitment, systemImage: "clock")
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
            
            Spacer()
            
            if opportunity.requirements.count > 0 {
                Text("\(opportunity.requirements.count) requirements")
                    .font(.caption2)
                    .foregroundColor(ColorTheme.secondaryText)
            }
        }
    }
    
    private func getColorForOpportunityType(_ type: OpportunityType) -> Color {
        switch type {
        case .foodService:
            return ColorTheme.primaryGreen
        case .shelterSupport:
            return ColorTheme.primaryBlue
        case .environmentalCleanup:
            return ColorTheme.success
        case .communityOutreach:
            return ColorTheme.accent
        case .education:
            return .orange
        case .elderCare:
            return ColorTheme.lightGreen
        }
    }
}

struct VolunteeringDetailView: View {
    let opportunity: VolunteeringOpportunity
    let isFavorite: Bool
    let onFavoriteToggle: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    detailsSection
                    requirementsSection
                    mapSection
                }
                .padding()
            }
            .background(ColorTheme.backgroundGradient)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.primaryGreen)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: opportunity.type.icon)
                    .font(.title)
                    .foregroundColor(getColorForOpportunityType(opportunity.type))
                
                VStack(alignment: .leading) {
                    Text(opportunity.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text(opportunity.organization)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.primaryGreen)
                }
                
                Spacer()
                
                Button {
                    onFavoriteToggle(!isFavorite)
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(isFavorite ? ColorTheme.success : ColorTheme.secondaryText)
                }
                
                if opportunity.isOngoing {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(ColorTheme.success)
                }
            }
            
            Text(opportunity.description)
                .font(.body)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            Label(opportunity.address, systemImage: "location.fill")
                .foregroundColor(ColorTheme.secondaryText)
            
            Label(opportunity.timeCommitment, systemImage: "clock.fill")
                .foregroundColor(ColorTheme.secondaryText)
            
            if let contactPhone = opportunity.contactPhone {
                Label(contactPhone, systemImage: "phone.fill")
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            if let contactEmail = opportunity.contactEmail {
                Label(contactEmail, systemImage: "envelope.fill")
                    .foregroundColor(ColorTheme.accent)
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var requirementsSection: some View {
        if !opportunity.requirements.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Requirements")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                ForEach(opportunity.requirements, id: \.self) { requirement in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ColorTheme.success)
                        Text(requirement)
                            .foregroundColor(ColorTheme.primaryText)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            Map(coordinateRegion: .constant(
                MKCoordinateRegion(
                    center: opportunity.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            ), annotationItems: [DetailMapAnnotation(coordinate: opportunity.coordinate)]) { annotation in
                MapPin(coordinate: annotation.coordinate, tint: .red)
            }
            .frame(height: 200)
            .cornerRadius(8)
            .disabled(true)
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }
    
    struct DetailMapAnnotation: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
    
    private func getColorForOpportunityType(_ type: OpportunityType) -> Color {
        switch type {
        case .foodService:
            return ColorTheme.primaryGreen
        case .shelterSupport:
            return ColorTheme.primaryBlue
        case .environmentalCleanup:
            return ColorTheme.success
        case .communityOutreach:
            return ColorTheme.accent
        case .education:
            return .orange
        case .elderCare:
            return ColorTheme.lightGreen
        }
    }
}

struct VolunteeringFiltersView: View {
    @Binding var selectedTypes: Set<OpportunityType>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Filter by Type")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primaryText)
                    .padding(.top)
                
                filterGrid
                
                Spacer()
                
                doneButton
            }
            .background(ColorTheme.backgroundGradient)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var filterGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(OpportunityType.allCases, id: \.self) { type in
                VolunteeringFilterCard(
                    type: type,
                    isSelected: selectedTypes.contains(type)
                ) {
                    toggleTypeSelection(type)
                }
            }
        }
        .padding()
    }
    
    private var doneButton: some View {
        Button("Done") {
            dismiss()
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(ColorTheme.primaryGreen)
        .cornerRadius(12)
        .padding()
    }
    
    private func toggleTypeSelection(_ type: OpportunityType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }
}

struct VolunteeringFilterCard: View {
    let type: OpportunityType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : getColorForOpportunityType(type))
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : ColorTheme.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(isSelected ? getColorForOpportunityType(type) : ColorTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(getColorForOpportunityType(type), lineWidth: isSelected ? 0 : 2)
            )
            .cornerRadius(12)
            .shadow(color: ColorTheme.shadow, radius: isSelected ? 5 : 2, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
    
    private func getColorForOpportunityType(_ type: OpportunityType) -> Color {
        switch type {
        case .foodService:
            return ColorTheme.primaryGreen
        case .shelterSupport:
            return ColorTheme.primaryBlue
        case .environmentalCleanup:
            return ColorTheme.success
        case .communityOutreach:
            return ColorTheme.accent
        case .education:
            return .orange
        case .elderCare:
            return ColorTheme.lightGreen
        }
    }
}

#Preview {
    VolunteeringView()
}
