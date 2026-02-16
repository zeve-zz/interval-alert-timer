import SwiftUI
import UniformTypeIdentifiers

struct SetupView: View {
    @Environment(TimerEngine.self) private var engine
    var ringNamespace: Namespace.ID
    @State private var showContent = false
    @State private var appearTime: Date?

    @AppStorage("lastMinutes") private var minutes = 5
    @AppStorage("lastSeconds") private var seconds = 0
    @AppStorage("lastPercentage") private var percentage = 25

    @AppStorage("notificationPermissionRequested") private var permissionRequested = false

    @State private var customPresets: [TimerPreset] = []
    @State private var hiddenBuiltInIDs: Set<UUID> = []
    @State private var presetOrder: [UUID] = []
    @State private var draggedPresetID: UUID?
    @State private var swipedPresetID: UUID?
    @State private var showSaveAlert = false
    @State private var newPresetName = ""

    private let notificationService = NotificationService()
    private let percentageOptions = [10, 20, 25, 33, 50]
    private let showQuickChips = false

    var totalDuration: TimeInterval {
        TimeInterval(minutes * 60 + seconds)
    }

    var isValid: Bool {
        totalDuration >= 5
    }

    var config: TimerConfiguration {
        TimerConfiguration(totalDuration: totalDuration, intervalMode: .percentage(percentage))
    }

    var normalizedOffsets: [Double] {
        guard isValid else { return [] }
        return config.alertOffsets.map { $0 / config.totalDuration }
    }

    private var orderedPresets: [TimerPreset] {
        let available = TimerPreset.builtInPresets.filter { !hiddenBuiltInIDs.contains($0.id) } + customPresets
        guard !presetOrder.isEmpty else { return available }
        var result: [TimerPreset] = []
        for id in presetOrder {
            if let p = available.first(where: { $0.id == id }) {
                result.append(p)
            }
        }
        for p in available where !presetOrder.contains(p.id) {
            result.append(p)
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 40)

                // Ring with pickers inside
                ZStack {
                    ProgressRingView(
                        progress: 0,
                        alertLevel: .gentle,
                        alertOffsets: normalizedOffsets
                    )

                    HStack(spacing: 0) {
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0...120, id: \.self) { m in
                                Text("\(m)").tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 70, height: 120)

                        Text(":")
                            .font(.system(size: 36, weight: .thin, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.bottom, 18)

                        Picker("Seconds", selection: $seconds) {
                            ForEach(0...59, id: \.self) { s in
                                Text(String(format: "%02d", s)).tag(s)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 70, height: 120)
                    }
                    .opacity(showContent ? 1 : 0)
                }
                .frame(width: 260, height: 260)
                .matchedGeometryEffect(id: "timerRing", in: ringNamespace)
                .padding(.bottom, 28)

                // Below-ring content
                Group {
                // Quick duration chips
                if showQuickChips {
                    HStack(spacing: 8) {
                        QuickChip(label: "1m", m: 1, s: 0)
                        QuickChip(label: "3m", m: 3, s: 0)
                        QuickChip(label: "5m", m: 5, s: 0)
                        QuickChip(label: "10m", m: 10, s: 0)
                        QuickChip(label: "25m", m: 25, s: 0)
                    }
                    .padding(.bottom, 24)
                }

                // Interval section
                Text("Alert Every")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.bottom, 10)

                HStack(spacing: 8) {
                    ForEach(percentageOptions, id: \.self) { pct in
                        Button {
                            percentage = pct
                        } label: {
                            Text("\(pct)%")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    percentage == pct
                                        ? Theme.accent
                                        : Theme.backgroundRaised
                                )
                                .foregroundStyle(percentage == pct ? Theme.backgroundDeep : Theme.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.bottom, 12)

                // Summary
                Text(isValid
                     ? "\(config.alertCount) alerts over \(TimerEngine.formatTime(totalDuration)) · Every \(percentage)%"
                     : "Set at least 5 seconds")
                    .font(.caption)
                    .foregroundStyle(isValid ? Theme.textTertiary : Theme.textSecondary)
                    .padding(.bottom, 32)

                // Start button
                Button {
                    startTimer()
                } label: {
                    Text("Start")
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Theme.accent : Theme.accentMuted)
                        .foregroundStyle(isValid ? Theme.backgroundDeep : Theme.textTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!isValid)
                .padding(.horizontal)
                .padding(.bottom, 36)

                // Presets inline
                VStack(alignment: .leading, spacing: 0) {
                    Text("Presets")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal)
                        .padding(.bottom, 12)

                    VStack(spacing: 0) {
                        ForEach(orderedPresets) { preset in
                            VStack(spacing: 0) {
                                ZStack(alignment: .trailing) {
                                    // Delete button (only when swiped)
                                    if swipedPresetID == preset.id {
                                        HStack {
                                            Spacer()
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    deletePreset(preset)
                                                    swipedPresetID = nil
                                                }
                                            } label: {
                                                Image(systemName: "trash")
                                                    .font(.body.weight(.semibold))
                                                    .foregroundStyle(.white)
                                                    .frame(width: 80)
                                                    .frame(maxHeight: .infinity)
                                                    .background(Color.red)
                                            }
                                        }
                                    }

                                    // Row content
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(preset.name)
                                                .font(.body.weight(.medium))
                                                .foregroundStyle(Theme.textPrimary)
                                            Text("\(TimerEngine.formatTime(preset.configuration.totalDuration)) · \(preset.configuration.intervalMode.displayLabel)")
                                                .font(.caption)
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(Theme.accent)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .background(Theme.backgroundSurface)
                                    .offset(x: swipedPresetID == preset.id ? -80 : 0)
                                    .onTapGesture {
                                        if swipedPresetID != nil {
                                            withAnimation(.easeOut(duration: 0.2)) {
                                                swipedPresetID = nil
                                            }
                                        } else {
                                            applyPreset(preset)
                                            startTimer()
                                        }
                                    }
                                    .gesture(
                                        DragGesture(minimumDistance: 20)
                                            .onEnded { value in
                                                withAnimation(.easeOut(duration: 0.2)) {
                                                    if value.translation.width < -30 {
                                                        swipedPresetID = preset.id
                                                    } else {
                                                        swipedPresetID = nil
                                                    }
                                                }
                                            }
                                    )
                                }
                                .clipped()
                                .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 12))
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation { deletePreset(preset) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }

                                if preset.id != orderedPresets.last?.id {
                                    Divider()
                                        .overlay(Theme.backgroundDivider)
                                        .padding(.leading, 16)
                                }
                            }
                            .onDrag {
                                draggedPresetID = preset.id
                                return NSItemProvider(object: preset.id.uuidString as NSString)
                            }
                            .onDrop(of: [UTType.text], delegate: PresetDropDelegate(
                                targetID: preset.id,
                                draggedID: $draggedPresetID,
                                presetOrder: $presetOrder,
                                onReorder: savePresetOrder
                            ))
                        }

                        if !orderedPresets.isEmpty {
                            Divider()
                                .overlay(Theme.backgroundDivider)
                                .padding(.leading, 16)
                        }

                        // Save preset row (not draggable)
                        Button {
                            showSaveAlert = true
                        } label: {
                            HStack {
                                Text("Save Current Settings")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Theme.accent)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Theme.accent)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: orderedPresets.map(\.id))
                    .background(Theme.backgroundSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
                } // end Group
                .opacity(showContent ? 1 : 0)
            }
        }
        .background(Theme.backgroundDeep)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            customPresets = loadCustomPresets()
            hiddenBuiltInIDs = loadHiddenBuiltInIDs()
            presetOrder = loadPresetOrder()
            if presetOrder.isEmpty {
                let available = TimerPreset.builtInPresets.filter { !hiddenBuiltInIDs.contains($0.id) } + customPresets
                presetOrder = available.map { $0.id }
            }
            showContent = false
            appearTime = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showContent = true
                }
            }
        }
        .alert("Save Preset", isPresented: $showSaveAlert) {
            TextField("Preset Name", text: $newPresetName)
            Button("Save") { saveCurrentAsPreset() }
            Button("Cancel", role: .cancel) { newPresetName = "" }
        } message: {
            Text("Enter a name for this preset")
        }
    }

    @ViewBuilder
    private func QuickChip(label: String, m: Int, s: Int) -> some View {
        Button {
            minutes = m
            seconds = s
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    minutes == m && seconds == s
                        ? Theme.accent.opacity(0.2)
                        : Theme.backgroundRaised
                )
                .clipShape(Capsule())
        }
    }

    private func startTimer() {
        let timerConfig = TimerConfiguration(totalDuration: totalDuration, intervalMode: .percentage(percentage))

        Task {
            if !permissionRequested {
                _ = await notificationService.requestPermission()
                permissionRequested = true
            }
        }

        withAnimation(.easeInOut(duration: 0.5)) {
            engine.start(with: timerConfig)
        }
    }

    private func applyPreset(_ preset: TimerPreset) {
        let c = preset.configuration
        minutes = Int(c.totalDuration) / 60
        seconds = Int(c.totalDuration) % 60
        if case .percentage(let pct) = c.intervalMode {
            percentage = pct
        }
    }

    private func loadCustomPresets() -> [TimerPreset] {
        guard let data = UserDefaults.standard.data(forKey: "savedPresets"),
              let decoded = try? JSONDecoder().decode([TimerPreset].self, from: data)
        else { return [] }
        return decoded
    }

    private func saveCustomPresets() {
        guard let data = try? JSONEncoder().encode(customPresets) else { return }
        UserDefaults.standard.set(data, forKey: "savedPresets")
    }

    private func deletePreset(_ preset: TimerPreset) {
        presetOrder.removeAll { $0 == preset.id }
        savePresetOrder()
        if preset.isBuiltIn {
            hiddenBuiltInIDs.insert(preset.id)
            saveHiddenBuiltInIDs()
        } else {
            customPresets.removeAll { $0.id == preset.id }
            saveCustomPresets()
        }
    }

    private func loadHiddenBuiltInIDs() -> Set<UUID> {
        guard let data = UserDefaults.standard.data(forKey: "hiddenBuiltInPresets"),
              let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data)
        else { return [] }
        return decoded
    }

    private func saveHiddenBuiltInIDs() {
        guard let data = try? JSONEncoder().encode(hiddenBuiltInIDs) else { return }
        UserDefaults.standard.set(data, forKey: "hiddenBuiltInPresets")
    }

    private func loadPresetOrder() -> [UUID] {
        guard let data = UserDefaults.standard.data(forKey: "presetOrder"),
              let decoded = try? JSONDecoder().decode([UUID].self, from: data)
        else { return [] }
        return decoded
    }

    private func savePresetOrder() {
        guard let data = try? JSONEncoder().encode(presetOrder) else { return }
        UserDefaults.standard.set(data, forKey: "presetOrder")
    }

    private func saveCurrentAsPreset() {
        let name = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let config = TimerConfiguration(totalDuration: totalDuration, intervalMode: .percentage(percentage))
        let preset = TimerPreset(name: name, configuration: config)
        withAnimation(.easeInOut(duration: 0.3)) {
            customPresets.append(preset)
            presetOrder.append(preset.id)
        }
        saveCustomPresets()
        savePresetOrder()
        newPresetName = ""
    }
}

struct PresetDropDelegate: DropDelegate {
    let targetID: UUID
    @Binding var draggedID: UUID?
    @Binding var presetOrder: [UUID]
    let onReorder: () -> Void

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedID, dragged != targetID else { return }
        guard let fromIndex = presetOrder.firstIndex(of: dragged),
              let toIndex = presetOrder.firstIndex(of: targetID) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            presetOrder.move(fromOffsets: IndexSet(integer: fromIndex),
                             toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedID = nil
        onReorder()
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
