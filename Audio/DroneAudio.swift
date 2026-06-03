import AVFoundation

class DroneAudio {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100

    init() {
        engine.attach(playerNode)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
    }

    func play(frequency: Float) {
        if !engine.isRunning { try? engine.start() }
        playerNode.stop()
        let buffer = makeDroneBuffer(frequency: Double(frequency))
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        playerNode.play()
    }

    func stop() {
        playerNode.stop()
    }

    private func makeDroneBuffer(frequency: Double) -> AVAudioPCMBuffer {
        // One full fundamental cycle — harmonics complete integer multiples, so loop is seamless
        let framesPerCycle = max(1, Int(round(sampleRate / frequency)))
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(framesPerCycle))!
        buffer.frameLength = AVAudioFrameCount(framesPerCycle)
        let data = buffer.floatChannelData![0]

        for i in 0..<framesPerCycle {
            let t = 2.0 * .pi * Double(i) / Double(framesPerCycle)
            // Harmonic series — warm pitch-pipe tone, useful for tuning by ear
            let sample = sin(t)        * 1.00   // fundamental
                       + sin(2.0 * t) * 0.35   // 2nd harmonic (octave)
                       + sin(3.0 * t) * 0.15   // 3rd harmonic (fifth)
                       + sin(4.0 * t) * 0.07   // 4th harmonic
                       + sin(5.0 * t) * 0.03   // 5th harmonic
            // Normalize sum (1.0+0.35+0.15+0.07+0.03 = 1.60) then scale volume
            data[i] = Float(sample / 1.60 * 0.60)
        }
        return buffer
    }
}
