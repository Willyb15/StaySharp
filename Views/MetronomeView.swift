import SwiftUI

struct MetronomeView: View {
    @StateObject private var vm = MetronomeViewModel()

    var body: some View {
        VStack(spacing: 0) {
            logoHeader
                .padding(.top, 16)

            Spacer()

            beatIndicator

            if !vm.isPlaying {
                Text("Tap a beat to set accents")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }

            Spacer()

            bpmDisplay

            bpmSlider

            Spacer()

            beatsPicker

            subdivisionPicker

            clickStylePicker

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
                let isAccent = vm.accentedBeats.contains(i)
                Button {
                    vm.toggleAccent(beat: i)
                } label: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(beatColor(isCurrent: isCurrent, isAccent: isAccent))
                        .frame(height: isAccent ? 44 : 36)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(isCurrent && vm.beatFlash ? 1.15 : 1.0)
                        .animation(.easeOut(duration: 0.06), value: vm.beatFlash)
                        .overlay(
                            isAccent && !isCurrent ?
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 50)
        .padding(.horizontal, 8)
    }

    private var bpmDisplay: some View {
        VStack(spacing: 8) {
            Text("\(Int(vm.bpm.rounded()))")
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .contentTransition(.numericText())
                .animation(.snappy, value: Int(vm.bpm.rounded()))

            Text("BPM")
                .font(.caption)
                .foregroundStyle(.secondary)
                .kerning(2)

            HStack(spacing: 10) {
                nudgeButton(label: "−5", amount: -5)
                nudgeButton(label: "−1", amount: -1)
                Spacer()
                nudgeButton(label: "+1", amount: 1)
                nudgeButton(label: "+5", amount: 5)
            }
            .padding(.horizontal, 32)
        }
    }

    private func nudgeButton(label: String, amount: Double) -> some View {
        Button {
            vm.bpm = min(300, max(20, vm.bpm + amount))
            if vm.isPlaying { vm.restart() }
        } label: {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .frame(width: 48, height: 36)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var bpmSlider: some View {
        VStack(spacing: 8) {
            Slider(value: $vm.bpm, in: 20...300, step: 1) { Text("BPM") }
                .tint(.green)
                .onChange(of: vm.bpm) { _, _ in
                    if vm.isPlaying { vm.restart() }
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimeSignature.presets, id: \.label) { ts in
                        Button {
                            vm.timeSignature = ts
                            vm.currentBeat = 0
                        } label: {
                            Text(ts.label)
                                .font(.subheadline.weight(.semibold))
                                .frame(minWidth: 48)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 8)
                                .background(vm.timeSignature == ts ? Color.green.opacity(0.25) : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(vm.timeSignature == ts ? Color.green.opacity(0.6) : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var subdivisionPicker: some View {
        VStack(spacing: 10) {
            Text("Subdivision")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(subdivisionOptions, id: \.value) { option in
                    Button {
                        vm.subdivision = option.value
                        if vm.isPlaying { vm.restart() }
                    } label: {
                        VStack(spacing: 2) {
                            Text(option.symbol)
                                .font(.subheadline.weight(.semibold))
                            Text(option.label)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(vm.subdivision == option.value ? Color.green.opacity(0.25) : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(vm.subdivision == option.value ? Color.green.opacity(0.6) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var subdivisionOptions: [(value: Int, symbol: String, label: String)] {
        [(1, "♩", "Quarter"), (2, "♪♪", "8th"), (3, "♪³", "Triplet"), (4, "♬", "16th")]
    }

    private var clickStylePicker: some View {
        VStack(spacing: 10) {
            Text("Click Sound")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(ClickStyle.allCases, id: \.self) { style in
                    Button {
                        vm.clickStyle = style
                    } label: {
                        Text(style.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(vm.clickStyle == style ? Color.green.opacity(0.25) : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(vm.clickStyle == style ? Color.green.opacity(0.6) : Color.clear, lineWidth: 1)
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
                    Image(systemName: "hand.tap.fill").font(.title2)
                    Text("Tap Tempo").font(.caption2)
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
                    Image(systemName: vm.isPlaying ? "stop.fill" : "play.fill").font(.title2)
                    Text(vm.isPlaying ? "Stop" : "Play").font(.headline)
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
        return isAccent ? Color.white.opacity(0.22) : Color.white.opacity(0.08)
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
