import Foundation

protocol ParkingSessionStorageServiceProtocol {
    func load() throws -> [ParkingSession]
    func save(_ sessions: [ParkingSession]) throws
}

final class ParkingSessionStorageService: ParkingSessionStorageServiceProtocol {
    static let currentSchemaVersion = 1

    private let fileURL: URL

    init(filename: String = "parking_sessions.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documents.appendingPathComponent(filename)
    }

    /// Test-friendly initializer.
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func load() throws -> [ParkingSession] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let envelope = try? decoder.decode(ParkingSessionStorageEnvelope.self, from: data) {
            guard envelope.schemaVersion <= Self.currentSchemaVersion else {
                throw ParkingSessionStorageError.unsupportedSchemaVersion(envelope.schemaVersion)
            }
            return envelope.sessions
        }

        // Phase 1 wrote a bare [ParkingSession] array. Keep this fallback so existing
        // local installs migrate simply by loading once and saving again.
        return try decoder.decode([ParkingSession].self, from: data)
    }

    func save(_ sessions: [ParkingSession]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let envelope = ParkingSessionStorageEnvelope(
            schemaVersion: Self.currentSchemaVersion,
            savedAt: Date(),
            sessions: sessions
        )
        let data = try encoder.encode(envelope)
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: [.atomic])
    }
}

private struct ParkingSessionStorageEnvelope: Codable {
    let schemaVersion: Int
    let savedAt: Date
    let sessions: [ParkingSession]
}

enum ParkingSessionStorageError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
}
