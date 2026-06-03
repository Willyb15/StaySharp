import SwiftUI

struct TunerView: View {
    @ObservedObject var vm: TunerViewModel
    @State private var showTunings = false

    var body: some View {
        VStack(spacing: 0) {
            tuningSelector
                .padding(.top, 12)

            modeRow
                .padding(.top, 8)

            Spacer()

            noteDisplay
                .animation(.spring(response: 0.3), value: vm.detectedNote?.displayName)

            Spacer()

            meterSection

            Spacer()

            stringSelector

            if [Instrument.guitar, .sevenString].contains(vm.selectedTuning.instrument) {
                capoSelector
                    .padding(.top, 12)
            }

            bottomControls
                .padding(.bottom, 32)
        }
        .sheet(isPresented: $showTunings) {
            TuningPresetsView(vm: vm)
        }
        .alert("Microphone Access Required", isPresented: $vm.permissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Stay Sharp needs microphone access to detect pitch.")
        }
    }

    // MARK: - Subviews

    private var tuningSelector: some View {
        HStack {
            Button { showTunings = true } label: {
                HStack(spacing: 6) {
                    Text(vm.selectedTuning.name)
                        .font(.subheadline.weight(.semibold))
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(vm.selectedTuning.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.white.opacity(0.08), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                vm.autoMode.toggle()
                if vm.autoMode { vm.selectedString = nil; vm.stopGuidedTuning() }
            } label: {
                Text("Auto")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(vm.autoMode ? Color.green.opacity(0.2) : Color.white.opacity(0.08), in: Capsule())
                    .overlay(Capsule().stroke(vm.autoMode ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1))
                    .foregroundStyle(vm.autoMode ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private var modeRow: some View {
        HStack(spacing: 8) {
            // Guided string-by-string button
            Button {
                if vm.guidedTuning {
                    vm.stopGuidedTuning()
                } else {
                    vm.autoMode = false
                    vm.startGuidedTuning()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: vm.guidedTuning ? "stop.circle" : "arrow.right.circle")
                        .font(.caption)
                    Text(vm.guidedTuning ? vm.guidedProgress : "Guide")
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(vm.guidedTuning ? Color.orange.opacity(0.2) : Color.white.opacity(0.08), in: Capsule())
                .overlay(Capsule().stroke(vm.guidedTuning ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1))
                .foregroundStyle(vm.guidedTuning ? .orange : .secondary)
            }
            .buttonStyle(.plain)

            // Drone tone button
            Button {
                vm.droneActive.toggle()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: vm.droneActive ? "waveform.circle.fill" : "waveform.circle")
                        .font(.caption)
                    Text("Drone")
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(vm.droneActive ? Color.purple.opacity(0.2) : Color.white.opacity(0.08), in: Capsule())
                .overlay(Capsule().stroke(vm.droneActive ? Color.purple.opacity(0.5) : Color.clear, lineWidth: 1))
                .foregroundStyle(vm.droneActive ? .purple : .secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            // Reference pitch A=440
            referencePitchControl
        }
        .padding(.horizontal)
    }

    private var referencePitchControl: some View {
        HStack(spacing: 4) {
            Button {
                vm.referencePitch = max(430, vm.referencePitch - 1)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)

            Text("A=\(Int(vm.referencePitch))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(vm.referencePitch == 440 ? .secondary : Color.yellow)
                .frame(minWidth: 44)

            Button {
                vm.referencePitch = min(450, vm.referencePitch + 1)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var noteDisplay: some View {
        VStack(spacing: 4) {
            if let note = vm.detectedNote {
                Text(note.name)
                    .font(.system(size: 80, weight: .thin, design: .rounded))
                    .foregroundStyle(noteColor(for: note.tuningState))
                    .contentTransition(.numericText())

                HStack(spacing: 12) {
                    Text(centsLabel(note.cents))
                        .contentTransition(.numericText())

                    if let freq = vm.detectedFrequency {
                        Text("·").foregroundStyle(.tertiary)
                        Text(String(format: "%.1f Hz", freq))
                            .contentTransition(.numericText())
                    }
                }
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
            } else {
                Text(vm.isListening ? "–" : "Tap to listen")
                    .font(.system(size: vm.isListening ? 80 : 24, weight: .thin, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 110)
    }

    private var meterSection: some View {
        Group {
            if let note = vm.detectedNote {
                TunerMeterView(cents: note.cents, state: note.tuningState)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
            } else {
                TunerMeterView(cents: 0, state: .inTune)
                    .padding(.horizontal, 20)
                    .opacity(0.3)
            }
        }
    }

    private var stringSelector: some View {
        let allSorted = vm.selectedTuning.strings.sorted { $0.stringNumber > $1.stringNumber }
        let leftCount = (allSorted.count + 1) / 2
        let leftStrings = Array(allSorted.prefix(leftCount).reversed())
        let rightStrings = Array(allSorted.suffix(allSorted.count - leftCount))
        let logoHeight = CGFloat(max(leftStrings.count, rightStrings.count)) * 52

        return VStack(spacing: 10) {
            HStack(alignment: .top) {
                VStack(spacing: 8) {
                    ForEach(leftStrings) { str in
                        StringButton(
                            guitarString: str,
                            isSelected: vm.selectedString == str,
                            isInTune: vm.tunedStrings.contains(str.id)
                        ) {
                            vm.autoMode = false
                            vm.stopGuidedTuning()
                            vm.selectedString = vm.selectedString == str ? nil : str
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Spacer()
                    Image("StaySharpLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    Spacer()
                }
                .frame(width: 80, height: logoHeight)

                VStack(spacing: 8) {
                    ForEach(rightStrings) { str in
                        StringButton(
                            guitarString: str,
                            isSelected: vm.selectedString == str,
                            isInTune: vm.tunedStrings.contains(str.id)
                        ) {
                            vm.autoMode = false
                            vm.stopGuidedTuning()
                            vm.selectedString = vm.selectedString == str ? nil : str
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)

            Text(vm.selectedString.map { "Tuning \(String($0.noteName.prefix(while: { !$0.isNumber }))) · string \($0.stringNumber)" }
                ?? (vm.autoMode ? "Detecting string automatically" : "Tap a string to tune it individually"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    private var capoSelector: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Capo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if vm.capo > 0 {
                    Button { vm.capo = 0 } label: {
                        Text("Remove")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(0...7, id: \.self) { fret in
                        Button { vm.capo = fret } label: {
                            VStack(spacing: 2) {
                                Text(fret == 0 ? "Open" : "Fret \(fret)")
                                    .font(.caption2.weight(vm.capo == fret ? .semibold : .regular))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(vm.capo == fret ? Color.green.opacity(0.2) : Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(vm.capo == fret ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1))
                            .foregroundStyle(vm.capo == fret ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var bottomControls: some View {
        Button {
            vm.toggleListening()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: vm.isListening ? "mic.fill" : "mic")
                    .font(.title3)
                Text(vm.isListening ? "Listening…" : "Start Tuner")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(vm.isListening ? Color.green.opacity(0.25) : Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(vm.isListening ? Color.green.opacity(0.6) : Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .symbolEffect(.pulse, isActive: vm.isListening)
    }

    // MARK: - Helpers

    private func noteColor(for state: Note.TuningState) -> Color {
        switch state {
        case .inTune: return .green
        case .flat:   return Color(hue: 0.6, saturation: 0.9, brightness: 1.0)
        case .sharp:  return Color(hue: 0.08, saturation: 0.9, brightness: 1.0)
        }
    }

    private func centsLabel(_ cents: Float) -> String {
        if abs(cents) < 1 { return "In tune" }
        let sign = cents > 0 ? "+" : ""
        return "\(sign)\(Int(cents)) cents"
    }
}

struct StringButton: View {
    let guitarString: GuitarString
    let isSelected: Bool
    let isInTune: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(borderColor, lineWidth: isSelected || isInTune ? 2 : 0))
                Text(noteLetter(guitarString.noteName))
                    .font(.system(size: 16, weight: isSelected || isInTune ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(labelColor)
            }
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        if isInTune { return .green.opacity(0.2) }
        if isSelected { return .white.opacity(0.15) }
        return .white.opacity(0.07)
    }

    private var borderColor: Color {
        if isInTune { return .green.opacity(0.7) }
        if isSelected { return .white.opacity(0.4) }
        return .clear
    }

    private var labelColor: Color {
        if isInTune { return .green }
        if isSelected { return .white }
        return .secondary
    }

    private func noteLetter(_ name: String) -> String {
        String(name.prefix(while: { !$0.isNumber }))
    }
}
