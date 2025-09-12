//
//  SettingsView.swift
//  ChronoPulse Forest
//
//  Created by Вячеслав on 9/11/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var gameViewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation: Bool = false
    @State private var showResetOnboardingConfirmation: Bool = false
    @State private var tempMusicVolume: Double
    @State private var tempSfxVolume: Double
    
    init(gameViewModel: GameViewModel) {
        self._gameViewModel = StateObject(wrappedValue: gameViewModel)
        self._tempMusicVolume = State(initialValue: gameViewModel.gameSettings.musicVolume)
        self._tempSfxVolume = State(initialValue: gameViewModel.gameSettings.sfxVolume)
    }
    
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
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Audio Settings
                        audioSettingsSection
                        
                        // Gameplay Settings
                        gameplaySettingsSection
                        
                        // Account Settings
                        accountSettingsSection
                        
                        // About Section
                        aboutSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
        }
        .alert("Delete All Progress", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllProgress()
            }
        } message: {
            Text("This will permanently delete all your progress, scores, and unlocked levels. This action cannot be undone.")
        }
        .alert("Reset Tutorial", isPresented: $showResetOnboardingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetOnboarding()
            }
        } message: {
            Text("This will reset the onboarding tutorial so you can view it again on next app launch.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                IconButtonView(icon: "chevron.left", style: .ghost) {
                    dismiss()
                }
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                Image(systemName: "gear")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Color(hex: "40a7bb"))
                
                Text("Settings")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Audio Settings
    private var audioSettingsSection: some View {
        SettingsSection(title: "Audio", icon: "speaker.wave.2.fill") {
            VStack(spacing: 20) {
                // Sound Toggle
                SettingsToggle(
                    title: "Sound Effects",
                    subtitle: "Enable game sound effects",
                    icon: "speaker.wave.2.fill",
                    isOn: Binding(
                        get: { gameViewModel.gameSettings.soundEnabled },
                        set: { newValue in
                            var settings = gameViewModel.gameSettings
                            settings.soundEnabled = newValue
                            gameViewModel.updateSettings(settings)
                        }
                    )
                )
                
                // Haptic Toggle
                SettingsToggle(
                    title: "Haptic Feedback",
                    subtitle: "Feel the rhythm through vibrations",
                    icon: "iphone.radiowaves.left.and.right",
                    isOn: Binding(
                        get: { gameViewModel.gameSettings.hapticEnabled },
                        set: { newValue in
                            var settings = gameViewModel.gameSettings
                            settings.hapticEnabled = newValue
                            gameViewModel.updateSettings(settings)
                            
                            // Test haptic feedback
                            if newValue {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                        }
                    )
                )
                
                // Music Volume
                SettingsSlider(
                    title: "Music Volume",
                    icon: "music.note",
                    value: $tempMusicVolume,
                    range: 0...1,
                    step: 0.1
                ) { newValue in
                    var settings = gameViewModel.gameSettings
                    settings.musicVolume = newValue
                    gameViewModel.updateSettings(settings)
                }
                
                // SFX Volume
                SettingsSlider(
                    title: "Sound Effects Volume",
                    icon: "speaker.wave.3.fill",
                    value: $tempSfxVolume,
                    range: 0...1,
                    step: 0.1
                ) { newValue in
                    var settings = gameViewModel.gameSettings
                    settings.sfxVolume = newValue
                    gameViewModel.updateSettings(settings)
                    
                    // Test sound effect
                    if gameViewModel.gameSettings.soundEnabled {
                        GameService.shared.playSoundEffect("menu_select", volume: newValue)
                    }
                }
            }
        }
    }
    
    // MARK: - Gameplay Settings
    private var gameplaySettingsSection: some View {
        SettingsSection(title: "Gameplay", icon: "gamecontroller.fill") {
            VStack(spacing: 20) {
                // Difficulty Preference
                SettingsPicker(
                    title: "Preferred Difficulty",
                    subtitle: "Default difficulty for new levels",
                    icon: "slider.horizontal.3",
                    selection: Binding(
                        get: { gameViewModel.gameSettings.difficulty },
                        set: { newValue in
                            var settings = gameViewModel.gameSettings
                            settings.difficulty = newValue
                            gameViewModel.updateSettings(settings)
                        }
                    ),
                    options: Difficulty.allCases
                ) { difficulty in
                    Text(difficulty.rawValue)
                        .foregroundColor(.primary)
                }
                
                // Reset Tutorial
                SettingsButton(
                    title: "Reset Tutorial",
                    subtitle: "View the onboarding tutorial again",
                    icon: "arrow.clockwise.circle.fill",
                    style: .secondary
                ) {
                    showResetOnboardingConfirmation = true
                }
            }
        }
    }
    
    // MARK: - Account Settings
    private var accountSettingsSection: some View {
        SettingsSection(title: "Account", icon: "person.circle.fill") {
            VStack(spacing: 20) {
                // Player Stats
                PlayerStatsView(playerProgress: gameViewModel.playerProgress)
                
                // Delete Progress
                SettingsButton(
                    title: "Delete All Progress",
                    subtitle: "Permanently remove all game data",
                    icon: "trash.fill",
                    style: .destructive
                ) {
                    showDeleteConfirmation = true
                }
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle.fill") {
            VStack(spacing: 16) {
                // App Info
                VStack(spacing: 8) {
                    Text("ChronoPulse Forest")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Version 1.0.0")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Description
                Text("A unique rhythm-based game where you navigate through time-themed levels by synchronizing your movements with beats.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                
                // Credits
                VStack(spacing: 4) {
                    Text("Created with ❤️")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Built with SwiftUI")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func deleteAllProgress() {
        gameViewModel.resetAllProgress()
        
        // Show success haptic
        if gameViewModel.gameSettings.hapticEnabled {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }
    
    private func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        
        // Show success haptic
        if gameViewModel.gameSettings.hapticEnabled {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }
}

// MARK: - Settings Components
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "40a7bb"))
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Section content
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "40a7bb").opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "40a7bb"))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "40a7bb")))
        }
    }
}

struct SettingsSlider: View {
    let title: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let onEditingChanged: (Double) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "40a7bb"))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(value * 100))%")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            
            Slider(
                value: $value,
                in: range,
                step: step
            ) { editing in
                if !editing {
                    onEditingChanged(value)
                }
            }
            .accentColor(Color(hex: "40a7bb"))
        }
    }
}

struct SettingsPicker<T: Hashable & CaseIterable, Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var selection: T
    let options: [T]
    let content: (T) -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "40a7bb"))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selection = option
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        content(option)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selection == option ? Color(hex: "40a7bb") : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(hex: "40a7bb"), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
    }
}

struct SettingsButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let style: ButtonView.ButtonStyle
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(style.foregroundColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(style.foregroundColor)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(style.foregroundColor.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(style.foregroundColor.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(style.backgroundColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style.backgroundColor, lineWidth: 1)
                    )
            )
        }
    }
}

struct PlayerStatsView: View {
    let playerProgress: PlayerProgress
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Your Progress")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                SettingsStatCard(title: "Total Score", value: "\(playerProgress.totalScore)", icon: "star.fill")
                SettingsStatCard(title: "Games Played", value: "\(playerProgress.gamesPlayed)", icon: "gamecontroller.fill")
                SettingsStatCard(title: "Levels Completed", value: "\(playerProgress.levelsCompleted)", icon: "checkmark.circle.fill")
                SettingsStatCard(title: "Best Streak", value: "\(playerProgress.bestStreak)", icon: "flame.fill")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "40a7bb").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "40a7bb").opacity(0.3), lineWidth: 1)
                )
            )
    }
}

struct SettingsStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: "ffce3d"))
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.2))
        )
    }
}

#Preview {
    SettingsView(gameViewModel: GameViewModel())
}
