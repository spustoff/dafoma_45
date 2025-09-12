//
//  GameView.swift
//  ChronoPulse Forest
//
//  Created by Вячеслав on 9/11/25.
//

import SwiftUI

struct GameView: View {
    @StateObject private var gameViewModel: GameViewModel
    @StateObject private var gameService = GameService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showPauseMenu: Bool = false
    @State private var gameSize: CGSize = .zero
    @State private var beatIndicatorScale: CGFloat = 1.0
    @State private var scorePopups: [ScorePopup] = []
    
    let level: Level
    
    init(level: Level, gameViewModel: GameViewModel) {
        self.level = level
        self._gameViewModel = StateObject(wrappedValue: gameViewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                gameBackground
                
                // Game area
                gameArea(geometry: geometry)
                
                // UI overlay
                gameUIOverlay
                
                // Beat indicator
                beatIndicator
                
                // Score popups
                ForEach(scorePopups, id: \.id) { popup in
                    AnimatedScorePopup(
                        score: popup.score,
                        isVisible: popup.isVisible,
                        position: popup.position
                    )
                }
                
                // Pause menu
                if showPauseMenu {
                    pauseMenuOverlay
                }
                
                // Game over screen
                if gameViewModel.showGameOver {
                    gameOverScreen
                }
            }
            .onAppear {
                gameSize = geometry.size
                startGame()
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        handleGameTap(at: value.location)
                    }
            )
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Background
    private var gameBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [Color(hex: "257792"), Color(hex: "1a2e35")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background elements
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: CGFloat.random(in: 20...60))
                    .position(
                        x: CGFloat.random(in: 0...400),
                        y: CGFloat.random(in: 0...800)
                    )
                    .animation(
                        .linear(duration: Double.random(in: 10...20))
                        .repeatForever(autoreverses: false),
                        value: gameViewModel.gameTime
                    )
            }
            
            // Level-specific background
            levelBackgroundElements
        }
        .scaleEffect(gameViewModel.screenShake ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: gameViewModel.screenShake)
    }
    
    private var levelBackgroundElements: some View {
        Group {
            switch level.type {
            case .hourglass:
                HourglassBackground()
            case .sundial:
                SundialBackground()
            case .calendar:
                CalendarBackground()
            }
        }
    }
    
    // MARK: - Game Area
    private func gameArea(geometry: GeometryProxy) -> some View {
        ZStack {
            // Ship
            shipView
            
            // Obstacles
            if let session = gameViewModel.currentSession {
                ForEach(session.obstacles, id: \.id) { obstacle in
                    obstacleView(obstacle: obstacle)
                }
                
                // Energy pickups
                ForEach(session.energyPickups, id: \.id) { energy in
                    energyPickupView(energy: energy)
                }
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .clipped()
    }
    
    private var shipView: some View {
        ZStack {
            // Ship glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "40a7bb").opacity(0.6), Color.clear],
                        center: .center,
                        startRadius: 5,
                        endRadius: 25
                    )
                )
                .frame(width: 50, height: 50)
            
            // Ship body
            Circle()
                .fill(Color(hex: "40a7bb"))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                )
            
            // Invincibility effect
            if gameViewModel.currentSession?.ship.isInvincible == true {
                Circle()
                    .stroke(Color.yellow, lineWidth: 3)
                    .frame(width: 30, height: 30)
                    .scaleEffect(beatIndicatorScale)
            }
        }
        .position(gameViewModel.shipPosition)
        .animation(.easeInOut(duration: 0.2), value: gameViewModel.shipPosition)
    }
    
    private func obstacleView(obstacle: Obstacle) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [Color.red.opacity(0.8), Color.red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: obstacle.size.width, height: obstacle.size.height)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color.red.opacity(0.4), radius: 4, x: 0, y: 0)
            .position(obstacle.position)
    }
    
    private func energyPickupView(energy: TimeEnergy) -> some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "ffce3d").opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 5,
                        endRadius: 20
                    )
                )
                .frame(width: 40, height: 40)
            
            // Energy orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "ffce3d"), Color(hex: "ffce3d").opacity(0.6)],
                        center: .center,
                        startRadius: 2,
                        endRadius: 10
                    )
                )
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )
        }
        .position(energy.position)
        .scaleEffect(beatIndicatorScale)
        .shadow(color: Color(hex: "ffce3d").opacity(0.6), radius: 6, x: 0, y: 0)
    }
    
    // MARK: - UI Overlay
    private var gameUIOverlay: some View {
        VStack {
            // Top UI
            HStack {
                // Pause button
                IconButtonView(icon: "pause.fill", style: .ghost, size: 36) {
                    pauseGame()
                }
                
                Spacer()
                
                // Score
                ScoreView(score: gameViewModel.currentSession?.score ?? 0, style: .detailed)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Spacer()
            
            // Bottom UI
            VStack(spacing: 12) {
                HStack {
                    // Energy bar
                    if let ship = gameViewModel.currentSession?.ship {
                        EnergyBarView(energy: ship.energy, maxEnergy: ship.maxEnergy)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                HStack {
                    // Time progress
                    if let session = gameViewModel.currentSession {
                        TimeProgressView(
                            timeRemaining: session.timeRemaining,
                            totalTime: session.level.duration
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Beat Indicator
    private var beatIndicator: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                ZStack {
                    // Beat ring
                    Circle()
                        .stroke(
                            gameViewModel.rhythmBeat.isOnBeat ? Color(hex: "ffce3d") : Color.white.opacity(0.3),
                            lineWidth: 3
                        )
                        .frame(width: 60, height: 60)
                        .scaleEffect(beatIndicatorScale)
                    
                    // Beat center
                    Circle()
                        .fill(gameViewModel.rhythmBeat.isOnBeat ? Color(hex: "ffce3d") : Color.white.opacity(0.5))
                        .frame(width: 12, height: 12)
                    
                    // Beat text
                    Text("BEAT")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .offset(y: 30)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 120)
            }
        }
        .onChange(of: gameViewModel.rhythmBeat.isOnBeat) { isOnBeat in
            if isOnBeat {
                withAnimation(.easeOut(duration: 0.1)) {
                    beatIndicatorScale = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        beatIndicatorScale = 1.0
                    }
                }
            }
        }
    }
    
    // MARK: - Pause Menu
    private var pauseMenuOverlay: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Game Paused")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    ButtonView(title: "Resume", icon: "play.fill", style: .primary) {
                        resumeGame()
                    }
                    
                    ButtonView(title: "Restart", icon: "arrow.clockwise", style: .secondary) {
                        restartGame()
                    }
                    
                    ButtonView(title: "Main Menu", icon: "house.fill", style: .ghost) {
                        returnToMenu()
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "1a2e35"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "40a7bb"), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Game Over Screen
    private var gameOverScreen: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Title
                VStack(spacing: 8) {
                    Text("Game Over")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(level.type.rawValue)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Score section
                VStack(spacing: 16) {
                    ScoreView(score: gameViewModel.lastScore, style: .large)
                    
                    HStack(spacing: 32) {
                        VStack(spacing: 4) {
                            Text("Target")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("\(level.targetScore)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Best")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("\(level.bestScore)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "ffce3d"))
                        }
                    }
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    ButtonView(title: "Play Again", icon: "arrow.clockwise", style: .primary) {
                        restartGame()
                    }
                    
                    ButtonView(title: "Main Menu", icon: "house.fill", style: .secondary) {
                        returnToMenu()
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a2e35"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "40a7bb"), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Game Logic
    private func startGame() {
        gameService.playBackgroundMusic(for: level.type, volume: gameViewModel.gameSettings.musicVolume)
        gameViewModel.startGame(with: level)
    }
    
    private func handleGameTap(at location: CGPoint) {
        guard gameViewModel.gameState == .playing else { return }
        
        gameViewModel.handlePlayerTap(at: location)
        
        // Create score popup
        let isOnBeat = gameViewModel.rhythmBeat.isOnBeat
        let points = isOnBeat ? 50 : 25
        
        let popup = ScorePopup(
            score: points,
            position: location,
            isVisible: true
        )
        scorePopups.append(popup)
        
        // Remove popup after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            scorePopups.removeAll { $0.id == popup.id }
        }
        
        // Play sound effect
        if gameViewModel.gameSettings.soundEnabled {
            gameService.playSoundEffect(
                isOnBeat ? "tap_on_beat" : "tap_off_beat",
                volume: gameViewModel.gameSettings.sfxVolume
            )
        }
    }
    
    private func pauseGame() {
        showPauseMenu = true
        gameViewModel.pauseGame()
    }
    
    private func resumeGame() {
        showPauseMenu = false
        gameViewModel.resumeGame()
    }
    
    private func restartGame() {
        showPauseMenu = false
        gameViewModel.restartCurrentLevel()
    }
    
    private func returnToMenu() {
        gameService.stopBackgroundMusic()
        gameViewModel.returnToMenu()
        dismiss()
    }
}

// MARK: - Background Components
struct HourglassBackground: View {
    var body: some View {
        ForEach(0..<3, id: \.self) { index in
            Image(systemName: "hourglass")
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.05))
                .position(
                    x: CGFloat.random(in: 50...350),
                    y: CGFloat.random(in: 100...700)
                )
                .rotationEffect(.degrees(Double.random(in: 0...360)))
        }
    }
}

struct SundialBackground: View {
    var body: some View {
        ForEach(0..<3, id: \.self) { index in
            Image(systemName: "sun.max")
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.05))
                .position(
                    x: CGFloat.random(in: 50...350),
                    y: CGFloat.random(in: 100...700)
                )
                .rotationEffect(.degrees(Double.random(in: 0...360)))
        }
    }
}

struct CalendarBackground: View {
    var body: some View {
        ForEach(0..<3, id: \.self) { index in
            Image(systemName: "calendar")
                .font(.system(size: 80, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.05))
                .position(
                    x: CGFloat.random(in: 50...350),
                    y: CGFloat.random(in: 100...700)
                )
                .rotationEffect(.degrees(Double.random(in: 0...360)))
        }
    }
}

// MARK: - Score Popup
struct ScorePopup {
    let id = UUID()
    let score: Int
    let position: CGPoint
    let isVisible: Bool
}

#Preview {
    GameView(
        level: Level(type: .hourglass, difficulty: .normal),
        gameViewModel: GameViewModel()
    )
}
