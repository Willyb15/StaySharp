import AVFoundation
import Foundation

class MetronomeAudio {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100

    private lazy var accentBuffer: AVAudioPCMBuffer = makeClickBuffer(frequency: 1500, duration: 0.06)
    private lazy var beatBuffer: AVAudioPCMBuffer = makeClickBuffer(frequency: 900, duration: 0.05)

    init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        engine.attach(playerNode)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        try? engine.start()
    }

    func playAccent() { scheduleBuffer(accentBuffer) }
    func playBeat() { scheduleBuffer(beatBuffer) }

    private func scheduleBuffer(_ buffer: AVAudioPCMBuffer) {
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        playerNode.play()
    }

    private func makeClickBuffer(frequency: Double, duration: Double) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]
        let attackFrames = Int(sampleRate * 0.005)
        let releaseFrames = Int(sampleRate * 0.02)
        let totalFrames = Int(frameCount)
        for i in 0..<totalFrames {
            var envelope: Double = 1.0
            if i < attackFrames {
                envelope = Double(i) / Double(attackFrames)
            } else if i > totalFrames - releaseFrames {
                envelope = Double(totalFrames - i) / Double(releaseFrames)
            }
            let sample = sin(2.0 * .pi * frequency * Double(i) / sampleRate)
            data[i] = Float(sample * envelope * 0.6)
        }
        return buffer
    }
}
