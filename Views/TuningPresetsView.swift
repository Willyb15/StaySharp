import SwiftUI

struct TuningPresetsView: View {
    @ObservedObject var vm: TunerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Instrument.allCases, id: \.self) { instrument in
                    let presets = TuningPreset.forInstrument(instrument)
                    if !presets.isEmpty {
                        Section {
                            ForEach(presets) { preset in
                                Button {
                                    vm.selectedTuning = preset
                                    vm.selectedString = nil
                                    dismiss()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(preset.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Text(preset.description)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if vm.selectedTuning == preset {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                                .font(.title3)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.white.opacity(0.05))
                            }
                        } header: {
                            Text(instrument.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(white: 0.06))
            .navigationTitle("Tunings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
