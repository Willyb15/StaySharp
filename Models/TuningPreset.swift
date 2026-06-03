import Foundation

enum Instrument: String, CaseIterable {
    case guitar      = "Guitar"
    case bass        = "Bass"
    case sevenString = "7-String Guitar"
    case ukulele     = "Ukulele"
    case banjo       = "Banjo"
    case mandolin    = "Mandolin"
    case violin      = "Violin"
}

struct GuitarString: Identifiable, Equatable {
    let id = UUID()
    let noteName: String
    let stringNumber: Int  // 1 = highest pitch, N = lowest pitch
    var targetFrequency: Float { Note.frequency(for: noteName) }

    static func == (lhs: GuitarString, rhs: GuitarString) -> Bool { lhs.id == rhs.id }
}

struct TuningPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let instrument: Instrument
    let strings: [GuitarString]

    var stringsHighToLow: [GuitarString] {
        strings.sorted { $0.stringNumber < $1.stringNumber }
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: TuningPreset, rhs: TuningPreset) -> Bool { lhs.id == rhs.id }

    static func forInstrument(_ instrument: Instrument) -> [TuningPreset] {
        all.filter { $0.instrument == instrument }
    }

    static let all: [TuningPreset] = guitarPresets + bassPresets + sevenStringPresets + ukulelePresets + banjoPresets + mandolinPresets + violinPresets

    // MARK: - Guitar (6-string)

    static let guitarPresets: [TuningPreset] = [
        TuningPreset(name: "Standard", description: "E A D G B e", instrument: .guitar, strings: [
            GuitarString(noteName: "E2", stringNumber: 6),
            GuitarString(noteName: "A2", stringNumber: 5),
            GuitarString(noteName: "D3", stringNumber: 4),
            GuitarString(noteName: "G3", stringNumber: 3),
            GuitarString(noteName: "B3", stringNumber: 2),
            GuitarString(noteName: "E4", stringNumber: 1),
        ]),
        TuningPreset(name: "Drop D", description: "D A D G B e", instrument: .guitar, strings: [
            GuitarString(noteName: "D2", stringNumber: 6),
            GuitarString(noteName: "A2", stringNumber: 5),
            GuitarString(noteName: "D3", stringNumber: 4),
            GuitarString(noteName: "G3", stringNumber: 3),
            GuitarString(noteName: "B3", stringNumber: 2),
            GuitarString(noteName: "E4", stringNumber: 1),
        ]),
        TuningPreset(name: "Open G", description: "D G D G B D", instrument: .guitar, strings: [
            GuitarString(noteName: "D2", stringNumber: 6),
            GuitarString(noteName: "G2", stringNumber: 5),
            GuitarString(noteName: "D3", stringNumber: 4),
            GuitarString(noteName: "G3", stringNumber: 3),
            GuitarString(noteName: "B3", stringNumber: 2),
            GuitarString(noteName: "D4", stringNumber: 1),
        ]),
        TuningPreset(name: "Open D", description: "D A D F# A D", instrument: .guitar, strings: [
            GuitarString(noteName: "D2", stringNumber: 6),
            GuitarString(noteName: "A2", stringNumber: 5),
            GuitarString(noteName: "D3", stringNumber: 4),
            GuitarString(noteName: "F#3", stringNumber: 3),
            GuitarString(noteName: "A3", stringNumber: 2),
            GuitarString(noteName: "D4", stringNumber: 1),
        ]),
        TuningPreset(name: "DADGAD", description: "D A D G A D", instrument: .guitar, strings: [
            GuitarString(noteName: "D2", stringNumber: 6),
            GuitarString(noteName: "A2", stringNumber: 5),
            GuitarString(noteName: "D3", stringNumber: 4),
            GuitarString(noteName: "G3", stringNumber: 3),
            GuitarString(noteName: "A3", stringNumber: 2),
            GuitarString(noteName: "D4", stringNumber: 1),
        ]),
        TuningPreset(name: "Open E", description: "E B E G# B E", instrument: .guitar, strings: [
            GuitarString(noteName: "E2", stringNumber: 6),
            GuitarString(noteName: "B2", stringNumber: 5),
            GuitarString(noteName: "E3", stringNumber: 4),
            GuitarString(noteName: "G#3", stringNumber: 3),
            GuitarString(noteName: "B3", stringNumber: 2),
            GuitarString(noteName: "E4", stringNumber: 1),
        ]),
        TuningPreset(name: "Open A", description: "E A E A C# E", instrument: .guitar, strings: [
            GuitarString(noteName: "E2", stringNumber: 6),
            GuitarString(noteName: "A2", stringNumber: 5),
            GuitarString(noteName: "E3", stringNumber: 4),
            GuitarString(noteName: "A3", stringNumber: 3),
            GuitarString(noteName: "C#4", stringNumber: 2),
            GuitarString(noteName: "E4", stringNumber: 1),
        ]),
        TuningPreset(name: "Half Step Down", description: "Eb Ab Db Gb Bb Eb", instrument: .guitar, strings: [
            GuitarString(noteName: "Eb2", stringNumber: 6),
            GuitarString(noteName: "Ab2", stringNumber: 5),
            GuitarString(noteName: "Db3", stringNumber: 4),
            GuitarString(noteName: "Gb3", stringNumber: 3),
            GuitarString(noteName: "Bb3", stringNumber: 2),
            GuitarString(noteName: "Eb4", stringNumber: 1),
        ]),
        TuningPreset(name: "Full Step Down", description: "D G C F A D", instrument: .guitar, strings: [
            GuitarString(noteName: "D2", stringNumber: 6),
            GuitarString(noteName: "G2", stringNumber: 5),
            GuitarString(noteName: "C3", stringNumber: 4),
            GuitarString(noteName: "F3", stringNumber: 3),
            GuitarString(noteName: "A3", stringNumber: 2),
            GuitarString(noteName: "D4", stringNumber: 1),
        ]),
        TuningPreset(name: "Drop C", description: "C G C F A D", instrument: .guitar, strings: [
            GuitarString(noteName: "C2", stringNumber: 6),
            GuitarString(noteName: "G2", stringNumber: 5),
            GuitarString(noteName: "C3", stringNumber: 4),
            GuitarString(noteName: "F3", stringNumber: 3),
            GuitarString(noteName: "A3", stringNumber: 2),
            GuitarString(noteName: "D4", stringNumber: 1),
        ]),
    ]

    // MARK: - Bass Guitar

    static let bassPresets: [TuningPreset] = [
        TuningPreset(name: "Standard", description: "E A D G", instrument: .bass, strings: [
            GuitarString(noteName: "E1", stringNumber: 4),
            GuitarString(noteName: "A1", stringNumber: 3),
            GuitarString(noteName: "D2", stringNumber: 2),
            GuitarString(noteName: "G2", stringNumber: 1),
        ]),
        TuningPreset(name: "Drop D", description: "D A D G", instrument: .bass, strings: [
            GuitarString(noteName: "D1", stringNumber: 4),
            GuitarString(noteName: "A1", stringNumber: 3),
            GuitarString(noteName: "D2", stringNumber: 2),
            GuitarString(noteName: "G2", stringNumber: 1),
        ]),
        TuningPreset(name: "5-String", description: "B E A D G", instrument: .bass, strings: [
            GuitarString(noteName: "B0", stringNumber: 5),
            GuitarString(noteName: "E1", stringNumber: 4),
            GuitarString(noteName: "A1", stringNumber: 3),
            GuitarString(noteName: "D2", stringNumber: 2),
            GuitarString(noteName: "G2", stringNumber: 1),
        ]),
        TuningPreset(name: "Half Step Down", description: "Eb Ab Db Gb", instrument: .bass, strings: [
            GuitarString(noteName: "Eb1", stringNumber: 4),
            GuitarString(noteName: "Ab1", stringNumber: 3),
            GuitarString(noteName: "Db2", stringNumber: 2),
            GuitarString(noteName: "Gb2", stringNumber: 1),
        ]),
    ]

    // MARK: - 7-String Guitar

    static let sevenStringPresets: [TuningPreset] = [
        TuningPreset(name: "Standard", description: "B E A D G B e", instrument: .sevenString, strings: [
            GuitarString(noteName: "B1", stringNumber: 7),
            GuitarString(noteName: "E2", stringNumber: 6),
            GuitarString(noteName: "A2", stringNumber: 5),
            GuitarString(noteName: "D3", stringNumber: 4),
            GuitarString(noteName: "G3", stringNumber: 3),
            GuitarString(noteName: "B3", stringNumber: 2),
            GuitarString(noteName: "E4", stringNumber: 1),
        ]),
        TuningPreset(name: "Drop A", description: "A E A D G B e", instrument: .sevenString, strings: [
            GuitarString(noteName: "A1", stringNumber: 7),
            GuitarString(noteName: "E2", stringNumber: 6),
            GuitarString(noteName: "A2", stringNumber: 5),
            GuitarString(noteName: "D3", stringNumber: 4),
            GuitarString(noteName: "G3", stringNumber: 3),
            GuitarString(noteName: "B3", stringNumber: 2),
            GuitarString(noteName: "E4", stringNumber: 1),
        ]),
    ]

    // MARK: - Ukulele

    static let ukulelePresets: [TuningPreset] = [
        TuningPreset(name: "Standard", description: "G C E A", instrument: .ukulele, strings: [
            GuitarString(noteName: "G4", stringNumber: 4),
            GuitarString(noteName: "C4", stringNumber: 3),
            GuitarString(noteName: "E4", stringNumber: 2),
            GuitarString(noteName: "A4", stringNumber: 1),
        ]),
        TuningPreset(name: "Low G", description: "G C E A (low)", instrument: .ukulele, strings: [
            GuitarString(noteName: "G3", stringNumber: 4),
            GuitarString(noteName: "C4", stringNumber: 3),
            GuitarString(noteName: "E4", stringNumber: 2),
            GuitarString(noteName: "A4", stringNumber: 1),
        ]),
        TuningPreset(name: "Baritone", description: "D G B E", instrument: .ukulele, strings: [
            GuitarString(noteName: "D3", stringNumber: 4),
            GuitarString(noteName: "G3", stringNumber: 3),
            GuitarString(noteName: "B3", stringNumber: 2),
            GuitarString(noteName: "E4", stringNumber: 1),
        ]),
    ]

    // MARK: - Banjo

    static let banjoPresets: [TuningPreset] = [
        TuningPreset(name: "Open G (5-string)", description: "G D G B D", instrument: .banjo, strings: [
            GuitarString(noteName: "G4", stringNumber: 5),
            GuitarString(noteName: "D3", stringNumber: 4),
            GuitarString(noteName: "G3", stringNumber: 3),
            GuitarString(noteName: "B3", stringNumber: 2),
            GuitarString(noteName: "D4", stringNumber: 1),
        ]),
        TuningPreset(name: "Double C (5-string)", description: "G C G C D", instrument: .banjo, strings: [
            GuitarString(noteName: "G4", stringNumber: 5),
            GuitarString(noteName: "C3", stringNumber: 4),
            GuitarString(noteName: "G3", stringNumber: 3),
            GuitarString(noteName: "C4", stringNumber: 2),
            GuitarString(noteName: "D4", stringNumber: 1),
        ]),
        TuningPreset(name: "Standard (4-string)", description: "C G D A", instrument: .banjo, strings: [
            GuitarString(noteName: "C3", stringNumber: 4),
            GuitarString(noteName: "G3", stringNumber: 3),
            GuitarString(noteName: "D4", stringNumber: 2),
            GuitarString(noteName: "A4", stringNumber: 1),
        ]),
    ]

    // MARK: - Mandolin

    static let mandolinPresets: [TuningPreset] = [
        TuningPreset(name: "Standard", description: "G D A E", instrument: .mandolin, strings: [
            GuitarString(noteName: "G3", stringNumber: 4),
            GuitarString(noteName: "D4", stringNumber: 3),
            GuitarString(noteName: "A4", stringNumber: 2),
            GuitarString(noteName: "E5", stringNumber: 1),
        ]),
        TuningPreset(name: "Open G", description: "G D G B", instrument: .mandolin, strings: [
            GuitarString(noteName: "G3", stringNumber: 4),
            GuitarString(noteName: "D4", stringNumber: 3),
            GuitarString(noteName: "G4", stringNumber: 2),
            GuitarString(noteName: "B4", stringNumber: 1),
        ]),
    ]

    // MARK: - Violin

    static let violinPresets: [TuningPreset] = [
        TuningPreset(name: "Standard", description: "G D A E", instrument: .violin, strings: [
            GuitarString(noteName: "G3", stringNumber: 4),
            GuitarString(noteName: "D4", stringNumber: 3),
            GuitarString(noteName: "A4", stringNumber: 2),
            GuitarString(noteName: "E5", stringNumber: 1),
        ]),
        TuningPreset(name: "Scordatura (A-E-A-E)", description: "A E A E", instrument: .violin, strings: [
            GuitarString(noteName: "A3", stringNumber: 4),
            GuitarString(noteName: "E4", stringNumber: 3),
            GuitarString(noteName: "A4", stringNumber: 2),
            GuitarString(noteName: "E5", stringNumber: 1),
        ]),
    ]
}
