//
//  ContentView.swift
//  ChronoPulse Forest
//
//  Created by Вячеслав on 9/11/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    @State private var showOnboarding: Bool = false
    @State private var selectedLevel: Level?
    @State private var showSettings: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "257792"), Color(hex: "1a2e35")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Game content
                    if gameViewModel.gameState == .menu {
                        ScrollView {
                            VStack(spacing: 32) {
                                // Title section
                                titleSection
                                
                                // Quick play section
                                quickPlaySection
                                
                                // Level selection
                                levelSelectionSection
                                
                                // Player progress
                                playerProgressSection
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(gameViewModel: gameViewModel)
        }
        .fullScreenCover(item: $selectedLevel) { level in
            GameView(level: level, gameViewModel: gameViewModel)
        }
        .onAppear {
            checkOnboardingStatus()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            // Logo/Title
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "ffce3d"))
                
                Text("ChronoPulse")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Settings button
            IconButtonView(icon: "gear", style: .ghost, size: 36) {
                showSettings = true
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 16) {
            // Main title
            VStack(spacing: 8) {
                Text("ChronoPulse")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Forest")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(Color(hex: "40a7bb"))
                
                Text("Navigate through time with rhythm")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Animated elements
            HStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color(hex: "ffce3d").opacity(0.6))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animatedScale(for: index))
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Quick Play Section
    private var quickPlaySection: some View {
        VStack(spacing: 16) {
            AnimatedButtonView(
                title: "Quick Play",
                icon: "play.fill",
                style: .primary
            ) {
                startQuickPlay()
            }
            
            HStack(spacing: 12) {
                ButtonView(
                    title: "Tutorial",
                    icon: "questionmark.circle.fill",
                    style: .secondary
                ) {
                    showOnboarding = true
                }
                
                ButtonView(
                    title: "Continue",
                    icon: "arrow.right.circle.fill",
                    style: .ghost,
                    isEnabled: hasUnfinishedLevel()
                ) {
                    continueLastLevel()
                }
            }
        }
    }
    
    // MARK: - Level Selection
    private var levelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Level")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(gameViewModel.availableLevels, id: \.id) { level in
                    LevelCard(level: level, isUnlocked: level.isUnlocked) {
                        if level.isUnlocked {
                            selectedLevel = level
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Player Progress
    private var playerProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                // Score and stats
                HStack(spacing: 16) {
                    StatCard(
                        title: "Total Score",
                        value: formatScore(gameViewModel.playerProgress.totalScore),
                        icon: "star.fill",
                        color: Color(hex: "ffce3d")
                    )
                    
                    StatCard(
                        title: "Levels Complete",
                        value: "\(gameViewModel.playerProgress.levelsCompleted)",
                        icon: "checkmark.circle.fill",
                        color: Color(hex: "40a7bb")
                    )
                }
                
                // Streak information
                if gameViewModel.playerProgress.currentStreak > 0 {
                    ScoreStreakView(
                        streak: gameViewModel.playerProgress.currentStreak,
                        maxStreak: gameViewModel.playerProgress.bestStreak,
                        isActive: true
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func checkOnboardingStatus() {
        if !onboardingViewModel.isCompleted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showOnboarding = true
            }
        }
    }
    
    private func startQuickPlay() {
        // Find the first available level
        if let firstLevel = gameViewModel.availableLevels.first(where: { $0.isUnlocked }) {
            selectedLevel = firstLevel
        } else {
            // Fallback to first level
            let defaultLevel = Level(type: .hourglass, difficulty: .easy)
            selectedLevel = defaultLevel
        }
    }
    
    private func hasUnfinishedLevel() -> Bool {
        return gameViewModel.playerProgress.gamesPlayed > 0 && 
               gameViewModel.playerProgress.currentStreak > 0
    }
    
    private func continueLastLevel() {
        // Logic to continue the last played level
        startQuickPlay() // For now, just start quick play
    }
    
    private func animatedScale(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.2
        return 1.0 + 0.3 * sin(Date().timeIntervalSince1970 * 2 + delay)
    }
    
    private func formatScore(_ score: Int) -> String {
        if score >= 1_000_000 {
            return String(format: "%.1fM", Double(score) / 1_000_000)
        } else if score >= 1_000 {
            return String(format: "%.1fK", Double(score) / 1_000)
        } else {
            return "\(score)"
        }
    }
}

// MARK: - Level Card
struct LevelCard: View {
    let level: Level
    let isUnlocked: Bool
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            if isUnlocked {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                action()
            }
        }) {
            VStack(spacing: 12) {
                // Level icon
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Color(hex: "40a7bb").opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: isUnlocked ? level.type.icon : "lock.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isUnlocked ? Color(hex: "ffce3d") : .gray)
                }
                
                // Level info
                VStack(spacing: 4) {
                    Text(level.type.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isUnlocked ? .white : .gray)
                    
                    Text(level.difficulty.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isUnlocked ? .secondary : .gray)
                    
                    if level.bestScore > 0 {
                        Text("Best: \(level.bestScore)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "ffce3d"))
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isUnlocked ? Color.black.opacity(0.3) : Color.black.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isUnlocked ? Color(hex: "40a7bb").opacity(0.5) : Color.gray.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isUnlocked ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if isUnlocked {
                isPressed = pressing
            }
        }, perform: {})
        .disabled(!isUnlocked)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Level Extension
extension Level: Identifiable {
    // Level already has an id property from the struct definition
}

#Preview {
    ContentView()
        .environmentObject(GameViewModel())
        .environmentObject(OnboardingViewModel())
}
