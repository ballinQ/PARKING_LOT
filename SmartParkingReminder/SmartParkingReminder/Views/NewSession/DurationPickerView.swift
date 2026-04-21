import SwiftUI

struct DurationPickerView: View {
    @Binding var minutes: Int

    var body: some View {
        Picker("Duration", selection: $minutes) {
            ForEach([15, 30, 45, 60, 90, 120, 180, 240], id: \.self) { m in
                Text(label(for: m)).tag(m)
            }
        }
        .pickerStyle(.menu)
    }

    private func label(for minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }
}
