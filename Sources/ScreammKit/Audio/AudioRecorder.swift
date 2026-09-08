import AVFoundation
import Foundation

/// Custom AVAudioEngine capture (chosen over WhisperKit's streaming AudioProcessor in
/// eng review). Taps the mic, converts to 16 kHz mono Float, accumulates the buffer
/// between start() and stop().
///
///   mic ──installTap──▶ [native format] ──AVAudioConverter──▶ [16kHz mono Float] ──▶ buffer
///
/// We own duration (samples.count / 16000) and route-change handling — the reasons we
/// didn't lean on WhisperKit's capture.
public final class AudioRecorder: AudioRecording {

    private let engine = AVAudioEngine()
    private let targetFormat: AVAudioFormat
    private var converter: AVAudioConverter?

    private let lock = NSLock()
    private var samples: [Float] = []
    private var isRunning = false

    /// Fired if the audio route changes mid-recording (e.g. AirPods connect). The
    /// coordinator can choose to abort. Delivered on an arbitrary thread.
    public var onConfigurationChange: (() -> Void)?

    public init() {
        // 16 kHz mono Float32, non-interleaved — exactly what Whisper wants.
        self.targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: whisperSampleRate,
            channels: 1,
            interleaved: false
        )!
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConfigChange),
            name: .AVAudioEngineConfigurationChange,
            object: engine
        )
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    public func start() throws {
        lock.lock(); samples.removeAll(keepingCapacity: true); lock.unlock()

        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0 else {
            throw AudioRecorderError.noInput
        }
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioRecorderError.converterUnavailable
        }
        self.converter = converter

        input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.append(buffer, using: converter)
        }

        engine.prepare()
        try engine.start()
        isRunning = true
    }

    public func stop() -> [Float] {
        guard isRunning else { return [] }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        lock.lock(); let out = samples; lock.unlock()
        return out
    }

    // MARK: - Private

    /// Convert one tap buffer to 16 kHz mono and append. Runs on the realtime audio thread.
    private func append(_ buffer: AVAudioPCMBuffer, using converter: AVAudioConverter) {
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
        guard let out = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }

        var consumed = false
        var error: NSError?
        converter.convert(to: out, error: &error) { _, status in
            if consumed {
                status.pointee = .noDataNow
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        guard error == nil, let channel = out.floatChannelData?[0] else { return }

        let frames = Int(out.frameLength)
        guard frames > 0 else { return }
        let chunk = Array(UnsafeBufferPointer(start: channel, count: frames))
        lock.lock(); samples.append(contentsOf: chunk); lock.unlock()
    }

    @objc private func handleConfigChange() {
        onConfigurationChange?()
    }
}

public enum AudioRecorderError: Error {
    case noInput
    case converterUnavailable
}
