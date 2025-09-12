//
//  GameModel.swift
//  ChronoPulse Forest
//
//  Created by Вячеслав on 9/11/25.
//

import SwiftUI
import Foundation

// MARK: - Game State
enum GameState {
    case onboarding
    case menu
    case playing
    case paused
    case gameOver
    case settings
}

// MARK: - Level Types
enum LevelType: String, CaseIterable {
    case hourglass = "Hourglass"
    case sundial = "Sundial"
    case calendar = "Calendar"
    
    var icon: String {
        switch self {
        case .hourglass: return "hourglass"
        case .sundial: return "sun.max"
        case .calendar: return "calendar"
        }
    }
    
    var baseSpeed: Double {
        switch self {
        case .hourglass: return 1.0
        case .sundial: return 1.2
        case .calendar: return 1.5
        }
    }
    
    var rhythmPattern: [Double] {
        switch self {
        case .hourglass: return [1.0, 0.5, 1.0, 0.5]
        case .sundial: return [0.75, 0.75, 0.5, 1.0]
        case .calendar: return [0.5, 0.5, 0.5, 1.5]
        }
    }
}

// MARK: - Difficulty
enum Difficulty: String, CaseIterable {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"
    
    var multiplier: Double {
        switch self {
        case .easy: return 0.8
        case .normal: return 1.0
        case .hard: return 1.3
        }
    }
}

// MARK: - Game Objects
struct TimeShip {
    var position: CGPoint
    var velocity: CGVector
    var energy: Double
    var maxEnergy: Double
    var isInvincible: Bool
    var invincibilityTime: Double
    
    init() {
        self.position = CGPoint(x: 100, y: 200)
        self.velocity = CGVector(dx: 0, dy: 0)
        self.energy = 100.0
        self.maxEnergy = 100.0
        self.isInvincible = false
        self.invincibilityTime = 0.0
    }
    
    mutating func move(to point: CGPoint) {
        self.position = point
    }
    
    mutating func addEnergy(_ amount: Double) {
        self.energy = min(maxEnergy, energy + amount)
    }
    
    mutating func drainEnergy(_ amount: Double) {
        self.energy = max(0, energy - amount)
    }
    
    mutating func activateInvincibility(duration: Double) {
        self.isInvincible = true
        self.invincibilityTime = duration
    }
    
    mutating func updateInvincibility(deltaTime: Double) {
        if isInvincible {
            invincibilityTime -= deltaTime
            if invincibilityTime <= 0 {
                isInvincible = false
                invincibilityTime = 0
            }
        }
    }
}

struct TimeEnergy {
    let id = UUID()
    var position: CGPoint
    var value: Double
    var isCollected: Bool
    
    init(position: CGPoint, value: Double = 20.0) {
        self.position = position
        self.value = value
        self.isCollected = false
    }
}

struct Obstacle {
    let id = UUID()
    var position: CGPoint
    var size: CGSize
    var velocity: CGVector
    var isActive: Bool
    
    init(position: CGPoint, size: CGSize = CGSize(width: 40, height: 40)) {
        self.position = position
        self.size = size
        self.velocity = CGVector(dx: -150, dy: 0)
        self.isActive = true
    }
}

// MARK: - Level Data
struct Level {
    let id = UUID()
    let type: LevelType
    let difficulty: Difficulty
    let duration: Double
    let targetScore: Int
    var isUnlocked: Bool
    var bestScore: Int
    var isCompleted: Bool
    
    init(type: LevelType, difficulty: Difficulty, duration: Double = 120.0, targetScore: Int = 1000) {
        self.type = type
        self.difficulty = difficulty
        self.duration = duration
        self.targetScore = targetScore
        self.isUnlocked = false
        self.bestScore = 0
        self.isCompleted = false
    }
}

// MARK: - Game Session
struct GameSession {
    let id = UUID()
    var level: Level
    var ship: TimeShip
    var obstacles: [Obstacle]
    var energyPickups: [TimeEnergy]
    var score: Int
    var timeRemaining: Double
    var rhythmBeat: Double
    var lastBeatTime: Double
    var gameState: GameState
    var isPaused: Bool
    
    init(level: Level) {
        self.level = level
        self.ship = TimeShip()
        self.obstacles = []
        self.energyPickups = []
        self.score = 0
        self.timeRemaining = level.duration
        self.rhythmBeat = 0.0
        self.lastBeatTime = 0.0
        self.gameState = .playing
        self.isPaused = false
    }
    
    mutating func addScore(_ points: Int) {
        self.score += points
    }
    
    mutating func spawnObstacle(at position: CGPoint) {
        let obstacle = Obstacle(position: position)
        obstacles.append(obstacle)
    }
    
    mutating func spawnEnergyPickup(at position: CGPoint) {
        let energy = TimeEnergy(position: position)
        energyPickups.append(energy)
    }
    
    mutating func updateTime(deltaTime: Double) {
        timeRemaining -= deltaTime
        if timeRemaining <= 0 {
            gameState = .gameOver
        }
    }
    
    mutating func pause() {
        isPaused = true
        gameState = .paused
    }
    
    mutating func resume() {
        isPaused = false
        gameState = .playing
    }
}

// MARK: - Player Progress
struct PlayerProgress {
    var totalScore: Int
    var gamesPlayed: Int
    var levelsCompleted: Int
    var bestStreak: Int
    var currentStreak: Int
    var unlockedLevels: Set<String>
    var achievements: Set<String>
    
    init() {
        self.totalScore = 0
        self.gamesPlayed = 0
        self.levelsCompleted = 0
        self.bestStreak = 0
        self.currentStreak = 0
        self.unlockedLevels = ["hourglass_easy"] // Start with first level unlocked
        self.achievements = []
    }
    
    mutating func completeLevel(level: Level, score: Int) {
        gamesPlayed += 1
        totalScore += score
        
        if score >= level.targetScore {
            levelsCompleted += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            
            // Unlock next level
            unlockNextLevel(for: level)
        } else {
            currentStreak = 0
        }
    }
    
    private mutating func unlockNextLevel(for completedLevel: Level) {
        let levelKey = "\(completedLevel.type.rawValue.lowercased())_\(completedLevel.difficulty.rawValue.lowercased())"
        unlockedLevels.insert(levelKey)
        
        // Logic to unlock next difficulty or level type
        switch completedLevel.difficulty {
        case .easy:
            let nextKey = "\(completedLevel.type.rawValue.lowercased())_normal"
            unlockedLevels.insert(nextKey)
        case .normal:
            let nextKey = "\(completedLevel.type.rawValue.lowercased())_hard"
            unlockedLevels.insert(nextKey)
        case .hard:
            // Unlock next level type on easy
            if let nextType = LevelType.allCases.first(where: { $0.rawValue > completedLevel.type.rawValue }) {
                let nextKey = "\(nextType.rawValue.lowercased())_easy"
                unlockedLevels.insert(nextKey)
            }
        }
    }
}

// MARK: - Game Settings
struct GameSettings {
    var soundEnabled: Bool
    var hapticEnabled: Bool
    var difficulty: Difficulty
    var musicVolume: Double
    var sfxVolume: Double
    
    init() {
        self.soundEnabled = true
        self.hapticEnabled = true
        self.difficulty = .normal
        self.musicVolume = 0.7
        self.sfxVolume = 0.8
    }
}

// MARK: - Rhythm System
struct RhythmBeat {
    var currentBeat: Int
    var beatsPerMinute: Double
    var beatInterval: Double
    var nextBeatTime: Double
    var isOnBeat: Bool
    var beatTolerance: Double
    
    init(bpm: Double = 120.0) {
        self.currentBeat = 0
        self.beatsPerMinute = bpm
        self.beatInterval = 60.0 / bpm
        self.nextBeatTime = 0.0
        self.isOnBeat = false
        self.beatTolerance = 0.1 // 100ms tolerance
    }
    
    mutating func update(currentTime: Double) {
        if currentTime >= nextBeatTime {
            currentBeat += 1
            nextBeatTime = currentTime + beatInterval
            isOnBeat = true
        } else {
            let timeToBeat = abs(currentTime - nextBeatTime)
            isOnBeat = timeToBeat <= beatTolerance
        }
    }
    
    func isPlayerOnBeat(actionTime: Double) -> Bool {
        let timeToBeat = abs(actionTime - nextBeatTime)
        return timeToBeat <= beatTolerance
    }
}
