import SwiftUI

struct MetronomeView: View {
    @StateObject private var vm = MetronomeViewModel()

    var body: some View {
        VStack(spacing: 0) {
            logoHeader
                .padding(.top, 16)

            Spacer()

            beatIndicator

            Spacer()

            bpmDisplay

            bpmSlider

            Spacer()

            beatsPicker

            Spacer()

            controlRow

            Spacer(minLength: 40)
        }
        .padding(.horizontal)
    }

    // MARK: - Subviews

    private var logoHeader: some View {
        Image("StaySharpLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 90, height: 90)
            .clipShape(Circle())
    }

    private var beatIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<vm.beatsPerMeasure, id: \.self) { i in
                let isCurrent = vm.isPlaying && vm.activeBeat == i
                let isAccent = i == 0
                RoundedRectangle(cornerRadius: 6)
                    .fill(beatColor(isCurrent: isCurrent, isAccent: isAccent))
                    .frame(height: isAccent ? 44 : 36)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(isCurrent && vm.beatFlash ? 1.15 : 1.0)
                    .animation(.easeOut(duration: 0.06), value: vm.beatFlash)
            }
        }
        .frame(height: 50)
        .padding(.horizontal, 8)
    }

    private var bpmDisplay: some View {
        VStack(spacing: 2) {
            Text("\(Int(vm.bpm.rounded()))")
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .contentTransition(.numericText())
                .animation(.snappy, value: Int(vm.bpm.rounded()))
            Text("BPM")
                .font(.caption)
                .foregroundStyle(.secondary)
                .kerning(2)
        }
    }

    private var bpmSlider: some View {
        VStack(spacing: 8) {
            Slider(value: $vm.bpm, in: 20...300, step: 1) {
                Text("BPM")
            }
            .tint(.green)
            .onChange(of: vm.bpm) { _, _ in
                if vm.isPlaying {
                    // Restart metronome with new tempo
                    vm.togglePlay()
                    vm.togglePlay()
                }
            }

            HStack {
                Text("20")
                Spacer()
                Text("♩= \(tempoMarking(vm.bpm))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("300")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }

    private var beatsPicker: some View {
        VStack(spacing: 10) {
            Text("Time Signature")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                ForEach([2, 3, 4, 6], id: \.self) { beats in
                    Button {
                        vm.beatsPerMeasure = beats
                        vm.currentBeat = 0
                    } label: {
                        Text("\(beats)/4")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(vm.beatsPerMeasure == beats ? Color.green.opacity(0.25) : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(vm.beatsPerMeasure == beats ? Color.green.opacity(0.6) : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 16) {
            Button {
                vm.tapTempo()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "hand.tap.fill")
                        .font(.title2)
                    Text("Tap Tempo")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Button {
                vm.togglePlay()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: vm.isPlaying ? "stop.fill" : "play.fill")
                        .font(.title2)
                    Text(vm.isPlaying ? "Stop" : "Play")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(vm.isPlaying ? Color.green.opacity(0.25) : Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(vm.isPlaying ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func beatColor(isCurrent: Bool, isAccent: Bool) -> Color {
        if isCurrent && vm.beatFlash {
            return isAccent ? .green : .white.opacity(0.7)
        }
        return isAccent ? Color.white.opacity(0.2) : Color.white.opacity(0.1)
    }

    private func tempoMarking(_ bpm: Double) -> String {
        switch bpm {
        case ..<60:   return "Largo"
        case ..<66:   return "Larghetto"
        case ..<76:   return "Adagio"
        case ..<108:  return "Andante"
        case ..<120:  return "Moderato"
        case ..<156:  return "Allegro"
        case ..<176:  return "Vivace"
        case ..<200:  return "Presto"
        default:      return "Prestissimo"
        }
    }
}

#Preview {
    ZStack {
        Color(white: 0.06).ignoresSafeArea()
        MetronomeView()
    }
}
