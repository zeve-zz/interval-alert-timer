import SwiftUI

struct IntervalModePicker: View {
    @Binding var usePercentage: Bool
    @Binding var percentage: Int
    @Binding var fixedMinutes: Int
    @Binding var fixedSeconds: Int

    private let percentageOptions = [10, 20, 25, 33, 50]

    var body: some View {
        VStack(spacing: 16) {
            Picker("Interval Type", selection: $usePercentage) {
                Text("Percentage").tag(true)
                Text("Fixed Time").tag(false)
            }
            .pickerStyle(.segmented)

            if usePercentage {
                HStack(spacing: 10) {
                    ForEach(percentageOptions, id: \.self) { pct in
                        Button {
                            percentage = pct
                        } label: {
                            Text("\(pct)%")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    percentage == pct
                                        ? Color.accentColor
                                        : Color(.systemGray5)
                                )
                                .foregroundStyle(percentage == pct ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            } else {
                HStack(spacing: 16) {
                    HStack {
                        Text("Min")
                            .foregroundStyle(.secondary)
                        Picker("Minutes", selection: $fixedMinutes) {
                            ForEach(0...60, id: \.self) { m in
                                Text("\(m)").tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60, height: 100)
                    }
                    HStack {
                        Text("Sec")
                            .foregroundStyle(.secondary)
                        Picker("Seconds", selection: $fixedSeconds) {
                            ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { s in
                                Text("\(s)").tag(s)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60, height: 100)
                    }
                }
            }
        }
    }

    var intervalMode: IntervalMode {
        if usePercentage {
            return .percentage(percentage)
        } else {
            let totalSeconds = TimeInterval(fixedMinutes * 60 + fixedSeconds)
            return .fixedTime(max(totalSeconds, 5))
        }
    }
}
