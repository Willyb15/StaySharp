import Foundation

struct Note: Equatable {
    let name: String
    let octave: Int
    let cents: Float

    var displayName: String { "\(name)\(octave)" }

    var tuningState: TuningState {
        if cents > 5 { return .sharp }
        if cents < -5 { return .flat }
        return .inTune
    }

    enum TuningState {
        case flat, inTune, sharp
    }

    static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    static func from(frequency: Float, referencePitch: Double = 440.0) -> Note? {
        guard frequency > 16 && frequency < 8000 else { return nil }
        let semitones = 12.0 * log2(Double(frequency) / referencePitch)
        let rounded = semitones.rounded()
        let midi = Int(rounded) + 69
        guard midi >= 0 && midi <= 127 else { return nil }
        let noteIndex = ((midi % 12) + 12) % 12
        let octave = (midi / 12) - 1
        let perfectFreq = referencePitch * pow(2.0, Double(midi - 69) / 12.0)
        let cents = Float(1200.0 * log2(Double(frequency) / perfectFreq))
        return Note(name: noteNames[noteIndex], octave: octave, cents: min(max(cents, -50), 50))
    }

    static func frequency(for noteName: String, referencePitch: Double = 440.0) -> Float {
        guard let midi = midiNumber(for: noteName) else { return Float(referencePitch) }
        return Float(referencePitch * pow(2.0, Double(midi - 69) / 12.0))
    }

    static func midiNumber(for noteName: String) -> Int? {
        var str = noteName
        guard let lastChar = str.last, let oct = Int(String(lastChar)) else { return nil }
        str = String(str.dropLast())
        let noteIndex: Int
        switch str {
        case "C":         noteIndex = 0
        case "C#", "Db": noteIndex = 1
        case "D":         noteIndex = 2
        case "D#", "Eb": noteIndex = 3
        case "E":         noteIndex = 4
        case "F":         noteIndex = 5
        case "F#", "Gb": noteIndex = 6
        case "G":         noteIndex = 7
        case "G#", "Ab": noteIndex = 8
        case "A":         noteIndex = 9
        case "A#", "Bb": noteIndex = 10
        case "B":         noteIndex = 11
        default: return nil
        }
        return 12 * (oct + 1) + noteIndex
    }
}
