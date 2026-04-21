import SwiftUI

struct NewSessionView: View {
    @EnvironmentObject var store: ParkingSessionStore
    @Environment(\.dismiss) private var dismiss

    let locationService: LocationService

    @State private var locationName: String = ""
    @State private var note: String = ""
    @State private var durationMinutes: Int = 60

    @State private var isStarting: Bool = false

    private var canSave: Bool {
        !locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    TextField("e.g. Green P Lot", text: $locationName)
                        .textInputAutocapitalization(.words)
                }

                Section("Duration") {
                    DurationPickerView(minutes: $durationMinutes)
                    Text("Notifications: 15 minutes before expiry and at expiry.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Note (optional)") {
                    TextField("Add a note", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Location (auto)") {
                    Text("When you tap Start, the app requests your current location once and saves it with the session.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isStarting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await startSession() }
                    } label: {
                        if isStarting {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Starting…")
                            }
                        } else {
                            Text("Start")
                        }
                    }
                    .disabled(!canSave || isStarting)
                }
            }
        }
    }

    private func startSession() async {
        isStarting = true
        defer { isStarting = false }

        let trimmedName = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let duration = TimeInterval(durationMinutes * 60)

        let coordinate = await locationService.currentCoordinateOnce()
        let coordTuple = coordinate.map { (lat: $0.latitude, lon: $0.longitude) }

        await store.startNewSession(
            locationName: trimmedName,
            duration: duration,
            note: trimmedNote,
            coordinate: coordTuple
        )

        dismiss()
    }
}
