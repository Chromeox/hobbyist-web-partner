import Foundation
import CoreLocation
import SwiftUI

struct ClassItem: Identifiable, Codable {
    let id: String
    let name: String
    let category: String
    let instructor: String
    let instructorInitials: String
    let description: String
    let duration: String
    let difficulty: String
    let price: String
    let creditsRequired: Int
    let startTime: Date
    let endTime: Date
    let location: String
    let venueName: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let spotsAvailable: Int
    let totalSpots: Int
    let rating: String
    let reviewCount: String
    let icon: String
    let categoryColor: Color
    let isFeatured: Bool
    let requirements: [String]
    let amenities: [Amenity]
    let equipment: [Equipment]
    
    var spotsLeft: String {
        "\(spotsAvailable) spots"
    }
    
    // Sample data for previews
    static var sample: ClassItem {
        ClassItem(
            id: "1",
            name: "Beginner Pottery Wheel",
            category: "Ceramics",
            instructor: "Maria Chen",
            instructorInitials: "MC",
            description: "Learn the fundamentals of pottery on the wheel. This hands-on class covers centering clay, pulling walls, and creating your first bowl. Perfect for complete beginners wanting to explore the meditative art of ceramics.",
            duration: "90 min",
            difficulty: "Beginner",
            price: "$45",
            creditsRequired: 12,
            startTime: Date().addingTimeInterval(86400),
            endTime: Date().addingTimeInterval(91800),
            location: "Studio A",
            venueName: "Clay Mates Ceramics Studio",
            address: "1234 Main St, Vancouver, BC V6B 2V5",
            coordinate: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
            spotsAvailable: 6,
            totalSpots: 8,
            rating: "4.9",
            reviewCount: "89",
            icon: "paintpalette",
            categoryColor: .brown,
            isFeatured: true,
            requirements: ["Comfortable clothes that can get dirty", "Closed-toe shoes", "Hair tie (if long hair)"],
            amenities: [
                Amenity(name: "Parking", icon: "car.fill"),
                Amenity(name: "Aprons Provided", icon: "tshirt.fill"),
                Amenity(name: "Tools Included", icon: "wrench.fill")
            ],
            equipment: [
                Equipment(name: "Clay (1lb)", price: "$8"),
                Equipment(name: "Glazing", price: "$12"),
                Equipment(name: "Firing Service", price: "$15")
            ]
        )
    }

    // Extended hobby sample data
    static var hobbyClassSamples: [ClassItem] {
        [
            // Ceramics Classes
            ClassItem(
                id: "pottery-1",
                name: "Beginner Pottery Wheel",
                category: "Ceramics",
                instructor: "Maria Chen",
                instructorInitials: "MC",
                description: "Learn the fundamentals of pottery on the wheel. This hands-on class covers centering clay, pulling walls, and creating your first bowl. Perfect for complete beginners wanting to explore the meditative art of ceramics.",
                duration: "90 min",
                difficulty: "Beginner",
                price: "$45",
                creditsRequired: 12,
                startTime: Date().addingTimeInterval(86400),
                endTime: Date().addingTimeInterval(91800),
                location: "Studio A",
                venueName: "Clay Mates Ceramics Studio",
                address: "1234 Main St, Vancouver, BC V6B 2V5",
                coordinate: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
                spotsAvailable: 6,
                totalSpots: 8,
                rating: "4.9",
                reviewCount: "89",
                icon: "paintpalette",
                categoryColor: .brown,
                isFeatured: true,
                requirements: ["Comfortable clothes that can get dirty", "Closed-toe shoes", "Hair tie (if long hair)"],
                amenities: [
                    Amenity(name: "Parking", icon: "car.fill"),
                    Amenity(name: "Aprons Provided", icon: "tshirt.fill"),
                    Amenity(name: "Tools Included", icon: "wrench.fill")
                ],
                equipment: [
                    Equipment(name: "Clay (1lb)", price: "$8"),
                    Equipment(name: "Glazing", price: "$12"),
                    Equipment(name: "Firing Service", price: "$15")
                ]
            ),

            // Hand-Building Ceramics
            ClassItem(
                id: "pottery-2",
                name: "Hand-Building Ceramics",
                category: "Ceramics",
                instructor: "Maria Chen",
                instructorInitials: "MC",
                description: "Explore ceramic hand-building techniques including pinch pots, coil building, and slab construction. Create unique vessels and sculptural pieces without using the pottery wheel.",
                duration: "2 hours",
                difficulty: "All Levels",
                price: "$50",
                creditsRequired: 14,
                startTime: Date().addingTimeInterval(172800),
                endTime: Date().addingTimeInterval(180000),
                location: "Studio B",
                venueName: "Clay Mates Ceramics Studio",
                address: "1234 Main St, Vancouver, BC V6B 2V5",
                coordinate: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
                spotsAvailable: 4,
                totalSpots: 10,
                rating: "4.8",
                reviewCount: "67",
                icon: "paintpalette",
                categoryColor: .brown,
                isFeatured: false,
                requirements: ["Apron or old clothes", "Creativity and patience"],
                amenities: [
                    Amenity(name: "Parking", icon: "car.fill"),
                    Amenity(name: "All Tools Provided", icon: "wrench.fill"),
                    Amenity(name: "Tea & Coffee", icon: "cup.and.saucer")
                ],
                equipment: [
                    Equipment(name: "Clay (2lbs)", price: "$12"),
                    Equipment(name: "Underglazes", price: "$8"),
                    Equipment(name: "Clear Glaze & Firing", price: "$18")
                ]
            ),


            // Woodworking
            ClassItem(
                id: "wood-1",
                name: "Intro to Woodworking",
                category: "Woodworking",
                instructor: "David Park",
                instructorInitials: "DP",
                description: "Learn essential woodworking skills and safety practices. Build a simple cutting board while mastering basic tools, measuring, cutting, and finishing techniques.",
                duration: "3 hours",
                difficulty: "Beginner",
                price: "$85",
                creditsRequired: 22,
                startTime: Date().addingTimeInterval(259200),
                endTime: Date().addingTimeInterval(270000),
                location: "Woodshop",
                venueName: "Vancouver Woodworking Co-op",
                address: "890 Craft Lane, Vancouver, BC V5T 2M4",
                coordinate: CLLocationCoordinate2D(latitude: 49.2627, longitude: -123.1007),
                spotsAvailable: 3,
                totalSpots: 6,
                rating: "4.9",
                reviewCount: "43",
                icon: "hammer",
                categoryColor: .orange,
                isFeatured: true,
                requirements: ["Closed-toe shoes", "Long pants", "Safety glasses (provided)"],
                amenities: [
                    Amenity(name: "All Tools Provided", icon: "wrench.fill"),
                    Amenity(name: "Safety Equipment", icon: "eye"),
                    Amenity(name: "Wood Included", icon: "leaf")
                ],
                equipment: [
                    Equipment(name: "Premium Wood Upgrade", price: "$25"),
                    Equipment(name: "Take-home Tool Kit", price: "$45")
                ]
            ),

            // Painting
            ClassItem(
                id: "paint-1",
                name: "Watercolor Botanicals",
                category: "Painting",
                instructor: "Sofia Rodriguez",
                instructorInitials: "SR",
                description: "Paint beautiful botanical illustrations using watercolor techniques. Learn color mixing, wet-on-wet, and detail work while creating your own botanical artwork to take home.",
                duration: "2.5 hours",
                difficulty: "Intermediate",
                price: "$65",
                creditsRequired: 18,
                startTime: Date().addingTimeInterval(345600),
                endTime: Date().addingTimeInterval(354600),
                location: "Art Studio",
                venueName: "Creative Arts Collective",
                address: "234 Artist Way, Vancouver, BC V6K 3P7",
                coordinate: CLLocationCoordinate2D(latitude: 49.2727, longitude: -123.1307),
                spotsAvailable: 8,
                totalSpots: 12,
                rating: "4.8",
                reviewCount: "92",
                icon: "paintbrush",
                categoryColor: .blue,
                isFeatured: false,
                requirements: ["Basic painting experience helpful", "Apron or old clothes"],
                amenities: [
                    Amenity(name: "All Supplies Included", icon: "paintbrush"),
                    Amenity(name: "Natural Light Studio", icon: "sun.max"),
                    Amenity(name: "Gallery Display Option", icon: "photo")
                ],
                equipment: [
                    Equipment(name: "Professional Paper", price: "$15"),
                    Equipment(name: "Premium Paint Set", price: "$35")
                ]
            ),

            // Photography
            ClassItem(
                id: "photo-1",
                name: "Digital Photography Basics",
                category: "Photography",
                instructor: "James Wilson",
                instructorInitials: "JW",
                description: "Master your camera settings and composition techniques. Learn exposure triangle, depth of field, and creative composition in this hands-on outdoor photography workshop.",
                duration: "3 hours",
                difficulty: "Beginner",
                price: "$75",
                creditsRequired: 20,
                startTime: Date().addingTimeInterval(432000),
                endTime: Date().addingTimeInterval(442800),
                location: "Meet at Studio",
                venueName: "Vancouver Photo Academy",
                address: "456 Lens Street, Vancouver, BC V6J 1R8",
                coordinate: CLLocationCoordinate2D(latitude: 49.2527, longitude: -123.1407),
                spotsAvailable: 5,
                totalSpots: 8,
                rating: "4.6",
                reviewCount: "74",
                icon: "camera",
                categoryColor: .purple,
                isFeatured: false,
                requirements: ["DSLR or mirrorless camera", "Comfortable walking shoes", "Weather-appropriate clothing"],
                amenities: [
                    Amenity(name: "Camera Rental Available", icon: "camera"),
                    Amenity(name: "Photo Editing Tips", icon: "desktopcomputer"),
                    Amenity(name: "Small Group Size", icon: "person.2")
                ],
                equipment: [
                    Equipment(name: "Camera Rental", price: "$25"),
                    Equipment(name: "Memory Card", price: "$15")
                ]
            ),

            // Cooking
            ClassItem(
                id: "cook-1",
                name: "Italian Pasta Making",
                category: "Cooking",
                instructor: "Giuseppe Rossi",
                instructorInitials: "GR",
                description: "Learn traditional Italian pasta making from scratch. Create fresh fettuccine, ravioli, and gnocchi while mastering authentic sauce preparation techniques.",
                duration: "2.5 hours",
                difficulty: "All Levels",
                price: "$95",
                creditsRequired: 25,
                startTime: Date().addingTimeInterval(518400),
                endTime: Date().addingTimeInterval(527400),
                location: "Teaching Kitchen",
                venueName: "Culinary Arts Institute",
                address: "789 Flavor Ave, Vancouver, BC V6R 4T3",
                coordinate: CLLocationCoordinate2D(latitude: 49.2427, longitude: -123.1507),
                spotsAvailable: 7,
                totalSpots: 12,
                rating: "4.9",
                reviewCount: "128",
                icon: "chef.hat",
                categoryColor: .green,
                isFeatured: true,
                requirements: ["Apron (provided)", "Hair tie if needed", "Appetite for learning!"],
                amenities: [
                    Amenity(name: "All Ingredients Included", icon: "leaf"),
                    Amenity(name: "Take Home Meals", icon: "takeoutbag.and.cup.and.straw"),
                    Amenity(name: "Recipe Cards", icon: "doc.text")
                ],
                equipment: [
                    Equipment(name: "Pasta Machine", price: "$45"),
                    Equipment(name: "Professional Knife Set", price: "$85")
                ]
            ),

            // Jewelry Making
            ClassItem(
                id: "jewelry-1",
                name: "Silver Wire Jewelry Basics",
                category: "Jewelry Making",
                instructor: "Elena Kovač",
                instructorInitials: "EK",
                description: "Create beautiful silver wire jewelry using basic wireworking techniques. Learn to make rings, earrings, and pendants while mastering fundamental jewelry-making skills.",
                duration: "2 hours",
                difficulty: "Beginner",
                price: "$70",
                creditsRequired: 19,
                startTime: Date().addingTimeInterval(604800),
                endTime: Date().addingTimeInterval(612000),
                location: "Jewelry Studio",
                venueName: "Artisan Jewelry Workshop",
                address: "321 Silver Lane, Vancouver, BC V6H 2K9",
                coordinate: CLLocationCoordinate2D(latitude: 49.2327, longitude: -123.1607),
                spotsAvailable: 4,
                totalSpots: 8,
                rating: "4.7",
                reviewCount: "56",
                icon: "diamond",
                categoryColor: .cyan,
                isFeatured: false,
                requirements: ["Reading glasses if needed", "Comfortable seating posture"],
                amenities: [
                    Amenity(name: "All Tools Provided", icon: "wrench.fill"),
                    Amenity(name: "Materials Included", icon: "diamond"),
                    Amenity(name: "Take Home Pieces", icon: "gift")
                ],
                equipment: [
                    Equipment(name: "Premium Silver Wire", price: "$20"),
                    Equipment(name: "Gemstone Add-on", price: "$35")
                ]
            ),

            // Dance
            ClassItem(
                id: "dance-1",
                name: "Salsa Dancing for Beginners",
                category: "Dance",
                instructor: "Carlos Mendoza",
                instructorInitials: "CM",
                description: "Learn the passionate art of salsa dancing! Master basic steps, turns, and partnering techniques in a fun, supportive environment. No dance experience necessary.",
                duration: "90 min",
                difficulty: "Beginner",
                price: "$40",
                creditsRequired: 11,
                startTime: Date().addingTimeInterval(691200),
                endTime: Date().addingTimeInterval(696600),
                location: "Dance Studio A",
                venueName: "Vancouver Dance Academy",
                address: "654 Rhythm Street, Vancouver, BC V6T 1L5",
                coordinate: CLLocationCoordinate2D(latitude: 49.2227, longitude: -123.1707),
                spotsAvailable: 10,
                totalSpots: 16,
                rating: "4.8",
                reviewCount: "94",
                icon: "figure.dance",
                categoryColor: .pink,
                isFeatured: true,
                requirements: ["Comfortable dancing shoes", "Water bottle", "Positive attitude"],
                amenities: [
                    Amenity(name: "Sprung Floors", icon: "square.grid.3x3"),
                    Amenity(name: "Sound System", icon: "speaker.wave.3"),
                    Amenity(name: "Mirrors", icon: "mirror")
                ],
                equipment: [
                    Equipment(name: "Dance Shoes", price: "$35"),
                    Equipment(name: "Practice Videos", price: "$15")
                ]
            ),

            // Music
            ClassItem(
                id: "music-1",
                name: "Acoustic Guitar for Beginners",
                category: "Music",
                instructor: "Maya Thompson",
                instructorInitials: "MT",
                description: "Start your musical journey with acoustic guitar! Learn basic chords, strumming patterns, and play your first songs. Perfect for complete beginners with no musical background.",
                duration: "60 min",
                difficulty: "Beginner",
                price: "$55",
                creditsRequired: 15,
                startTime: Date().addingTimeInterval(777600),
                endTime: Date().addingTimeInterval(781200),
                location: "Music Room 2",
                venueName: "Harmony Music Studio",
                address: "987 Melody Drive, Vancouver, BC V6S 3M8",
                coordinate: CLLocationCoordinate2D(latitude: 49.2127, longitude: -123.1807),
                spotsAvailable: 6,
                totalSpots: 8,
                rating: "4.9",
                reviewCount: "67",
                icon: "music.note",
                categoryColor: .indigo,
                isFeatured: false,
                requirements: ["Acoustic guitar (rentals available)", "Pick (provided)", "Notebook for chord charts"],
                amenities: [
                    Amenity(name: "Guitar Rentals", icon: "music.note"),
                    Amenity(name: "Sheet Music", icon: "doc.text"),
                    Amenity(name: "Practice Space", icon: "speaker.wave.1")
                ],
                equipment: [
                    Equipment(name: "Guitar Rental", price: "$15"),
                    Equipment(name: "Beginner Songbook", price: "$20")
                ]
            ),

            // Writing
            ClassItem(
                id: "writing-1",
                name: "Creative Writing Workshop",
                category: "Writing",
                instructor: "Rachel Bennett",
                instructorInitials: "RB",
                description: "Unleash your creativity through guided writing exercises and prompts. Explore short fiction, poetry, and personal narrative in a supportive group setting with constructive feedback.",
                duration: "2 hours",
                difficulty: "All Levels",
                price: "$45",
                creditsRequired: 12,
                startTime: Date().addingTimeInterval(864000),
                endTime: Date().addingTimeInterval(871200),
                location: "Writers' Lounge",
                venueName: "Literary Arts Center",
                address: "147 Story Lane, Vancouver, BC V6P 4N2",
                coordinate: CLLocationCoordinate2D(latitude: 49.2027, longitude: -123.1907),
                spotsAvailable: 8,
                totalSpots: 12,
                rating: "4.6",
                reviewCount: "83",
                icon: "pencil",
                categoryColor: .brown,
                isFeatured: false,
                requirements: ["Notebook and pen", "Open mind", "Willingness to share (optional)"],
                amenities: [
                    Amenity(name: "Cozy Environment", icon: "book"),
                    Amenity(name: "Tea & Coffee", icon: "cup.and.saucer"),
                    Amenity(name: "Writing Materials", icon: "pencil")
                ],
                equipment: [
                    Equipment(name: "Premium Journal", price: "$25"),
                    Equipment(name: "Writer's Toolkit", price: "$15")
                ]
            ),

            // Additional Pottery Class
            ClassItem(
                id: "pottery-3",
                name: "Glazing & Firing Workshop",
                category: "Pottery",
                instructor: "Maria Chen",
                instructorInitials: "MC",
                description: "Complete your ceramic pieces with professional glazing techniques. Learn about different glaze types, application methods, and firing processes to bring your pottery to life.",
                duration: "2.5 hours",
                difficulty: "Intermediate",
                price: "$60",
                creditsRequired: 16,
                startTime: Date().addingTimeInterval(950400),
                endTime: Date().addingTimeInterval(959400),
                location: "Glazing Studio",
                venueName: "Clay Mates Ceramics Studio",
                address: "1234 Main St, Vancouver, BC V6B 2V5",
                coordinate: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
                spotsAvailable: 5,
                totalSpots: 8,
                rating: "4.8",
                reviewCount: "45",
                icon: "cup.and.saucer",
                categoryColor: .orange,
                isFeatured: false,
                requirements: ["Bisque-fired pieces to glaze", "Apron", "Previous pottery experience"],
                amenities: [
                    Amenity(name: "Kiln Firing Included", icon: "flame"),
                    Amenity(name: "50+ Glaze Options", icon: "paintpalette"),
                    Amenity(name: "Glazing Tools", icon: "paintbrush")
                ],
                equipment: [
                    Equipment(name: "Extra Firing", price: "$10"),
                    Equipment(name: "Premium Glazes", price: "$20")
                ]
            )
        ]
    }
}

// Make CLLocationCoordinate2D Codable
extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}

struct Amenity: Codable, Hashable {
    let name: String
    let icon: String
}

struct Equipment: Codable, Identifiable {
    var id: String { name }
    let name: String
    let price: String
}

struct InstructorCard: Identifiable, Codable {
    let id: String
    let name: String
    let initials: String
    let rating: String
    let specialties: [String]
    let bio: String
}

struct ClassReview: Identifiable, Codable {
    let id: String
    let userName: String
    let userInitials: String
    let rating: Int
    let comment: String
    let date: Date
}

// Category model for HomeView
extension ClassItem {
    struct Category: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let icon: String
    }
}

// Extension for Color to make it Codable
extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, opacity
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let opacity = try container.decode(Double.self, forKey: .opacity)
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // For simplicity, encoding a default color
        try container.encode(1.0, forKey: .red)
        try container.encode(0.0, forKey: .green)
        try container.encode(0.0, forKey: .blue)
        try container.encode(1.0, forKey: .opacity)
    }
}