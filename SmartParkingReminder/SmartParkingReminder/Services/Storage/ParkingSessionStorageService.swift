import Foundation

protocol ParkingSessionStorageServiceProtocol {
    func load() throws -> [ParkingSession]
    func save(_ sessions: [ParkingSession]) throws
}

final class ParkingSessionStorageService: ParkingSessionStorageServiceProtocol {
    private let fileURL: URL

    init(filename: String = "parking_sessions.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documents.appendingPathComponent(filename)
    }

    func load() throws -> [ParkingSession] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([ParkingSession].self, from: data)
    }

    func save(_ sessions: [ParkingSession]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(sessions)
        try data.write(to: fileURL, options: [.atomic])
    }
}
