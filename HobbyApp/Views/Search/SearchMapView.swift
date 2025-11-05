import SwiftUI
import MapKit
import CoreLocation

struct SearchMapView: View {
    let results: [SearchResult]
    let userLocation: CLLocation?
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207), // Vancouver default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var selectedResult: SearchResult?
    @State private var showingResultDetail = false
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: mapAnnotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    SearchMapPin(
                        annotation: annotation,
                        isSelected: selectedResult?.id == annotation.result.id
                    ) {
                        selectedResult = annotation.result
                        showingResultDetail = true
                    }
                }
            }
            .ignoresSafeArea(.all)
            .onAppear {
                updateRegionForResults()
            }
            .onChange(of: results) { _, _ in
                updateRegionForResults()
            }
            
            // Search Results Count Overlay
            VStack {
                HStack {
                    SearchMapResultsCount(count: results.count)
                    Spacer()
                    SearchMapLocationButton {
                        centerOnUserLocation()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingResultDetail) {
            if let selectedResult = selectedResult {
                SearchResultDetailView(result: selectedResult)
            }
        }
    }
    
    private var mapAnnotations: [SearchMapAnnotation] {
        results.compactMap { result in
            guard let coordinate = getCoordinate(for: result) else { return nil }
            return SearchMapAnnotation(
                id: result.id,
                coordinate: coordinate,
                result: result
            )
        }
    }
    
    private func getCoordinate(for result: SearchResult) -> CLLocationCoordinate2D? {
        switch result {
        case .class(let hobbyClass):
            return CLLocationCoordinate2D(
                latitude: hobbyClass.venue.latitude,
                longitude: hobbyClass.venue.longitude
            )
        case .venue(let venue):
            return CLLocationCoordinate2D(
                latitude: venue.latitude,
                longitude: venue.longitude
            )
        case .instructor:
            // Instructors don't have specific locations
            return nil
        }
    }
    
    private func updateRegionForResults() {
        guard !results.isEmpty else { return }
        
        let coordinates = mapAnnotations.map { $0.coordinate }
        
        if coordinates.isEmpty {
            // Default to user location or Vancouver
            if let userLocation = userLocation {
                region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
            return
        }
        
        // Calculate bounds for all results
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 49.2827
        let maxLat = latitudes.max() ?? 49.2827
        let minLon = longitudes.min() ?? -123.1207
        let maxLon = longitudes.max() ?? -123.1207
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let latDelta = max(maxLat - minLat, 0.01) * 1.2 // Add 20% padding
        let lonDelta = max(maxLon - minLon, 0.01) * 1.2
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
    
    private func centerOnUserLocation() {
        guard let userLocation = userLocation else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
    }
}

// MARK: - Map Annotation Model

struct SearchMapAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let result: SearchResult
}

// MARK: - Map Pin Component

struct SearchMapPin: View {
    let annotation: SearchMapAnnotation
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(annotation.result.typeColor)
                        .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                        .shadow(color: .black.opacity(0.3), radius: isSelected ? 8 : 4, x: 0, y: 2)
                    
                    Image(systemName: annotation.result.typeIcon)
                        .font(.system(size: isSelected ? 20 : 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Pin tail
                Path { path in
                    let width: CGFloat = isSelected ? 50 : 40
                    path.move(to: CGPoint(x: width * 0.5, y: 0))
                    path.addLine(to: CGPoint(x: width * 0.4, y: 8))
                    path.addLine(to: CGPoint(x: width * 0.6, y: 8))
                    path.closeSubpath()
                }
                .fill(annotation.result.typeColor)
                .frame(height: 8)
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Map Overlay Components

struct SearchMapResultsCount: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "map")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(BrandConstants.Colors.primary)
            
            Text("\(count) result\(count == 1 ? "" : "s")")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct SearchMapLocationButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: "location.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(BrandConstants.Colors.primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
        }
    }
}

// MARK: - Search Result Detail View

struct SearchResultDetailView: View {
    let result: SearchResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(BrandConstants.Colors.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: result.typeIcon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(result.typeColor)
                        
                        Text(result.typeLabel)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(result.typeColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(result.typeColor.opacity(0.1))
                    )
                }
                .padding()
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and Subtitle
                        VStack(alignment: .leading, spacing: 8) {
                            Text(result.title)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text(result.subtitle)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Rating and Price
                        HStack {
                            if let rating = result.rating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.yellow)
                                    
                                    Text(String(format: "%.1f", rating))
                                        .font(.system(size: 14, weight: .medium))
                                }
                            }
                            
                            Spacer()
                            
                            if let price = result.price {
                                Text(price == 0 ? "Free" : String(format: "$%.0f", price))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(BrandConstants.Colors.primary)
                            }
                        }
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button {
                                // Navigate to detail view
                                dismiss()
                            } label: {
                                Text("View Details")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(BrandConstants.Colors.primary)
                                    .cornerRadius(8)
                            }
                            
                            Button {
                                // Add to favorites
                            } label: {
                                Image(systemName: "heart")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(BrandConstants.Colors.primary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(BrandConstants.Colors.primary.opacity(0.1))
                                    )
                            }
                            
                            Button {
                                // Share
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(BrandConstants.Colors.primary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(BrandConstants.Colors.primary.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    SearchMapView(
        results: [
            .class(HobbyClass.from(ClassItem.hobbyClassSamples[0])),
            .class(HobbyClass.from(ClassItem.hobbyClassSamples[1]))
        ],
        userLocation: CLLocation(latitude: 49.2827, longitude: -123.1207)
    )
}