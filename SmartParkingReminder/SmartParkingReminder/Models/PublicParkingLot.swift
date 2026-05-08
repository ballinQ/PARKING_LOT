import CoreLocation
import Foundation

enum ParkingSourceKind: String, Codable, Equatable {
    case greenP
    case torontoOpenData
    case torontoParkingAuthority
    case mapKitSearch
    case staticPrototype
    case unknown
}

struct ParkingSource: Codable, Equatable, Identifiable {
    let id: String
    var name: String
    var organizationName: String?
    var kind: ParkingSourceKind
    var sourceURL: URL?
    var licenseDescription: String?
    var lastUpdated: Date?
    var updateFrequencyDescription: String?
    var isOfficial: Bool
    var supportsRealTimeAvailability: Bool
    var notes: String

    static let greenPResearchPlaceholder = ParkingSource(
        id: "green_p_research",
        name: "Green P Research Placeholder",
        organizationName: "Toronto Parking Authority",
        kind: .greenP,
        sourceURL: nil,
        licenseDescription: nil,
        lastUpdated: nil,
        updateFrequencyDescription: nil,
        isOfficial: false,
        supportsRealTimeAvailability: false,
        notes: "Placeholder only. Do not display production Green P lots or claim real-time availability until an official source is verified."
    )
}

enum PublicParkingFacilityType: String, Codable, Equatable {
    case surfaceLot
    case garage
    case undergroundGarage
    case street
    case mixed
    case unknown
}

enum PublicParkingAvailabilityKind: String, Codable, Equatable {
    case notProvided
    case staticOnly
    case averageOrHistoricalOnly
    case realTimeOfficial
}

struct PublicParkingAvailabilityInfo: Codable, Equatable {
    var kind: PublicParkingAvailabilityKind
    var displayText: String
    var sourceUpdatedAt: Date?

    static let notProvided = PublicParkingAvailabilityInfo(
        kind: .notProvided,
        displayText: "Availability not provided",
        sourceUpdatedAt: nil
    )
}

struct PublicParkingRateInfo: Codable, Equatable {
    var hourlyRateDescription: String?
    var dayMaxDescription: String?
    var nightMaxDescription: String?
    var weekendRateDescription: String?
    var maxTimeDescription: String?
    var notes: String

    init(
        hourlyRateDescription: String? = nil,
        dayMaxDescription: String? = nil,
        nightMaxDescription: String? = nil,
        weekendRateDescription: String? = nil,
        maxTimeDescription: String? = nil,
        notes: String = ""
    ) {
        self.hourlyRateDescription = hourlyRateDescription
        self.dayMaxDescription = dayMaxDescription
        self.nightMaxDescription = nightMaxDescription
        self.weekendRateDescription = weekendRateDescription
        self.maxTimeDescription = maxTimeDescription
        self.notes = notes
    }
}

struct PublicParkingLot: Codable, Equatable, Identifiable {
    let id: String
    var source: ParkingSource
    var sourceLotID: String?
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var facilityType: PublicParkingFacilityType
    var capacity: Int?
    var rateInfo: PublicParkingRateInfo
    var availabilityInfo: PublicParkingAvailabilityInfo
    var hasEVCharging: Bool?
    var heightRestrictionDescription: String?
    var sourceURL: URL?
    var sourceLastUpdated: Date?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var canClaimRealTimeAvailability: Bool {
        source.supportsRealTimeAvailability && availabilityInfo.kind == .realTimeOfficial
    }
}

struct GreenPParkingLot: Codable, Equatable, Identifiable {
    var lot: PublicParkingLot
    var carParkNumber: String?
    var greenPFacilityTypeDescription: String?

    var id: String { lot.id }

    init(
        lot: PublicParkingLot,
        carParkNumber: String? = nil,
        greenPFacilityTypeDescription: String? = nil
    ) {
        self.lot = lot
        self.carParkNumber = carParkNumber
        self.greenPFacilityTypeDescription = greenPFacilityTypeDescription
    }

    var canClaimRealTimeAvailability: Bool {
        lot.canClaimRealTimeAvailability
    }
}
