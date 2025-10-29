import SwiftUI
import CoreLocation
import MapKit

struct LocationSearchSheet: View {
    @StateObject private var addressSearchManager = AddressSearchManager()
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search for address, city, or place", text: $searchText)
                        .onChange(of: searchText) { newValue in
                            addressSearchManager.searchAddress(newValue)
                        }
                        .textFieldStyle(PlainTextFieldStyle())
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            addressSearchManager.clearSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if !addressSearchManager.searchResults.isEmpty {
                    List(addressSearchManager.searchResults, id: \.self) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.title)
                                .font(.body)
                            if !result.subtitle.isEmpty {
                                Text(result.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            addressSearchManager.selectAddress(result)
                        }
                    }
                }
                
                if let coordinate = addressSearchManager.selectedCoordinate {
                    Button(action: {
                        print("Setting selected location: \(coordinate)")
                        selectedLocation = coordinate
                        dismiss()
                    }) {
                        Text("Use \(addressSearchManager.selectedAddress)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
