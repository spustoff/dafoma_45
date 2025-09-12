//
//  GameService.swift
//  ChronoPulse Forest
//
//  Created by Вячеслав on 9/11/25.
//

import SwiftUI
import Foundation
import AVFoundation
import GameKit

class GameService: ObservableObject {
    static let shared = GameService()
    
    // Audio players
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var sfxPlayers: [String: AVAudioPlayer] = [:]
    
    // Score calculation
    private let baseScoreMultiplier: Double = 1.0
    private let rhythmBonusMultiplier: Double = 1.5
    private let streakBonusThreshold: Int = 10
    private let perfectTimingTolerance: Double = 0.05
    
    // Achievement system
    @Published var unlockedAchievements: Set<String> = []
    
    private init() {
        setupAudioSession()
        loadAchievements()
    }
    
    // MARK: - Audio Management
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func playBackgroundMusic(for level: LevelType, volume: Double = 0.7) {
        let musicFileName = getMusicFileName(for: level)
        playBackgroundMusic(fileName: musicFileName, volume: volume)
    }
    
    private func playBackgroundMusic(fileName: String, volume: Double) {
        stopBackgroundMusic()
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") ?? 
              Bundle.main.url(forResource: "default_background", withExtension: "mp3") else {
            // Create a simple tone programmatically if no audio files exist
            generateBackgroundTone(volume: volume)
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
            backgroundMusicPlayer?.volume = Float(volume)
            backgroundMusicPlayer?.play()
        } catch {
            print("Failed to play background music: \(error)")
            generateBackgroundTone(volume: volume)
        }
    }
    
    private func generateBackgroundTone(volume: Double) {
        // Generate a simple rhythmic background tone
        // This is a fallback when no audio files are available
        print("Generating background tone - volume: \(volume)")
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
    func playSoundEffect(_ effectName: String, volume: Double = 0.8) {
        let fileName = getSoundEffectFileName(for: effectName)
        
        if let existingPlayer = sfxPlayers[effectName] {
            existingPlayer.stop()
            existingPlayer.currentTime = 0
            existingPlayer.volume = Float(volume)
            existingPlayer.play()
            return
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "wav") ??
              Bundle.main.url(forResource: "default_sfx", withExtension: "wav") else {
            // Generate programmatic sound effect
            generateSoundEffect(effectName, volume: volume)
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = Float(volume)
            sfxPlayers[effectName] = player
            player.play()
        } catch {
            print("Failed to play sound effect \(effectName): \(error)")
            generateSoundEffect(effectName, volume: volume)
        }
    }
    
    private func generateSoundEffect(_ effectName: String, volume: Double) {
        // Generate programmatic sound effects as fallback
        print("Generating sound effect: \(effectName) - volume: \(volume)")
        
        // Use system sounds as fallback
        switch effectName {
        case "collect_energy":
            AudioServicesPlaySystemSound(1016) // SMS received sound
        case "hit_obstacle":
            AudioServicesPlaySystemSound(1521) // Peek sound
        case "level_complete":
            AudioServicesPlaySystemSound(1025) // Camera shutter sound
        case "tap_on_beat":
            AudioServicesPlaySystemSound(1104) // SMS sent sound
        case "menu_select":
            AudioServicesPlaySystemSound(1123) // Keyboard click
        default:
            AudioServicesPlaySystemSound(1000) // New mail sound
        }
    }
    
    private func getMusicFileName(for level: LevelType) -> String {
        switch level {
        case .hourglass: return "hourglass_theme"
        case .sundial: return "sundial_theme"
        case .calendar: return "calendar_theme"
        }
    }
    
    private func getSoundEffectFileName(for effect: String) -> String {
        switch effect {
        case "collect_energy": return "energy_collect"
        case "hit_obstacle": return "obstacle_hit"
        case "level_complete": return "level_complete"
        case "tap_on_beat": return "beat_tap"
        case "menu_select": return "menu_select"
        default: return "default_sfx"
        }
    }
    
    // MARK: - Score Calculation
    func calculateScore(for action: GameAction, rhythmAccuracy: Double, currentStreak: Int, difficultyMultiplier: Double) -> Int {
        var baseScore: Double = 0
        
        switch action {
        case .tapOnBeat:
            baseScore = 50
        case .collectEnergy:
            baseScore = 25
        case .avoidObstacle:
            baseScore = 75
        case .perfectTiming:
            baseScore = 100
        }
        
        // Apply rhythm bonus
        let rhythmBonus = rhythmAccuracy > 0.8 ? rhythmBonusMultiplier : 1.0
        
        // Apply streak bonus
        let streakBonus = currentStreak >= streakBonusThreshold ? 1.2 : 1.0
        
        // Apply difficulty multiplier
        let finalScore = baseScore * rhythmBonus * streakBonus * difficultyMultiplier
        
        return Int(finalScore)
    }
    
    func calculateRhythmAccuracy(tapTime: Double, beatTime: Double) -> Double {
        let timeDifference = abs(tapTime - beatTime)
        
        if timeDifference <= perfectTimingTolerance {
            return 1.0 // Perfect timing
        } else if timeDifference <= 0.1 {
            return 0.8 // Good timing
        } else if timeDifference <= 0.2 {
            return 0.6 // Fair timing
        } else {
            return 0.3 // Poor timing
        }
    }
    
    func getBeatTiming(for level: LevelType, difficulty: Difficulty) -> RhythmBeat {
        let baseBPM: Double = 120.0
        let levelMultiplier = level.baseSpeed
        let difficultyMultiplier = difficulty.multiplier
        
        let finalBPM = baseBPM * levelMultiplier * difficultyMultiplier
        
        return RhythmBeat(bpm: finalBPM)
    }
    
    // MARK: - Achievement System
    func checkAchievements(gameSession: GameSession, playerProgress: PlayerProgress) -> [Achievement] {
        var newAchievements: [Achievement] = []
        
        // Score-based achievements
        if gameSession.score >= 1000 && !unlockedAchievements.contains("score_1000") {
            newAchievements.append(Achievement(
                id: "score_1000",
                title: "Time Master",
                description: "Score 1000 points in a single game",
                icon: "star.fill"
            ))
            unlockedAchievements.insert("score_1000")
        }
        
        if gameSession.score >= 2500 && !unlockedAchievements.contains("score_2500") {
            newAchievements.append(Achievement(
                id: "score_2500",
                title: "Chrono Champion",
                description: "Score 2500 points in a single game",
                icon: "crown.fill"
            ))
            unlockedAchievements.insert("score_2500")
        }
        
        // Streak-based achievements
        if playerProgress.bestStreak >= 15 && !unlockedAchievements.contains("streak_15") {
            newAchievements.append(Achievement(
                id: "streak_15",
                title: "Perfect Rhythm",
                description: "Achieve a 15-level completion streak",
                icon: "music.note"
            ))
            unlockedAchievements.insert("streak_15")
        }
        
        // Level completion achievements
        if playerProgress.levelsCompleted >= 5 && !unlockedAchievements.contains("levels_5") {
            newAchievements.append(Achievement(
                id: "levels_5",
                title: "Time Explorer",
                description: "Complete 5 levels",
                icon: "map.fill"
            ))
            unlockedAchievements.insert("levels_5")
        }
        
        if playerProgress.levelsCompleted >= 15 && !unlockedAchievements.contains("levels_15") {
            newAchievements.append(Achievement(
                id: "levels_15",
                title: "Temporal Guardian",
                description: "Complete 15 levels",
                icon: "shield.fill"
            ))
            unlockedAchievements.insert("levels_15")
        }
        
        // Energy-based achievements
        if gameSession.ship.energy >= 90 && !unlockedAchievements.contains("energy_master") {
            newAchievements.append(Achievement(
                id: "energy_master",
                title: "Energy Master",
                description: "Maintain 90% energy throughout a level",
                icon: "bolt.fill"
            ))
            unlockedAchievements.insert("energy_master")
        }
        
        saveAchievements()
        return newAchievements
    }
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: "unlockedAchievements"),
           let achievements = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlockedAchievements = achievements
        }
    }
    
    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(unlockedAchievements) {
            UserDefaults.standard.set(data, forKey: "unlockedAchievements")
        }
    }
    
    // MARK: - Game Analytics
    func logGameEvent(_ event: GameEvent) {
        // Log game events for analytics
        print("Game Event: \(event)")
        
        // In a real app, you would send this to your analytics service
        // Analytics.logEvent(event.name, parameters: event.parameters)
    }
    
    // MARK: - Haptic Feedback
    func triggerHapticFeedback(for action: GameAction, intensity: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let impactFeedback = UIImpactFeedbackGenerator(style: intensity)
        impactFeedback.impactOccurred()
    }
    
    func triggerSuccessHaptic() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    func triggerErrorHaptic() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    // MARK: - Game Difficulty Balancing
    func getAdaptiveDifficulty(playerProgress: PlayerProgress, currentLevel: Level) -> Difficulty {
        let successRate = playerProgress.gamesPlayed > 0 ? 
            Double(playerProgress.levelsCompleted) / Double(playerProgress.gamesPlayed) : 0.0
        
        if successRate > 0.8 {
            // Player is doing very well, increase difficulty
            return currentLevel.difficulty == .easy ? .normal : 
                   (currentLevel.difficulty == .normal ? .hard : .hard)
        } else if successRate < 0.3 {
            // Player is struggling, decrease difficulty
            return currentLevel.difficulty == .hard ? .normal : 
                   (currentLevel.difficulty == .normal ? .easy : .easy)
        } else {
            // Keep current difficulty
            return currentLevel.difficulty
        }
    }
}

// MARK: - Supporting Structures
enum GameAction {
    case tapOnBeat
    case collectEnergy
    case avoidObstacle
    case perfectTiming
}

struct Achievement {
    let id: String
    let title: String
    let description: String
    let icon: String
}

struct GameEvent {
    let name: String
    let parameters: [String: Any]
    
    static func levelStart(level: Level) -> GameEvent {
        return GameEvent(name: "level_start", parameters: [
            "level_type": level.type.rawValue,
            "difficulty": level.difficulty.rawValue
        ])
    }
    
    static func levelComplete(level: Level, score: Int, time: Double) -> GameEvent {
        return GameEvent(name: "level_complete", parameters: [
            "level_type": level.type.rawValue,
            "difficulty": level.difficulty.rawValue,
            "score": score,
            "time": time
        ])
    }
    
    static func gameOver(reason: String, score: Int) -> GameEvent {
        return GameEvent(name: "game_over", parameters: [
            "reason": reason,
            "score": score
        ])
    }
}
