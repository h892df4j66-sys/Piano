import SwiftUI
import AVFoundation
struct PianoKey: Identifiable {
    let id = UUID()
    let note: String
    let fileName: String
    let isBlack: Bool
    let keyChar: String }
struct ContentView: View {
    let keys: [PianoKey] = [
        PianoKey(note: "C",  fileName: "C4",  isBlack: false, keyChar: "A"),
        PianoKey(note: "C#", fileName: "Cs4", isBlack: true,  keyChar: "W"),
        PianoKey(note: "D",  fileName: "D4",  isBlack: false, keyChar: "S"),
        PianoKey(note: "D#", fileName: "Ds4", isBlack: true,  keyChar: "E"),
        PianoKey(note: "E",  fileName: "E4",  isBlack: false, keyChar: "D"),
        PianoKey(note: "F",  fileName: "F4",  isBlack: false, keyChar: "F"),
        PianoKey(note: "F#", fileName: "Fs4", isBlack: true,  keyChar: "T"),
        PianoKey(note: "G",  fileName: "G4",  isBlack: false, keyChar: "G"),
        PianoKey(note: "G#", fileName: "Gs4", isBlack: true,  keyChar: "Y"),
        PianoKey(note: "A",  fileName: "A4",  isBlack: false, keyChar: "H"),
        PianoKey(note: "A#", fileName: "As4", isBlack: true,  keyChar: "U"),
        PianoKey(note: "B",  fileName: "B4",  isBlack: false, keyChar: "J"),
        PianoKey(note: "C5", fileName: "C5",  isBlack: false, keyChar: "K"), ]
@State private var pressedKey: UUID? = nil
@State private var lastNote: String = ""
@State private var audioPlayers: [String: AVAudioPlayer] = [:]

var body: some View {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.1, green: 0.1, blue: 0.2),
                     Color(red: 0.2, green: 0.1, blue: 0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 30) {
            VStack(spacing: 8) {
                Text("🎹 Пианино")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(lastNote.isEmpty ? "Нажми на клавишу" : "Нота: \(lastNote)")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
                    .animation(.easeOut, value: lastNote)
            }
            .padding(.top, 20)

            Spacer()

            HStack(spacing: 2) {
                ForEach(keys) { key in
                    KeyView(
                        key: key,
                        isPressed: pressedKey == key.id,
                        onPress: { playNote(key) }
                    )
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 320)

            Spacer()
        }
    }
    .onAppear {
        prepareAudio()
    }
}

func prepareAudio() {
    for key in keys {
        generateFallbackTone(for: key)
    }
}

func playNote(_ key: PianoKey) {
    pressedKey = key.id
    lastNote = key.note

    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()

    if let player = audioPlayers[key.fileName] {
        player.currentTime = 0
        player.play()
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        if pressedKey == key.id {
            pressedKey = nil
        }
    }
}

func frequency(for note: String) -> Double {
    let freqs: [String: Double] = [
        "C": 261.63, "C#": 277.18, "D": 293.66, "D#": 311.13,
        "E": 329.63, "F": 349.23, "F#": 369.99, "G": 392.00,
        "G#": 415.30, "A": 440.00, "A#": 466.16, "B": 493.88,
        "C5": 523.25
    ]
    return freqs[note] ?? 440.0
}

func generateFallbackTone(for key: PianoKey) {
    let freq = frequency(for: key.note)
    let sampleRate: Double = 44100
    let duration: Double = 1.2
    let frameCount = Int(sampleRate * duration)

    var samples = [Float](repeating: 0, count: frameCount)

    for i in 0..<frameCount {
        let t = Double(i) / sampleRate
        let value =
            0.6 * sin(2.0 * .pi * freq * t) +
            0.3 * sin(2.0 * .pi * freq * 2 * t) +
            0.1 * sin(2.0 * .pi * freq * 3 * t)
        let envelope = exp(-3.0 * t)
        samples[i] = Float(value * envelope * 0.5)
    }

    let wavData = makeWAV(samples: samples, sampleRate: Int(sampleRate))

    if let player = try? AVAudioPlayer(data: wavData) {


player.prepareToPlay()
        audioPlayers[key.fileName] = player
    }
}

func makeWAV(samples: [Float], sampleRate: Int) -> Data {
    var data = Data()
    let byteRate = sampleRate * 2

    data.append("RIFF".data(using: .ascii)!)
    data.append(UInt32(36 + samples.count * 2).littleEndianData)
    data.append("WAVE".data(using: .ascii)!)

    data.append("fmt ".data(using: .ascii)!)
    data.append(UInt32(16).littleEndianData)
    data.append(UInt16(1).littleEndianData)
    data.append(UInt16(1).littleEndianData)
    data.append(UInt32(sampleRate).littleEndianData)
    data.append(UInt32(byteRate).littleEndianData)
    data.append(UInt16(2).littleEndianData)
    data.append(UInt16(16).littleEndianData)

    data.append("data".data(using: .ascii)!)
    data.append(UInt32(samples.count * 2).littleEndianData)

    for sample in samples {
        let intSample = Int16(max(-1, min(1, sample)) * 32767)
        data.append(intSample.littleEndianData)
    }

    return data
}
}
struct KeyView: View {
    let key: PianoKey
    let isPressed: Bool
    let onPress: () -> Void
var body: some View {
    Button(action: onPress) {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 6)
                .fill(key.isBlack ? Color.black : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 3)

            VStack(spacing: 4) {
                Text(key.note)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(key.isBlack ? .white : .black.opacity(0.6))

                Text(key.keyChar)
                    .font(.caption2)
                    .foregroundColor(key.isBlack ? .white.opacity(0.7) : .gray)
                    .padding(4)
                    .background(
                        Circle()
                            .fill(key.isBlack ? Color.white.opacity(0.2) : Color.gray.opacity(0.2))
                    )
            }
            .padding(.bottom, 20)
        }
    }
    .scaleEffect(isPressed ? 0.95 : 1.0)
    .brightness(isPressed ? 0.2 : 0)
    .animation(.easeOut(duration: 0.08), value: isPressed)
}
}
extension UInt32 { var littleEndianData: Data { var value = self.littleEndian
    return Data(bytes: &value, count: 4) } }
extension UInt16 { var littleEndianData: Data { var value = self.littleEndian
    return Data(bytes: &value, count: 2) } }
extension Int16 { var littleEndianData: Data { var value = self.littleEndian
    return Data(bytes: &value, count: 2) } }
#Preview {
    ContentView()
}
