import AVFoundation
import Foundation

class AudioEngine {
    private var engine = AVAudioEngine()
    private var detector = PitchDetector()
    private(set) var isRunning = false

    var onPitchDetected: ((Float) -> Void)?

    func requestPermissionAndStart(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    do {
                        try self?.start()
                        completion(true)
                    } catch {
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }
    }

    private func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        detector = PitchDetector(sampleRate: Float(format.sampleRate))

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self,
                  let channelData = buffer.floatChannelData?[0] else { return }
            let count = Int(buffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: channelData, count: count))
            if let pitch = self.detector.detectPitch(in: samples) {
                DispatchQueue.main.async { self.onPitchDetected?(pitch) }
            }
        }

        try engine.start()
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRunning = false
    }
}
