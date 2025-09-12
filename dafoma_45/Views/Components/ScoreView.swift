//
//  ScoreView.swift
//  ChronoPulse Forest
//
//  Created by Вячеслав on 9/11/25.
//

import SwiftUI

struct ScoreView: View {
    let score: Int
    let style: ScoreStyle
    let showAnimation: Bool
    
    @State private var animatedScore: Int = 0
    @State private var scaleEffect: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    
    enum ScoreStyle {
        case compact
        case detailed
        case large
        case floating
        
        var fontSize: CGFloat {
            switch self {
            case .compact: return 16
            case .detailed: return 20
            case .large: return 32
            case .floating: return 24
            }
        }
        
        var fontWeight: Font.Weight {
            switch self {
            case .compact: return .medium
            case .detailed: return .semibold
            case .large: return .bold
            case .floating: return .bold
            }
        }
    }
    
    init(score: Int, style: ScoreStyle = .detailed, showAnimation: Bool = true) {
        self.score = score
        self.style = style
        self.showAnimation = showAnimation
    }
    
    var body: some View {
        Group {
            switch style {
            case .compact:
                compactScoreView
            case .detailed:
                detailedScoreView
            case .large:
                largeScoreView
            case .floating:
                floatingScoreView
            }
        }
        .onAppear {
            if showAnimation {
                animateScore()
            } else {
                animatedScore = score
            }
        }
        .onChange(of: score) { newValue in
            if showAnimation {
                animateScore()
            } else {
                animatedScore = newValue
            }
        }
    }
    
    private var compactScoreView: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundColor(Color(hex: "ffce3d"))
                .font(.system(size: 12))
            
            Text("\(animatedScore)")
                .font(.system(size: style.fontSize, weight: style.fontWeight, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
    
    private var detailedScoreView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Score")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(Color(hex: "ffce3d"))
                    .font(.system(size: 16))
                
                Text(formatScore(animatedScore))
                    .font(.system(size: style.fontSize, weight: style.fontWeight, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var largeScoreView: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundColor(Color(hex: "ffce3d"))
                .font(.system(size: 24))
                .scaleEffect(scaleEffect)
                .shadow(color: Color(hex: "ffce3d").opacity(glowOpacity), radius: 8, x: 0, y: 0)
            
            Text(formatScore(animatedScore))
                .font(.system(size: style.fontSize, weight: style.fontWeight, design: .monospaced))
                .foregroundColor(.primary)
                .scaleEffect(scaleEffect)
        }
    }
    
    private var floatingScoreView: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus")
                .foregroundColor(Color(hex: "40a7bb"))
                .font(.system(size: 16, weight: .bold))
            
            Text("\(animatedScore)")
                .font(.system(size: style.fontSize, weight: style.fontWeight, design: .monospaced))
                .foregroundColor(Color(hex: "40a7bb"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "40a7bb").opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "40a7bb"), lineWidth: 1)
                )
        )
        .scaleEffect(scaleEffect)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private func animateScore() {
        let oldScore = animatedScore
        let newScore = score
        let difference = newScore - oldScore
        
        if difference > 0 {
            // Positive score change - animate increment
            let duration = min(0.8, Double(difference) / 1000.0 + 0.3)
            
            withAnimation(.easeOut(duration: duration)) {
                animatedScore = newScore
            }
            
            // Scale and glow animation for positive changes
            withAnimation(.easeInOut(duration: 0.2)) {
                scaleEffect = 1.2
                glowOpacity = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scaleEffect = 1.0
                    glowOpacity = 0.0
                }
            }
        } else {
            // Direct update for non-positive changes
            animatedScore = newScore
        }
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

// MARK: - Leaderboard Score View
struct LeaderboardScoreView: View {
    let rank: Int
    let playerName: String
    let score: Int
    let isCurrentPlayer: Bool
    
    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "ffce3d") // Gold
        case 2: return Color.gray // Silver
        case 3: return Color(hex: "CD7F32") // Bronze
        default: return .secondary
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal"
        default: return "\(rank)"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                if rank <= 3 {
                    Image(systemName: rankIcon)
                        .foregroundColor(rankColor)
                        .font(.system(size: 16, weight: .bold))
                } else {
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(rankColor)
                }
            }
            
            // Player name
            Text(playerName)
                .font(.system(size: 16, weight: isCurrentPlayer ? .semibold : .medium))
                .foregroundColor(isCurrentPlayer ? .primary : .secondary)
                .lineLimit(1)
            
            Spacer()
            
            // Score
            ScoreView(score: score, style: .compact, showAnimation: false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentPlayer ? Color(hex: "40a7bb").opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrentPlayer ? Color(hex: "40a7bb") : Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Score Streak View
struct ScoreStreakView: View {
    let streak: Int
    let maxStreak: Int
    let isActive: Bool
    
    @State private var fireAnimation: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 8) {
            // Fire icon for active streaks
            if isActive && streak > 0 {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                    .scaleEffect(fireAnimation ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: fireAnimation)
                    .onAppear {
                        fireAnimation = true
                    }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Streak")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text("\(streak)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(isActive ? .orange : .primary)
                        .scaleEffect(pulseScale)
                    
                    if maxStreak > 0 {
                        Text("(\(maxStreak) best)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onChange(of: streak) { _ in
            if isActive {
                withAnimation(.easeInOut(duration: 0.2)) {
                    pulseScale = 1.3
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        pulseScale = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Animated Score Popup
struct AnimatedScorePopup: View {
    let score: Int
    let isVisible: Bool
    let position: CGPoint
    
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Text("+\(score)")
            .font(.system(size: 20, weight: .bold, design: .monospaced))
            .foregroundColor(Color(hex: "ffce3d"))
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(y: offset)
            .position(position)
            .onChange(of: isVisible) { visible in
                if visible {
                    startAnimation()
                }
            }
    }
    
    private func startAnimation() {
        // Initial pop animation
        withAnimation(.easeOut(duration: 0.1)) {
            scale = 1.3
        }
        
        // Float up animation
        withAnimation(.easeOut(duration: 1.0)) {
            offset = -60
            opacity = 0.0
        }
        
        // Reset scale after initial pop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.9)) {
                scale = 1.0
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        // Different score styles
        HStack(spacing: 20) {
            ScoreView(score: 1234, style: .compact)
            ScoreView(score: 5678, style: .detailed)
        }
        
        ScoreView(score: 9876, style: .large)
        
        ScoreView(score: 150, style: .floating)
        
        // Leaderboard entries
        VStack(spacing: 8) {
            LeaderboardScoreView(rank: 1, playerName: "ChronoMaster", score: 15420, isCurrentPlayer: false)
            LeaderboardScoreView(rank: 2, playerName: "TimeLord", score: 12350, isCurrentPlayer: false)
            LeaderboardScoreView(rank: 3, playerName: "You", score: 9876, isCurrentPlayer: true)
            LeaderboardScoreView(rank: 4, playerName: "RhythmKing", score: 8765, isCurrentPlayer: false)
        }
        
        // Streak views
        HStack(spacing: 20) {
            ScoreStreakView(streak: 5, maxStreak: 12, isActive: true)
            ScoreStreakView(streak: 0, maxStreak: 8, isActive: false)
        }
    }
    .padding()
    .background(Color(hex: "257792"))
}
