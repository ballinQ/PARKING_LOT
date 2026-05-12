import SwiftUI

struct DurationPickerView: View {
    @Binding var minutes: Int

    private let presets = [15, 30, 60, 120]
    private let maximumHours = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        minutes = preset
                    } label: {
                        Text(label(for: preset))
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 2)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier(A11y.newSessionDurationPresetButton(minutes: preset))
                }
            }

            HStack(spacing: 12) {
                Picker("Hours", selection: hoursBinding) {
                    ForEach(0...maximumHours, id: \.self) { hour in
                        Text("\(hour) hr").tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityIdentifier(A11y.newSessionDurationHoursPicker)

                Picker("Minutes", selection: minuteBinding) {
                    ForEach(0...59, id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
                .accessibilityIdentifier(A11y.newSessionDurationMinutesPicker)
            }
            .frame(height: 132)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text("Selected: \(label(for: minutes))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier(A11y.newSessionDurationPicker)
    }

    private var hoursBinding: Binding<Int> {
        Binding(
            get: { min(minutes / 60, maximumHours) },
            set: { newHours in
                let cappedHours = min(max(newHours, 0), maximumHours)
                minutes = normalizedDuration(hours: cappedHours, minuteRemainder: minutes % 60)
            }
        )
    }

    private var minuteBinding: Binding<Int> {
        Binding(
            get: { minutes % 60 },
            set: { newMinutes in
                minutes = normalizedDuration(hours: minutes / 60, minuteRemainder: newMinutes)
            }
        )
    }

    private func normalizedDuration(hours: Int, minuteRemainder: Int) -> Int {
        max(1, min(maximumHours * 60 + 59, max(hours, 0) * 60 + max(minuteRemainder, 0)))
    }

    private func label(for minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }
}
