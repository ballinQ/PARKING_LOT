import SwiftUI

struct NewSessionView: View {
    @EnvironmentObject var store: ParkingSessionStore
    @Environment(\.dismiss) private var dismiss

    let locationService: LocationServiceProtocol

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
                        .accessibilityIdentifier(A11y.newSessionLocationField)
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
                        .accessibilityIdentifier(A11y.newSessionNoteField)
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
                        .accessibilityIdentifier(A11y.newSessionCancelButton)
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
                    .accessibilityIdentifier(A11y.newSessionStartButton)
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

        let coordinate = await locationService.currentCoordinateOnce()
        let coordTuple = coordinate.map { (lat: $0.latitude, lon: $0.longitude) }

        await store.startNewSession(from: .fullForm(
            locationName: trimmedName,
            durationMinutes: durationMinutes,
            note: trimmedNote,
            coordinate: coordTuple
        ))

        dismiss()
    }
}
