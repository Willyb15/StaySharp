import Foundation
import Combine
import SwiftUI

struct TimeSignature: Equatable {
    let beats: Int
    let noteValue: Int      // 4=quarter, 8=eighth gets the beat
    let defaultAccents: Set<Int>
    var label: String { "\(beats)/\(noteValue)" }

    init(beats: Int, noteValue: Int, defaultAccents: Set<Int>? = nil) {
        self.beats = beats
        self.noteValue = noteValue
        self.defaultAccents = defaultAccents ?? [0]
    }

    static let presets: [TimeSignature] = [
        TimeSignature(beats: 2,  noteValue: 4),
        TimeSignature(beats: 3,  noteValue: 4),
        TimeSignature(beats: 4,  noteValue: 4),
        TimeSignature(beats: 5,  noteValue: 4),
        TimeSignature(beats: 6,  noteValue: 4),
        TimeSignature(beats: 7,  noteValue: 4),
        TimeSignature(beats: 6,  noteValue: 8, defaultAccents: [0, 3]),
        TimeSignature(beats: 7,  noteValue: 8),
        TimeSignature(beats: 9,  noteValue: 8, defaultAccents: [0, 3, 6]),
        TimeSignature(beats: 12, noteValue: 8, defaultAccents: [0, 3, 6, 9]),
    ]
}

@MainActor
class MetronomeViewModel: ObservableObject {
    @Published var bpm: Double = 120
    @Published var isPlaying = false
    @Published var currentBeat = 0
    @Published var activeBeat = 0
    @Published var beatFlash = false
    @Published var subdivision: Int = 1
    @Published var accentedBeats: Set<Int> = [0]
    @Published var clickStyle: ClickStyle = .classic {
        didSet { audio.style = clickStyle }
    }

    @Published var timeSignature = TimeSignature(beats: 4, noteValue: 4) {
        didSet {
            accentedBeats = timeSignature.defaultAccents
            if isPlaying { restart() }
        }
    }

    private var timer: AnyCancellable?
    private let audio = MetronomeAudio()
    private var tapTimes: [Date] = []
    private var subBeatCount = 0

    var beatsPerMeasure: Int { timeSignature.beats }
    var interval: TimeInterval { 60.0 / bpm }
    // For 7/8 the beat note is an eighth note (half a quarter)
    var beatInterval: TimeInterval { interval * 4.0 / Double(timeSignature.noteValue) }
    var subBeatInterval: TimeInterval { beatInterval / Double(subdivision) }

    func togglePlay() {
        if isPlaying { stop() } else { start() }
    }

    func toggleAccent(beat: Int) {
        if accentedBeats.contains(beat) && accentedBeats.count > 1 {
            accentedBeats.remove(beat)
        } else {
            accentedBeats.insert(beat)
        }
    }

    func tapTempo() {
        let now = Date()
        if let last = tapTimes.last, now.timeIntervalSince(last) > 3.0 {
            tapTimes.removeAll()
        }
        tapTimes.append(now)
        if tapTimes.count > 8 { tapTimes.removeFirst() }
        guard tapTimes.count >= 2 else { return }

        let intervals = zip(tapTimes, tapTimes.dropFirst()).map { $1.timeIntervalSince($0) }
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let newBPM = 60.0 / avgInterval

        if newBPM >= 20 && newBPM <= 300 {
            bpm = newBPM.rounded()
            if isPlaying { restart() }
        }
    }

    func restart() {
        stop()
        start()
    }

    private func start() {
        isPlaying = true
        currentBeat = 0
        subBeatCount = 0
        let si = subBeatInterval
        tick()
        timer = Timer.publish(every: si, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func stop() {
        isPlaying = false
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        let isMainBeat = subBeatCount % subdivision == 0

        if isMainBeat {
            let beat = currentBeat % beatsPerMeasure
            activeBeat = beat

            if accentedBeats.contains(beat) {
                audio.playAccent()
            } else {
                audio.playBeat()
            }

            withAnimation(.easeOut(duration: 0.05)) { beatFlash = true }
            let holdDuration = max(beatInterval - 0.08, 0.1)
            DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) {
                withAnimation(.easeIn(duration: 0.06)) { self.beatFlash = false }
            }
            currentBeat += 1
        } else {
            audio.playSubdivision()
        }

        subBeatCount += 1
    }
}
