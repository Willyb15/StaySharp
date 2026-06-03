import AVFoundation

enum ClickStyle: String, CaseIterable {
    case classic   = "Classic"
    case woodBlock = "Wood Block"
    case hihat     = "Hi-Hat"
}

class MetronomeAudio {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100

    private var accentBuffers:      [ClickStyle: AVAudioPCMBuffer] = [:]
    private var beatBuffers:        [ClickStyle: AVAudioPCMBuffer] = [:]
    private lazy var subdivisionBuffer = makeSineBuffer(frequency: 1200, duration: 0.025, volume: 0.18)

    var style: ClickStyle = .classic

    init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        engine.attach(playerNode)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        try? engine.start()

        for s in ClickStyle.allCases {
            accentBuffers[s] = makeAccent(style: s)
            beatBuffers[s]   = makeBeat(style: s)
        }
    }

    func playAccent()      { schedule(accentBuffers[style]!) }
    func playBeat()        { schedule(beatBuffers[style]!) }
    func playSubdivision() { schedule(subdivisionBuffer) }

    private func schedule(_ buffer: AVAudioPCMBuffer) {
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        playerNode.play()
    }

    // MARK: - Buffer Factories

    private func makeAccent(style: ClickStyle) -> AVAudioPCMBuffer {
        switch style {
        case .classic:   return makeSineBuffer(frequency: 1500, duration: 0.06, volume: 0.65)
        case .woodBlock: return makeWoodBlock(frequency: 750, duration: 0.05, volume: 0.75)
        case .hihat:     return makeHiHat(duration: 0.04, volume: 0.65)
        }
    }

    private func makeBeat(style: ClickStyle) -> AVAudioPCMBuffer {
        switch style {
        case .classic:   return makeSineBuffer(frequency: 900, duration: 0.05, volume: 0.60)
        case .woodBlock: return makeWoodBlock(frequency: 580, duration: 0.04, volume: 0.65)
        case .hihat:     return makeHiHat(duration: 0.028, volume: 0.45)
        }
    }

    // Smooth sine click (original sound)
    private func makeSineBuffer(frequency: Double, duration: Double, volume: Double) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let total = Int(frameCount)
        let attack = Int(sampleRate * 0.005)
        let release = Int(sampleRate * 0.02)
        for i in 0..<total {
            var env = 1.0
            if i < attack { env = Double(i) / Double(attack) }
            else if i > total - release { env = Double(total - i) / Double(release) }
            data[i] = Float(sin(2.0 * .pi * frequency * Double(i) / sampleRate) * env * volume)
        }
        return buffer
    }

    // Percussive wood block — exponential decay, resonant tone
    private func makeWoodBlock(frequency: Double, duration: Double, volume: Double) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let total = Int(frameCount)
        let decayRate = 1.0 / (sampleRate * 0.018) // fast exponential decay
        for i in 0..<total {
            let env = exp(-Double(i) * decayRate)
            let tone = sin(2.0 * .pi * frequency * Double(i) / sampleRate)
            // Mix tone with a tiny bit of noise for attack transient
            let noise = i < Int(sampleRate * 0.003) ? Double.random(in: -0.3...0.3) : 0
            data[i] = Float((tone * env + noise) * volume)
        }
        return buffer
    }

    // Hi-hat — filtered noise burst with fast exponential decay
    private func makeHiHat(duration: Double, volume: Double) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let total = Int(frameCount)
        let decayRate = 1.0 / (sampleRate * 0.008)
        var prevSample: Float = 0
        for i in 0..<total {
            let env = Float(exp(-Double(i) * decayRate))
            let noise = Float.random(in: -1...1)
            // High-pass: subtract previous to emphasize highs
            let hiPassed = noise - prevSample * 0.65
            prevSample = noise
            data[i] = hiPassed * env * Float(volume)
        }
        return buffer
    }
}
