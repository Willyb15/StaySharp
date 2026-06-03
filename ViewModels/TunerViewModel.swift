import Foundation
import CoreHaptics
import SwiftUI

@MainActor
class TunerViewModel: ObservableObject {
    @Published var detectedNote: Note?
    @Published var detectedFrequency: Float?
    @Published var selectedTuning: TuningPreset = TuningPreset.all[0] {
        didSet {
            if oldValue.id != selectedTuning.id {
                selectedString = nil
                tunedStrings = []
                guidedTuning = false
                capo = 0
            }
        }
    }
    @Published var selectedString: GuitarString? {
        didSet { if droneActive { startDrone() } }
    }
    @Published var isListening = false
    @Published var permissionDenied = false
    @Published var autoMode = true
    @Published var tunedStrings: Set<UUID> = []

    @Published var capo: Int = 0 {
        didSet { tunedStrings = [] }
    }
    @Published var droneActive: Bool = false {
        didSet { droneActive ? startDrone() : drone.stop() }
    }
    @Published var guidedTuning: Bool = false

    private var guidedOrder: [GuitarString] = []
    private var guidedIndex = 0
    private var autoAdvanceWork: DispatchWorkItem?

    private var frequencyHistory: [Float] = []
    private let historySize = 4

    private let audioEngine = AudioEngine()
    private let drone = DroneAudio()
    private var hapticEngine: CHHapticEngine?
    private var wasInTune = false

    init() {
        setupHaptics()
        audioEngine.onPitchDetected = { [weak self] freq in
            Task { @MainActor [weak self] in
                self?.handleFrequency(freq)
            }
        }
    }

    func toggleListening() {
        if isListening {
            audioEngine.stop()
            isListening = false
            detectedNote = nil
            detectedFrequency = nil
            frequencyHistory = []
            tunedStrings = []
            stopGuidedTuning()
        } else {
            audioEngine.requestPermissionAndStart { [weak self] granted in
                Task { @MainActor [weak self] in
                    if granted { self?.isListening = true }
                    else { self?.permissionDenied = true }
                }
            }
        }
    }

    // Capo-adjusted target frequency for the selected string
    var targetFrequency: Float? {
        guard let base = selectedString?.targetFrequency else { return nil }
        guard capo > 0 else { return base }
        return base * pow(2.0, Float(capo) / 12.0)
    }

    // MARK: - Guided Tuning

    func startGuidedTuning() {
        guidedOrder = selectedTuning.strings.sorted { $0.stringNumber > $1.stringNumber }
        guidedIndex = 0
        guidedTuning = true
        autoMode = false
        tunedStrings = []
        selectedString = guidedOrder.first
    }

    func stopGuidedTuning() {
        guidedTuning = false
        autoAdvanceWork?.cancel()
        autoAdvanceWork = nil
    }

    var guidedProgress: String {
        guard guidedTuning, !guidedOrder.isEmpty else { return "" }
        let stringNum = guidedOrder[min(guidedIndex, guidedOrder.count - 1)].stringNumber
        return "String \(stringNum) · \(guidedIndex + 1) of \(guidedOrder.count)"
    }

    // MARK: - Drone

    private func startDrone() {
        let freq = targetFrequency ?? selectedString?.targetFrequency
            ?? selectedTuning.strings.first?.targetFrequency ?? 440
        drone.play(frequency: freq)
    }

    // MARK: - Frequency Handling

    private func handleFrequency(_ freq: Float) {
        frequencyHistory.append(freq)
        if frequencyHistory.count > historySize { frequencyHistory.removeFirst() }
        let smoothed = frequencyHistory.reduce(0, +) / Float(frequencyHistory.count)

        if autoMode {
            if let closest = selectedTuning.strings.min(by: {
                let f0 = adjustedFreq($0)
                let f1 = adjustedFreq($1)
                return abs(f0 - smoothed) < abs(f1 - smoothed)
            }) {
                let ratio = smoothed / adjustedFreq(closest)
                if ratio > 0.8 && ratio < 1.25 { selectedString = closest }
            }
        }

        let note: Note?
        if let target = targetFrequency {
            let ratio = smoothed / target
            note = (ratio > 0.8 && ratio < 1.25) ? noteRelativeTo(smoothed, target: target) : nil
        } else {
            note = Note.from(frequency: smoothed)
        }

        detectedNote = note
        detectedFrequency = note != nil ? smoothed : nil

        if let note, note.tuningState == .inTune {
            if let string = selectedString { tunedStrings.insert(string.id) }
            if !wasInTune {
                triggerHaptic()
                if guidedTuning { scheduleAutoAdvance() }
            }
        }
        wasInTune = note?.tuningState == .inTune
    }

    private func adjustedFreq(_ string: GuitarString) -> Float {
        guard capo > 0 else { return string.targetFrequency }
        return string.targetFrequency * pow(2.0, Float(capo) / 12.0)
    }

    // Returns a Note with name from the target and cents relative to it
    private func noteRelativeTo(_ smoothed: Float, target: Float) -> Note? {
        guard let base = Note.from(frequency: target) else { return nil }
        let cents = Float(1200.0 * log2(Double(smoothed) / Double(target)))
        return Note(name: base.name, octave: base.octave, cents: min(max(cents, -50), 50))
    }

    private func scheduleAutoAdvance() {
        autoAdvanceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                guard self.guidedTuning else { return }
                self.guidedIndex += 1
                if self.guidedIndex < self.guidedOrder.count {
                    self.selectedString = self.guidedOrder[self.guidedIndex]
                } else {
                    self.guidedTuning = false
                    self.selectedString = nil
                }
            }
        }
        autoAdvanceWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }

    // MARK: - Haptics

    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        hapticEngine = try? CHHapticEngine()
        try? hapticEngine?.start()
    }

    private func triggerHaptic() {
        guard let engine = hapticEngine else { return }
        let events: [CHHapticEvent] = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4),
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
            ], relativeTime: 0.1),
        ]
        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: 0)
    }
}
