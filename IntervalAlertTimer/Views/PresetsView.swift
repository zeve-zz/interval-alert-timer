import SwiftUI

struct PresetsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TimerEngine.self) private var engine

    var onSelect: (TimerPreset) -> Void

    @State private var customPresets: [TimerPreset] = []
    @State private var showSaveSheet = false
    @State private var newPresetName = ""

    private let storageKey = "savedPresets"

    var body: some View {
        NavigationStack {
            List {
                Section("Built-in") {
                    ForEach(TimerPreset.builtInPresets) { preset in
                        PresetRow(preset: preset) {
                            onSelect(preset)
                            dismiss()
                        }
                    }
                }

                if !customPresets.isEmpty {
                    Section("Custom") {
                        ForEach(customPresets) { preset in
                            PresetRow(preset: preset) {
                                onSelect(preset)
                                dismiss()
                            }
                        }
                        .onDelete(perform: deletePresets)
                    }
                }

                Section {
                    Button {
                        showSaveSheet = true
                    } label: {
                        Label("Save Current Settings", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { loadPresets() }
            .alert("Save Preset", isPresented: $showSaveSheet) {
                TextField("Preset Name", text: $newPresetName)
                Button("Save") { saveCurrentAsPreset() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a name for this preset")
            }
        }
    }

    @ViewBuilder
    private func PresetRow(preset: TimerPreset, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                HStack {
                    Text(TimerEngine.formatTime(preset.configuration.totalDuration))
                    Text("·")
                    Text(preset.configuration.intervalMode.displayLabel)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([TimerPreset].self, from: data)
        else { return }
        customPresets = decoded
    }

    private func savePresets() {
        guard let data = try? JSONEncoder().encode(customPresets) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func saveCurrentAsPreset() {
        guard !newPresetName.isEmpty else { return }
        // Use defaults if no config — this is the "save current settings" from setup view
        let config = engine.configuration ?? TimerConfiguration(
            totalDuration: 300,
            intervalMode: .percentage(25)
        )
        let preset = TimerPreset(name: newPresetName, configuration: config)
        customPresets.append(preset)
        savePresets()
        newPresetName = ""
    }

    private func deletePresets(at offsets: IndexSet) {
        customPresets.remove(atOffsets: offsets)
        savePresets()
    }
}
