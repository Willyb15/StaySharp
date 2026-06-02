import Foundation
import Combine
import SwiftUI

@MainActor
class MetronomeViewModel: ObservableObject {
    @Published var bpm: Double = 120
    @Published var isPlaying = false
    @Published var currentBeat = 0
    @Published var activeBeat = 0  // which bar is visually lit — set before increment
    @Published var beatsPerMeasure = 4
    @Published var beatFlash = false

    private var timer: AnyCancellable?
    private let audio = MetronomeAudio()
    private var tapTimes: [Date] = []

    var interval: TimeInterval { 60.0 / bpm }

    func togglePlay() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    func tapTempo() {
        let now = Date()
        if let last = tapTimes.last, now.timeIntervalSince(last) > 3.0 {
            tapTimes.removeAll()
        }
        tapTimes.append(now)

        // Keep last 8 taps
        if tapTimes.count > 8 { tapTimes.removeFirst() }

        // Need at least 2 taps to calculate
        guard tapTimes.count >= 2 else { return }

        let intervals = zip(tapTimes, tapTimes.dropFirst()).map { $1.timeIntervalSince($0) }
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let newBPM = 60.0 / avgInterval

        if newBPM >= 20 && newBPM <= 300 {
            bpm = newBPM.rounded()
            if isPlaying {
                stop()
                start()
            }
        }
    }

    private func start() {
        isPlaying = true
        currentBeat = 0
        tick()
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func stop() {
        isPlaying = false
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        let beat = currentBeat % beatsPerMeasure
        activeBeat = beat  // set visual BEFORE incrementing so bar matches audio

        if beat == 0 {
            audio.playAccent()
        } else {
            audio.playBeat()
        }

        withAnimation(.easeOut(duration: 0.05)) { beatFlash = true }
        // Hold for nearly the full beat, fade just before next beat fires
        let holdDuration = max(interval - 0.08, 0.1)
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) {
            withAnimation(.easeIn(duration: 0.06)) { self.beatFlash = false }
        }

        currentBeat += 1
    }
}
