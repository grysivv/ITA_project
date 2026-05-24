//
//  SpeechManager.swift
//  Italian Learning
//

import AVFoundation
import Observation

@Observable
final class SpeechManager {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String, language: String = "it-IT") {
        // Jeśli lektor aktualnie mówi, zatrzymaj go natychmiast przed nową kwestią
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        
        // Szybkość mowy: domyślna wartość jest optymalna
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        
        // Konfiguracja AVAudioSession jest dostępna tylko dla systemów mobilnych.
        // Ograniczamy ten blok kodu, aby aplikacja poprawnie kompilowała się na macOS.
        #if os(iOS) || os(visionOS) || os(watchOS) || os(tvOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Błąd konfiguracji AVAudioSession: \(error)")
        }
        #endif
        
        synthesizer.speak(utterance)
    }
}
