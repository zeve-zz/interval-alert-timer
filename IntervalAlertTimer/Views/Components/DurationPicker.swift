import SwiftUI

struct DurationPicker: View {
    @Binding var minutes: Int
    @Binding var seconds: Int

    private let minuteRange = Array(0...120)
    private let secondRange = Array(0...59)

    var body: some View {
        HStack(spacing: 0) {
            Picker("Minutes", selection: $minutes) {
                ForEach(minuteRange, id: \.self) { m in
                    Text("\(m) min").tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 140)

            Picker("Seconds", selection: $seconds) {
                ForEach(secondRange, id: \.self) { s in
                    Text("\(s) sec").tag(s)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 140)
        }
        .frame(height: 150)
    }
}
