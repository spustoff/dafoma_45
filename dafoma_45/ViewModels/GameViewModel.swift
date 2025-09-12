//
//  GameViewModel.swift
//  ChronoPulse Forest
//
//  Created by Вячеслав on 9/11/25.
//

import SwiftUI
import Foundation
import Combine

class GameViewModel: ObservableObject {
    @Published var gameState: GameState = .menu
    @Published var currentSession: GameSession?
    @Published var playerProgress: PlayerProgress = PlayerProgress()
    @Published var gameSettings: GameSettings = GameSettings()
    @Published var availableLevels: [Level] = []
    @Published var rhythmBeat: RhythmBeat = RhythmBeat()
    @Published var lastScore: Int = 0
    @Published var showGameOver: Bool = false
    @Published var showPauseMenu: Bool = false
    
    // Game timing
    @Published var gameTime: Double = 0.0
    private var gameTimer: Timer?
    private var lastUpdateTime: Date = Date()
    
    // Animation states
    @Published var shipPosition: CGPoint = CGPoint(x: 100, y: 200)
    @Published var screenShake: Bool = false
    @Published var showScoreAnimation: Bool = false
    @Published var scoreAnimationValue: Int = 0
    
    // AppStorage for persistence
    @AppStorage("playerTotalScore") private var storedTotalScore: Int = 0
    @AppStorage("playerGamesPlayed") private var storedGamesPlayed: Int = 0
    @AppStorage("playerLevelsCompleted") private var storedLevelsCompleted: Int = 0
    @AppStorage("playerBestStreak") private var storedBestStreak: Int = 0
    @AppStorage("playerCurrentStreak") private var storedCurrentStreak: Int = 0
    @AppStorage("unlockedLevelsData") private var unlockedLevelsData: String = ""
    @AppStorage("soundEnabled") private var storedSoundEnabled: Bool = true
    @AppStorage("hapticEnabled") private var storedHapticEnabled: Bool = true
    @AppStorage("musicVolume") private var storedMusicVolume: Double = 0.7
    @AppStorage("sfxVolume") private var storedSfxVolume: Double = 0.8
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadPlayerProgress()
        loadGameSettings()
        setupAvailableLevels()
        startGameLoop()
    }
    
    // MARK: - Game Flow
    func startGame(with level: Level) {
        var gameLevel = level
        gameLevel.isUnlocked = true
        
        currentSession = GameSession(level: gameLevel)
        shipPosition = currentSession?.ship.position ?? CGPoint(x: 100, y: 200)
        gameState = .playing
        gameTime = 0.0
        lastUpdateTime = Date()
        
        rhythmBeat = RhythmBeat(bpm: 120.0 * level.difficulty.multiplier)
        
        // Provide haptic feedback
        if gameSettings.hapticEnabled {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    func pauseGame() {
        guard gameState == .playing else { return }
        currentSession?.pause()
        gameState = .paused
        showPauseMenu = true
    }
    
    func resumeGame() {
        guard gameState == .paused else { return }
        currentSession?.resume()
        gameState = .playing
        showPauseMenu = false
        lastUpdateTime = Date()
    }
    
    func endGame() {
        guard let session = currentSession else { return }
        
        lastScore = session.score
        showGameOver = true
        gameState = .gameOver
        
        // Update player progress
        var updatedLevel = session.level
        updatedLevel.bestScore = max(updatedLevel.bestScore, session.score)
        updatedLevel.isCompleted = session.score >= updatedLevel.targetScore
        
        playerProgress.completeLevel(level: updatedLevel, score: session.score)
        savePlayerProgress()
        
        // Screen shake effect for game over
        if gameSettings.hapticEnabled {
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            screenShake = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.screenShake = false
        }
    }
    
    func returnToMenu() {
        currentSession = nil
        gameState = .menu
        showGameOver = false
        showPauseMenu = false
        gameTime = 0.0
    }
    
    func restartCurrentLevel() {
        guard let session = currentSession else { return }
        startGame(with: session.level)
        showGameOver = false
        showPauseMenu = false
    }
    
    // MARK: - Game Logic
    func handlePlayerTap(at location: CGPoint) {
        guard gameState == .playing, let session = currentSession else { return }
        
        let currentTime = gameTime
        let isOnBeat = rhythmBeat.isPlayerOnBeat(actionTime: currentTime)
        
        // Move ship to tapped location
        var updatedSession = session
        updatedSession.ship.move(to: location)
        shipPosition = location
        
        // Award points based on rhythm accuracy
        let basePoints = isOnBeat ? 50 : 25
        let difficultyMultiplier = session.level.difficulty.multiplier
        let points = Int(Double(basePoints) * difficultyMultiplier)
        
        updatedSession.addScore(points)
        currentSession = updatedSession
        
        // Show score animation
        showScoreAnimation(points: points)
        
        // Haptic feedback
        if gameSettings.hapticEnabled {
            let impactStyle: UIImpactFeedbackGenerator.FeedbackStyle = isOnBeat ? .medium : .light
            let impactFeedback = UIImpactFeedbackGenerator(style: impactStyle)
            impactFeedback.impactOccurred()
        }
    }
    
    private func showScoreAnimation(points: Int) {
        scoreAnimationValue = points
        showScoreAnimation = true
        
        withAnimation(.easeOut(duration: 1.0)) {
            showScoreAnimation = false
        }
    }
    
    // MARK: - Game Loop
    private func startGameLoop() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            self.updateGame()
        }
    }
    
    private func updateGame() {
        guard gameState == .playing, var session = currentSession else { return }
        
        let currentTime = Date()
        let deltaTime = currentTime.timeIntervalSince(lastUpdateTime)
        lastUpdateTime = currentTime
        
        gameTime += deltaTime
        
        // Update rhythm beat
        rhythmBeat.update(currentTime: gameTime)
        
        // Update game session
        session.updateTime(deltaTime: deltaTime)
        session.ship.updateInvincibility(deltaTime: deltaTime)
        
        // Update obstacles
        updateObstacles(session: &session, deltaTime: deltaTime)
        
        // Update energy pickups
        updateEnergyPickups(session: &session, deltaTime: deltaTime)
        
        // Spawn new objects
        spawnGameObjects(session: &session)
        
        // Check win/lose conditions
        if session.timeRemaining <= 0 {
            endGame()
        } else if session.ship.energy <= 0 {
            endGame()
        }
        
        currentSession = session
    }
    
    private func updateObstacles(session: inout GameSession, deltaTime: Double) {
        for i in session.obstacles.indices.reversed() {
            session.obstacles[i].position.x += session.obstacles[i].velocity.dx * deltaTime
            
            // Remove obstacles that are off screen
            if session.obstacles[i].position.x < -50 {
                session.obstacles.remove(at: i)
                continue
            }
            
            // Check collision with ship
            if checkCollision(ship: session.ship, obstacle: session.obstacles[i]) && !session.ship.isInvincible {
                session.ship.drainEnergy(20)
                session.ship.activateInvincibility(duration: 1.0)
                
                // Screen shake on hit
                if gameSettings.hapticEnabled {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                }
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    screenShake = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.screenShake = false
                }
            }
        }
    }
    
    private func updateEnergyPickups(session: inout GameSession, deltaTime: Double) {
        for i in session.energyPickups.indices.reversed() {
            session.energyPickups[i].position.x += -100 * deltaTime // Move left
            
            // Remove energy pickups that are off screen
            if session.energyPickups[i].position.x < -50 {
                session.energyPickups.remove(at: i)
                continue
            }
            
            // Check collection
            if checkEnergyCollection(ship: session.ship, energy: session.energyPickups[i]) {
                session.ship.addEnergy(session.energyPickups[i].value)
                session.addScore(Int(session.energyPickups[i].value))
                session.energyPickups.remove(at: i)
                
                // Collection haptic feedback
                if gameSettings.hapticEnabled {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            }
        }
    }
    
    private func spawnGameObjects(session: inout GameSession) {
        let spawnRate = session.level.difficulty.multiplier
        
        // Spawn obstacles
        if Double.random(in: 0...1) < 0.02 * spawnRate {
            let yPosition = Double.random(in: 50...350)
            session.spawnObstacle(at: CGPoint(x: 400, y: yPosition))
        }
        
        // Spawn energy pickups
        if Double.random(in: 0...1) < 0.015 * spawnRate {
            let yPosition = Double.random(in: 50...350)
            session.spawnEnergyPickup(at: CGPoint(x: 400, y: yPosition))
        }
    }
    
    private func checkCollision(ship: TimeShip, obstacle: Obstacle) -> Bool {
        let shipRect = CGRect(x: ship.position.x - 20, y: ship.position.y - 20, width: 40, height: 40)
        let obstacleRect = CGRect(x: obstacle.position.x - obstacle.size.width/2,
                                  y: obstacle.position.y - obstacle.size.height/2,
                                  width: obstacle.size.width,
                                  height: obstacle.size.height)
        return shipRect.intersects(obstacleRect)
    }
    
    private func checkEnergyCollection(ship: TimeShip, energy: TimeEnergy) -> Bool {
        let distance = sqrt(pow(ship.position.x - energy.position.x, 2) + pow(ship.position.y - energy.position.y, 2))
        return distance < 30
    }
    
    // MARK: - Settings
    func updateSettings(_ newSettings: GameSettings) {
        gameSettings = newSettings
        saveGameSettings()
    }
    
    func resetAllProgress() {
        playerProgress = PlayerProgress()
        availableLevels = []
        setupAvailableLevels()
        savePlayerProgress()
        
        // Reset AppStorage values
        storedTotalScore = 0
        storedGamesPlayed = 0
        storedLevelsCompleted = 0
        storedBestStreak = 0
        storedCurrentStreak = 0
        unlockedLevelsData = ""
    }
    
    // MARK: - Data Persistence
    private func loadPlayerProgress() {
        playerProgress.totalScore = storedTotalScore
        playerProgress.gamesPlayed = storedGamesPlayed
        playerProgress.levelsCompleted = storedLevelsCompleted
        playerProgress.bestStreak = storedBestStreak
        playerProgress.currentStreak = storedCurrentStreak
        
        // Load unlocked levels
        if !unlockedLevelsData.isEmpty {
            let unlockedArray = unlockedLevelsData.components(separatedBy: ",")
            playerProgress.unlockedLevels = Set(unlockedArray)
        }
    }
    
    private func savePlayerProgress() {
        storedTotalScore = playerProgress.totalScore
        storedGamesPlayed = playerProgress.gamesPlayed
        storedLevelsCompleted = playerProgress.levelsCompleted
        storedBestStreak = playerProgress.bestStreak
        storedCurrentStreak = playerProgress.currentStreak
        
        // Save unlocked levels
        unlockedLevelsData = Array(playerProgress.unlockedLevels).joined(separator: ",")
    }
    
    private func loadGameSettings() {
        gameSettings.soundEnabled = storedSoundEnabled
        gameSettings.hapticEnabled = storedHapticEnabled
        gameSettings.musicVolume = storedMusicVolume
        gameSettings.sfxVolume = storedSfxVolume
    }
    
    private func saveGameSettings() {
        storedSoundEnabled = gameSettings.soundEnabled
        storedHapticEnabled = gameSettings.hapticEnabled
        storedMusicVolume = gameSettings.musicVolume
        storedSfxVolume = gameSettings.sfxVolume
    }
    
    private func setupAvailableLevels() {
        availableLevels = []
        
        for levelType in LevelType.allCases {
            for difficulty in Difficulty.allCases {
                let targetScore = difficulty == .easy ? 800 : (difficulty == .normal ? 1200 : 1600)
                var level = Level(type: levelType, difficulty: difficulty, targetScore: targetScore)
                
                let levelKey = "\(levelType.rawValue.lowercased())_\(difficulty.rawValue.lowercased())"
                level.isUnlocked = playerProgress.unlockedLevels.contains(levelKey)
                
                availableLevels.append(level)
            }
        }
    }
    
    deinit {
        gameTimer?.invalidate()
    }
}
