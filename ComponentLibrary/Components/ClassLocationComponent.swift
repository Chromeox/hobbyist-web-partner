import MapKit
import SwiftUI

// MARK: - Refactored Class Location Component

struct ClassLocationComponent: View, DataDisplayComponent {
    typealias Configuration = ClassLocationConfiguration
    typealias DataType = LocationData

    // MARK: - Properties

    let configuration: ClassLocationConfiguration
    let data: LocationData
    let isLoading: Bool
    let errorState: String?
    let onDirectionsTap: ((LocationData) -> Void)?
    let onCallTap: ((String) -> Void)?

    // MARK: - State

    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    // MARK: - Initializer

    init(
        locationData: LocationData,
        isLoading: Bool = false,
        errorState: String? = nil,
        onDirectionsTap: ((LocationData) -> Void)? = nil,
        onCallTap: ((String) -> Void)? = nil,
        configuration: ClassLocationConfiguration = ClassLocationConfiguration()
    ) {
        data = locationData
        self.isLoading = isLoading
        self.errorState = errorState
        self.onDirectionsTap = onDirectionsTap
        self.onCallTap = onCallTap
        self.configuration = configuration
    }

    // MARK: - Body

    var body: some View {
        buildContent()
    }

    @ViewBuilder
    func buildContent() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            LocationHeader(
                locationData: data,
                configuration: configuration
            )

            if isLoading {
                LocationLoadingView()
            } else if let errorState = errorState {
                LocationErrorView(message: errorState)
            } else {
                LocationContent(
                    locationData: data,
                    mapRegion: $mapRegion,
                    onDirectionsTap: onDirectionsTap,
                    onCallTap: onCallTap,
                    configuration: configuration
                )
            }
        }
        .onAppear {
            updateMapRegion()
        }
        .componentStyle(configuration)
    }

    private func updateMapRegion() {
        mapRegion = MKCoordinateRegion(
            center: data.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
}

// MARK: - Location Header Sub-Component

struct LocationHeader: View {
    let locationData: LocationData
    let configuration: ClassLocationConfiguration

    var body: some View {
        ModularHeader(
            title: "Location",
            subtitle: locationData.venue.name,
            headerStyle: .medium
        ) {
            AnyView(
                HStack(spacing: 12) {
                    if let phone = locationData.venue.phone {
                        Button(action: { /* Call action */ }) {
                            Image(systemName: "phone")
                                .foregroundColor(.accentColor)
                        }
                    }

                    Button(action: { /* Share action */ }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.accentColor)
                    }
                }
            )
        }
    }
}

// MARK: - Location Content Sub-Component

struct LocationContent: View {
    let locationData: LocationData
    @Binding var mapRegion: MKCoordinateRegion
    let onDirectionsTap: ((LocationData) -> Void)?
    let onCallTap: ((String) -> Void)?
    let configuration: ClassLocationConfiguration

    var body: some View {
        VStack(spacing: 16) {
            if configuration.showMap {
                LocationMapSection(
                    locationData: locationData,
                    mapRegion: $mapRegion,
                    configuration: configuration
                )
            }

            LocationDetailsSection(
                locationData: locationData,
                onDirectionsTap: onDirectionsTap,
                onCallTap: onCallTap,
                configuration: configuration
            )

            if configuration.showAmenities {
                LocationAmenitiesSection(
                    amenities: locationData.venue.amenities,
                    configuration: configuration
                )
            }

            if configuration.showNearbyTransport {
                NearbyTransportSection(
                    transportOptions: locationData.nearbyTransport,
                    configuration: configuration
                )
            }
        }
    }
}

// MARK: - Location Map Section Sub-Component

struct LocationMapSection: View {
    let locationData: LocationData
    @Binding var mapRegion: MKCoordinateRegion
    let configuration: ClassLocationConfiguration

    @State private var selectedAnnotation: LocationAnnotation?

    var body: some View {
        VStack(spacing: 12) {
            InteractiveLocationMap(
                region: $mapRegion,
                locationData: locationData,
                selectedAnnotation: $selectedAnnotation,
                configuration: configuration
            )
            .frame(height: configuration.mapHeight)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.gray.opacity(0.3), lineWidth: 1)
            )

            MapControls(
                onZoomIn: { adjustZoom(factor: 0.5) },
                onZoomOut: { adjustZoom(factor: 2.0) },
                onRecenter: { recenterMap() }
            )
        }
    }

    private func adjustZoom(factor: Double) {
        withAnimation(.easeInOut(duration: 0.3)) {
            mapRegion.span = MKCoordinateSpan(
                latitudeDelta: mapRegion.span.latitudeDelta * factor,
                longitudeDelta: mapRegion.span.longitudeDelta * factor
            )
        }
    }

    private func recenterMap() {
        withAnimation(.easeInOut(duration: 0.5)) {
            mapRegion.center = locationData.coordinate
        }
    }
}

// MARK: - Interactive Location Map Sub-Component

struct InteractiveLocationMap: View {
    @Binding var region: MKCoordinateRegion
    let locationData: LocationData
    @Binding var selectedAnnotation: LocationAnnotation?
    let configuration: ClassLocationConfiguration

    var body: some View {
        Map(coordinateRegion: $region,
            annotationItems: [LocationAnnotation(locationData: locationData)])
        { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                LocationPin(
                    annotation: annotation,
                    isSelected: selectedAnnotation?.id == annotation.id,
                    onTap: { selectedAnnotation = annotation }
                )
            }
        }
        .disabled(!configuration.allowMapInteraction)
    }
}

// MARK: - Location Pin Sub-Component

struct LocationPin: View {
    let annotation: LocationAnnotation
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(.accentColor)
                        .frame(width: isSelected ? 24 : 20, height: isSelected ? 24 : 20)

                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                }

                Image(systemName: "arrowtriangle.down.fill")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
                    .offset(y: -2)
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Map Controls Sub-Component

struct MapControls: View {
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onRecenter: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Spacer()

            VStack(spacing: 8) {
                MapControlButton(icon: "plus", action: onZoomIn)
                MapControlButton(icon: "minus", action: onZoomOut)
                MapControlButton(icon: "location", action: onRecenter)
            }
            .padding(8)
            .background(.background)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Map Control Button Sub-Component

struct MapControlButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 28, height: 28)
                .background(.background)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Location Details Section Sub-Component

struct LocationDetailsSection: View {
    let locationData: LocationData
    let onDirectionsTap: ((LocationData) -> Void)?
    let onCallTap: ((String) -> Void)?
    let configuration: ClassLocationConfiguration

    var body: some View {
        VStack(spacing: 16) {
            VenueInfoCard(
                venue: locationData.venue,
                onCallTap: onCallTap,
                configuration: configuration
            )

            AddressCard(
                address: locationData.address,
                onDirectionsTap: { onDirectionsTap?(locationData) },
                configuration: configuration
            )

            if configuration.showOperatingHours {
                OperatingHoursCard(
                    operatingHours: locationData.venue.operatingHours,
                    configuration: configuration
                )
            }
        }
    }
}

// MARK: - Venue Info Card Sub-Component

struct VenueInfoCard: View {
    let venue: VenueData
    let onCallTap: ((String) -> Void)?
    let configuration: ClassLocationConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(venue.name)
                        .font(.headline)
                        .fontWeight(.semibold)

                    if let description = venue.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                VenueRating(rating: venue.rating, reviewCount: venue.reviewCount)
            }

            VenueActions(
                venue: venue,
                onCallTap: onCallTap,
                configuration: configuration
            )
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Venue Rating Sub-Component

struct VenueRating: View {
    let rating: Double
    let reviewCount: Int

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)

                Text(String(format: "%.1f", rating))
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Text("\(reviewCount) reviews")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Venue Actions Sub-Component

struct VenueActions: View {
    let venue: VenueData
    let onCallTap: ((String) -> Void)?
    let configuration: ClassLocationConfiguration

    var body: some View {
        HStack(spacing: 16) {
            if let phone = venue.phone {
                ActionButton(
                    title: "Call",
                    icon: "phone",
                    action: { onCallTap?(phone) }
                )
            }

            if let website = venue.website {
                ActionButton(
                    title: "Website",
                    icon: "globe",
                    action: { /* Open website */ }
                )
            }

            ActionButton(
                title: "Share",
                icon: "square.and.arrow.up",
                action: { /* Share venue */ }
            )

            Spacer()
        }
    }
}

// MARK: - Action Button Sub-Component

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Address Card Sub-Component

struct AddressCard: View {
    let address: AddressData
    let onDirectionsTap: (() -> Void)?
    let configuration: ClassLocationConfiguration

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "location")
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("Address")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(address.formattedAddress)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let city = address.city, let state = address.state {
                    Text("\(city), \(state) \(address.zipCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button("Directions") {
                onDirectionsTap?()
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Operating Hours Card Sub-Component

struct OperatingHoursCard: View {
    let operatingHours: [DayOfWeek: TimeRange]
    let configuration: ClassLocationConfiguration

    private var currentDay: DayOfWeek {
        DayOfWeek(rawValue: Calendar.current.component(.weekday, from: Date()) - 1) ?? .sunday
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Operating Hours")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    OperatingHoursRow(
                        day: day,
                        timeRange: operatingHours[day],
                        isToday: day == currentDay
                    )
                }
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Operating Hours Row Sub-Component

struct OperatingHoursRow: View {
    let day: DayOfWeek
    let timeRange: TimeRange?
    let isToday: Bool

    var body: some View {
        HStack {
            Text(day.displayName)
                .font(.subheadline)
                .fontWeight(isToday ? .semibold : .regular)
                .foregroundColor(isToday ? .accentColor : .primary)

            Spacer()

            if let timeRange = timeRange {
                Text(timeRange.displayString)
                    .font(.subheadline)
                    .fontWeight(isToday ? .semibold : .regular)
                    .foregroundColor(isToday ? .accentColor : .secondary)
            } else {
                Text("Closed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Location Amenities Section Sub-Component

struct LocationAmenitiesSection: View {
    let amenities: [AmenityType]
    let configuration: ClassLocationConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amenities")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(amenities, id: \.self) { amenity in
                    AmenityItem(amenity: amenity)
                }
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Amenity Item Sub-Component

struct AmenityItem: View {
    let amenity: AmenityType

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: amenity.iconName)
                .font(.title2)
                .foregroundColor(.accentColor)

            Text(amenity.displayName)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Nearby Transport Section Sub-Component

struct NearbyTransportSection: View {
    let transportOptions: [TransportOption]
    let configuration: ClassLocationConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Getting There")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(transportOptions, id: \.id) { option in
                    TransportOptionRow(option: option)
                }
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Transport Option Row Sub-Component

struct TransportOptionRow: View {
    let option: TransportOption

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: option.type.iconName)
                .font(.title3)
                .foregroundColor(option.type.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(option.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(option.distance)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(option.walkingTime) walk")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Loading and Error Views

struct LocationLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.3))
                .frame(height: 200)

            VStack(spacing: 12) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray.opacity(0.3))
                            .frame(width: 24, height: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.gray.opacity(0.3))
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(.gray.opacity(0.3))
                                .frame(height: 16)
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .shimmering()
    }
}

struct LocationErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Unable to Load Location")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
    }
}

// MARK: - Data Models

struct LocationData: Identifiable {
    let id = UUID()
    let venue: VenueData
    let address: AddressData
    let coordinate: CLLocationCoordinate2D
    let nearbyTransport: [TransportOption]
}

struct VenueData {
    let name: String
    let description: String?
    let phone: String?
    let website: URL?
    let rating: Double
    let reviewCount: Int
    let amenities: [AmenityType]
    let operatingHours: [DayOfWeek: TimeRange]
}

struct AddressData {
    let street: String
    let city: String?
    let state: String?
    let zipCode: String

    var formattedAddress: String {
        return street
    }
}

struct LocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String

    init(locationData: LocationData) {
        coordinate = locationData.coordinate
        title = locationData.venue.name
    }
}

enum DayOfWeek: Int, CaseIterable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6

    var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

struct TimeRange {
    let open: Date
    let close: Date

    var displayString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: open)) - \(formatter.string(from: close))"
    }
}

enum AmenityType: CaseIterable {
    case parking
    case wifi
    case showers
    case lockers
    case towels
    case waterBottles
    case airConditioning
    case music
    case mirrors

    var displayName: String {
        switch self {
        case .parking: return "Parking"
        case .wifi: return "Wi-Fi"
        case .showers: return "Showers"
        case .lockers: return "Lockers"
        case .towels: return "Towels"
        case .waterBottles: return "Water"
        case .airConditioning: return "A/C"
        case .music: return "Music"
        case .mirrors: return "Mirrors"
        }
    }

    var iconName: String {
        switch self {
        case .parking: return "car"
        case .wifi: return "wifi"
        case .showers: return "shower"
        case .lockers: return "locker"
        case .towels: return "towel"
        case .waterBottles: return "drop"
        case .airConditioning: return "snow"
        case .music: return "music.note"
        case .mirrors: return "mirror"
        }
    }
}

enum TransportType {
    case subway
    case bus
    case parking
    case bike

    var iconName: String {
        switch self {
        case .subway: return "tram"
        case .bus: return "bus"
        case .parking: return "car"
        case .bike: return "bicycle"
        }
    }

    var color: Color {
        switch self {
        case .subway: return .blue
        case .bus: return .green
        case .parking: return .orange
        case .bike: return .purple
        }
    }
}

struct TransportOption: Identifiable {
    let id = UUID()
    let type: TransportType
    let name: String
    let distance: String
    let walkingTime: String
}

// MARK: - Configuration Objects

struct ClassLocationConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double
    let showMap: Bool
    let mapHeight: CGFloat
    let allowMapInteraction: Bool
    let showAmenities: Bool
    let showOperatingHours: Bool
    let showNearbyTransport: Bool

    init(
        isAccessibilityEnabled: Bool = true,
        animationDuration: Double = 0.3,
        showMap: Bool = true,
        mapHeight: CGFloat = 200,
        allowMapInteraction: Bool = true,
        showAmenities: Bool = true,
        showOperatingHours: Bool = true,
        showNearbyTransport: Bool = true
    ) {
        self.isAccessibilityEnabled = isAccessibilityEnabled
        self.animationDuration = animationDuration
        self.showMap = showMap
        self.mapHeight = mapHeight
        self.allowMapInteraction = allowMapInteraction
        self.showAmenities = showAmenities
        self.showOperatingHours = showOperatingHours
        self.showNearbyTransport = showNearbyTransport
    }
}
