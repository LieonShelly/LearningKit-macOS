//
//  SoundManager.swift
//  GammarTeacher
//
//  Created by Renjun Li on 2025/12/18.
//


import AppKit
import AVFoundation

class SoundManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SoundManager()
    
    private let clickSound: NSSound?
    private var synthesizer = AVSpeechSynthesizer()
    
    private override init() {
        self.clickSound = NSSound(named: "click")
        super.init()
        synthesizer.delegate = self
    }
    
    func playSuccess() {
        NSSound(named: "Glass")?.play()
    }
    
    func playError() {
        NSSound(named: "Basso")?.play()
    }
    
    func playKeyClick() {
        if let sound = clickSound {
            if sound.isPlaying { sound.stop() }
            sound.play()
        } else {
            NSSound(named: "Tink")?.play()
        }
    }
    
    func speak(_ text: String, rate: Float = 0.5) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        utterance.rate = rate
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
}
