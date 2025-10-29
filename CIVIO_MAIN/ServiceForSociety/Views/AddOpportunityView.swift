import SwiftUI
import CoreLocation
import MapKit

// MARK: - Address Search Manager
// Shared manager for address search functionality
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
        
        // Set region to entire USA for nationwide search
        let usaCenter = CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
        let usaSpan = MKCoordinateSpan(latitudeDelta: 50.0, longitudeDelta: 60.0)
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

// MARK: - Add Opportunity View
// Allows users to create new volunteering opportunities
struct AddOpportunityView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var addressSearchManager = AddressSearchManager()
    @StateObject private var volunteeringService = VolunteeringService.shared
    
    @State private var title: String = ""
    @State private var organization: String = ""
    @State private var selectedType: OpportunityType = .communityOutreach
    @State private var addressSearchText: String = ""
    @State private var description: String = ""
    @State private var selectedDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    @State private var hoursNeeded: String = ""
    @State private var contactPhone: String = ""
    @State private var contactEmail: String = ""
    @State private var requirements: [String] = [""]
    @State private var showingDatePicker = false
    @State private var showingStartTimePicker = false
    @State private var showingEndTimePicker = false
    @State private var showingMapPreview = false
    @State private var showingAddressAlert = false
    @State private var showingSaveSuccess = false
    
    private var isFormValid: Bool {
        let hasTitle = !title.isEmpty
        let hasOrganization = !organization.isEmpty
        let hasValidAddress = addressSearchManager.selectedCoordinate != nil
        let hasDescription = !description.isEmpty
        let hasHours = !hoursNeeded.isEmpty
        
        return hasTitle && hasOrganization && hasValidAddress && hasDescription && hasHours
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.backgroundGradient
                    .ignoresSafeArea()
                
                formScrollView
            }
            .navigationTitle("New Opportunity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarItems
            }
            .sheet(isPresented: $showingDatePicker) {
                datePickerSheet
            }
            .sheet(isPresented: $showingStartTimePicker) {
                startTimePickerSheet
            }
            .sheet(isPresented: $showingEndTimePicker) {
                endTimePickerSheet
            }
            .sheet(isPresented: $showingMapPreview) {
                mapPreviewSheet
            }
            .alert("Invalid Address", isPresented: $showingAddressAlert) {
                Button("OK") { }
            } message: {
                Text("Please select a valid address from the search results.")
            }
            .alert("Success!", isPresented: $showingSaveSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your volunteering opportunity has been created!")
            }
        }
    }
    
    private var formScrollView: some View {
        ScrollView {
            VStack(spacing: 20) {
                basicInformationSection
                addressSection
                dateTimeSection
                descriptionSection
                contactSection
            }
            .padding()
            .padding(.bottom, 100)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(ColorTheme.secondaryText)
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
                if isFormValid {
                    saveOpportunity()
                } else if addressSearchManager.selectedCoordinate == nil {
                    showingAddressAlert = true
                }
            }
            .foregroundColor(isFormValid ? ColorTheme.primaryGreen : ColorTheme.secondaryText)
            .disabled(!isFormValid)
        }
    }
    
    private var basicInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(spacing: 12) {
                FormTextField(
                    title: "Event Name",
                    text: $title,
                    placeholder: "Enter event name"
                )
                .textInputAutocapitalization(.words)
                
                FormTextField(
                    title: "Organization",
                    text: $organization,
                    placeholder: "Enter organization name"
                )
                .textInputAutocapitalization(.words)
                
                eventTypeSelector
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }
    
    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(spacing: 12) {
                addressSearchField
                
                if !addressSearchManager.searchResults.isEmpty {
                    addressSearchResults
                }
                
                if addressSearchManager.selectedCoordinate != nil {
                    selectedAddressView
                }
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }
    
    private var addressSearchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Address")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primaryText)
            
            HStack {
                Image(systemName: "location")
                    .foregroundColor(ColorTheme.primaryGreen)
                
                TextField("Search for address...", text: $addressSearchText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .onChange(of: addressSearchText) { newValue in
                        addressSearchManager.searchAddress(newValue)
                    }
                
                if !addressSearchText.isEmpty {
                    Button(action: {
                        addressSearchText = ""
                        addressSearchManager.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ColorTheme.primaryGreen.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var addressSearchResults: some View {
        VStack(spacing: 0) {
            ForEach(addressSearchManager.searchResults.prefix(5), id: \.self) { (result: MKLocalSearchCompletion) in
                Button(action: {
                    addressSearchManager.selectAddress(result)
                    addressSearchText = result.title
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title)
                            .font(.body)
                            .foregroundColor(ColorTheme.primaryText)
                            .multilineTextAlignment(.leading)
                        
                        Text(result.subtitle)
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(ColorTheme.cardBackground)
                }
                .buttonStyle(PlainButtonStyle())
                
                if result != addressSearchManager.searchResults.prefix(5).last {
                    Divider()
                }
            }
        }
        .background(ColorTheme.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ColorTheme.primaryGreen.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var selectedAddressView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(ColorTheme.success)
                
                Text("Address Selected")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.success)
                
                Spacer()
                
                Button("Preview") {
                    showingMapPreview = true
                }
                .font(.caption)
                .foregroundColor(ColorTheme.primaryGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ColorTheme.primaryGreen.opacity(0.1))
                .cornerRadius(6)
            }
            
            Text(addressSearchManager.selectedAddress)
                .font(.caption)
                .foregroundColor(ColorTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 24)
        }
        .padding()
        .background(ColorTheme.success.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var mapPreviewSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let coordinate = addressSearchManager.selectedCoordinate {
                    Map(coordinateRegion: .constant(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    ), annotationItems: [MapAnnotationItem(coordinate: coordinate)]) { annotation in
                        MapPin(coordinate: annotation.coordinate, tint: .red)
                    }
                    .frame(height: 300)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Location")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text(addressSearchManager.selectedAddress)
                            .font(.body)
                            .foregroundColor(ColorTheme.secondaryText)
                        
                        Text("Latitude: \(coordinate.latitude, specifier: "%.6f")")
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                        
                        Text("Longitude: \(coordinate.longitude, specifier: "%.6f")")
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(ColorTheme.cardBackground)
                    
                    Spacer()
                }
            }
            .navigationTitle("Location Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingMapPreview = false
                    }
                    .foregroundColor(ColorTheme.primaryGreen)
                }
            }
        }
    }
    
    struct MapAnnotationItem: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
    
    private var eventTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Event Type")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primaryText)
            
            Menu {
                ForEach(OpportunityType.allCases, id: \.self) { type in
                    Button(type.rawValue) {
                        selectedType = type
                    }
                }
            } label: {
                eventTypeLabel
            }
        }
    }
    
    private var eventTypeLabel: some View {
        HStack {
            Text(selectedType.rawValue)
                .foregroundColor(ColorTheme.primaryText)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(ColorTheme.secondaryText)
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ColorTheme.primaryGreen.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date & Time")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(spacing: 12) {
                dateSelector
                timeSelectors
                FormTextField(
                    title: "Hours Needed",
                    text: $hoursNeeded,
                    placeholder: "e.g., 2-4 hours"
                )
                .textInputAutocapitalization(.never)
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }
    
    private var dateSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primaryText)
            
            Button {
                showingDatePicker.toggle()
            } label: {
                dateSelectorLabel
            }
        }
    }
    
    private var dateSelectorLabel: some View {
        HStack {
            Text(selectedDate, style: .date)
                .foregroundColor(ColorTheme.primaryText)
            Spacer()
            Image(systemName: "calendar")
                .foregroundColor(ColorTheme.primaryGreen)
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ColorTheme.primaryGreen.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var timeSelectors: some View {
        HStack(spacing: 12) {
            startTimeSelector
            endTimeSelector
        }
    }
    
    private var startTimeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start Time")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primaryText)
            
            Button {
                showingStartTimePicker.toggle()
            } label: {
                timeSelectorLabel(time: startTime)
            }
        }
    }
    
    private var endTimeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("End Time")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primaryText)
            
            Button {
                showingEndTimePicker.toggle()
            } label: {
                timeSelectorLabel(time: endTime)
            }
        }
    }
    
    private func timeSelectorLabel(time: Date) -> some View {
        HStack {
            Text(time, style: .time)
                .foregroundColor(ColorTheme.primaryText)
            Spacer()
            Image(systemName: "clock")
                .foregroundColor(ColorTheme.primaryGreen)
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ColorTheme.primaryGreen.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Description & Details")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            descriptionEditor
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }
    
    private var descriptionEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primaryText)
            
            TextEditor(text: $description)
                .frame(minHeight: 100)
                .padding(8)
                .background(ColorTheme.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorTheme.primaryGreen.opacity(0.3), lineWidth: 1)
                )
                .textInputAutocapitalization(.sentences)
            
            if description.isEmpty {
                Text("Describe what volunteers will be doing...")
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
                    .padding(.leading, 8)
            }
        }
    }
    
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(spacing: 12) {
                FormTextField(
                    title: "Phone Number",
                    text: $contactPhone,
                    placeholder: "Enter phone number"
                )
                .keyboardType(.phonePad)
                .textInputAutocapitalization(.never)
                
                FormTextField(
                    title: "Email",
                    text: $contactEmail,
                    placeholder: "Enter email address"
                )
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            }
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
    }
    
    private var datePickerSheet: some View {
        NavigationView {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingDatePicker = false
                        }
                        .foregroundColor(ColorTheme.primaryGreen)
                    }
                }
        }
    }
    
    private var startTimePickerSheet: some View {
        NavigationView {
            DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .padding()
                .navigationTitle("Start Time")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingStartTimePicker = false
                        }
                        .foregroundColor(ColorTheme.primaryGreen)
                    }
                }
        }
    }
    
    private var endTimePickerSheet: some View {
        NavigationView {
            DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .padding()
                .navigationTitle("End Time")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingEndTimePicker = false
                        }
                        .foregroundColor(ColorTheme.primaryGreen)
                    }
                }
        }
    }
    
    private func saveOpportunity() {
        guard let coordinate = addressSearchManager.selectedCoordinate else {
            showingAddressAlert = true
            return
        }
        
        print("💾 SAVING OPPORTUNITY:")
        print("   Title: \(title)")
        print("   Organization: \(organization)")
        print("   Address: \(addressSearchManager.selectedAddress)")
        print("   Coordinates: \(coordinate.latitude), \(coordinate.longitude)")
        
        let newOpportunity = VolunteeringOpportunity.create(
            title: title,
            organization: organization,
            description: description,
            type: selectedType,
            address: addressSearchManager.selectedAddress,
            coordinate: coordinate,
            timeCommitment: hoursNeeded,
            requirements: requirements.filter { !$0.isEmpty },
            contactEmail: contactEmail.isEmpty ? nil : contactEmail,
            contactPhone: contactPhone.isEmpty ? nil : contactPhone,
            isOngoing: true,
            startDate: selectedDate,
            endDate: endTime > startTime ? endTime : nil
        )
        
        volunteeringService.addOpportunity(newOpportunity)
        
        print("✅ OPPORTUNITY SAVED! Total opportunities: \(volunteeringService.opportunities.count)")
        
        showingSaveSuccess = true
    }
}

// MARK: - Custom Form Text Field Component
struct FormTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primaryText)
            
            TextField(placeholder, text: $text)
                .padding()
                .background(ColorTheme.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorTheme.primaryGreen.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
