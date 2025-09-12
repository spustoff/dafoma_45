//
//  ProgressBarView.swift
//  ChronoPulse Forest
//
//  Created by Вячеслав on 9/11/25.
//

import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    let backgroundColor: Color
    let foregroundColor: Color
    let height: CGFloat
    let cornerRadius: CGFloat
    let showPercentage: Bool
    let animated: Bool
    
    @State private var animatedProgress: Double = 0.0
    
    init(
        progress: Double,
        backgroundColor: Color = Color.gray.opacity(0.3),
        foregroundColor: Color = Color(hex: "40a7bb"),
        height: CGFloat = 8,
        cornerRadius: CGFloat = 4,
        showPercentage: Bool = false,
        animated: Bool = true
    ) {
        self.progress = max(0, min(1, progress))
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.height = height
        self.cornerRadius = cornerRadius
        self.showPercentage = showPercentage
        self.animated = animated
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showPercentage {
                HStack {
                    Spacer()
                    Text("\(Int((animated ? animatedProgress : progress) * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
                        .frame(height: height)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(foregroundColor)
                        .frame(width: geometry.size.width * (animated ? animatedProgress : progress), height: height)
                        .animation(animated ? .easeInOut(duration: 0.3) : nil, value: animatedProgress)
                }
            }
            .frame(height: height)
        }
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { newValue in
            if animated {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animatedProgress = newValue
                }
            }
        }
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let size: CGFloat
    let showPercentage: Bool
    let animated: Bool
    
    @State private var animatedProgress: Double = 0.0
    
    init(
        progress: Double,
        lineWidth: CGFloat = 8,
        backgroundColor: Color = Color.gray.opacity(0.3),
        foregroundColor: Color = Color(hex: "40a7bb"),
        size: CGFloat = 60,
        showPercentage: Bool = true,
        animated: Bool = true
    ) {
        self.progress = max(0, min(1, progress))
        self.lineWidth = lineWidth
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.size = size
        self.showPercentage = showPercentage
        self.animated = animated
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animated ? animatedProgress : progress)
                .stroke(foregroundColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(animated ? .easeInOut(duration: 0.5) : nil, value: animatedProgress)
            
            // Percentage text
            if showPercentage {
                Text("\(Int((animated ? animatedProgress : progress) * 100))%")
                    .font(.system(size: size * 0.2, weight: .semibold))
                    .foregroundColor(foregroundColor)
            }
        }
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { newValue in
            if animated {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animatedProgress = newValue
                }
            }
        }
    }
}

// MARK: - Energy Bar View
struct EnergyBarView: View {
    let energy: Double
    let maxEnergy: Double
    let isLow: Bool
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    
    private var energyPercentage: Double {
        guard maxEnergy > 0 else { return 0 }
        return energy / maxEnergy
    }
    
    private var energyColor: Color {
        switch energyPercentage {
        case 0.7...1.0: return Color(hex: "40a7bb")
        case 0.3..<0.7: return Color(hex: "ffce3d")
        default: return Color.red
        }
    }
    
    init(energy: Double, maxEnergy: Double = 100.0) {
        self.energy = energy
        self.maxEnergy = maxEnergy
        self.isLow = energy / maxEnergy < 0.3
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(energyColor)
                    .font(.system(size: 12))
                
                Text("Energy")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(energy))/\(Int(maxEnergy))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(energyColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 12)
                    
                    // Energy fill with glow effect
                    RoundedRectangle(cornerRadius: 6)
                        .fill(energyColor)
                        .frame(width: geometry.size.width * energyPercentage, height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [energyColor.opacity(0.8), energyColor, energyColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * energyPercentage, height: 12)
                        )
                        .shadow(color: energyColor.opacity(glowOpacity), radius: 4, x: 0, y: 0)
                        .animation(.easeInOut(duration: 0.3), value: energyPercentage)
                    
                    // Animated segments for visual interest
                    if energyPercentage > 0 {
                        HStack(spacing: 2) {
                            ForEach(0..<Int(geometry.size.width / 8), id: \.self) { index in
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 1, height: 8)
                            }
                        }
                        .frame(width: geometry.size.width * energyPercentage, height: 12)
                        .clipped()
                    }
                }
            }
            .frame(height: 12)
            .scaleEffect(isLow ? pulseScale : 1.0)
        }
        .onAppear {
            startGlowAnimation()
            if isLow {
                startPulseAnimation()
            }
        }
        .onChange(of: isLow) { newValue in
            if newValue {
                startPulseAnimation()
            }
        }
    }
    
    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
}

// MARK: - Time Progress View
struct TimeProgressView: View {
    let timeRemaining: Double
    let totalTime: Double
    let isUrgent: Bool
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var warningOpacity: Double = 0.0
    
    private var timePercentage: Double {
        guard totalTime > 0 else { return 0 }
        return timeRemaining / totalTime
    }
    
    private var timeColor: Color {
        switch timePercentage {
        case 0.5...1.0: return Color(hex: "40a7bb")
        case 0.2..<0.5: return Color(hex: "ffce3d")
        default: return Color.red
        }
    }
    
    private var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    init(timeRemaining: Double, totalTime: Double) {
        self.timeRemaining = timeRemaining
        self.totalTime = totalTime
        self.isUrgent = timeRemaining / totalTime < 0.2
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(timeColor)
                    .font(.system(size: 12))
                
                Text("Time")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formattedTime)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(timeColor)
                    .opacity(isUrgent ? warningOpacity : 1.0)
            }
            
            ProgressBarView(
                progress: timePercentage,
                backgroundColor: Color.black.opacity(0.3),
                foregroundColor: timeColor,
                height: 12,
                cornerRadius: 6,
                animated: true
            )
            .scaleEffect(isUrgent ? pulseScale : 1.0)
        }
        .onAppear {
            if isUrgent {
                startUrgentAnimation()
            }
        }
        .onChange(of: isUrgent) { newValue in
            if newValue {
                startUrgentAnimation()
            }
        }
    }
    
    private func startUrgentAnimation() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
            warningOpacity = 0.5
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        VStack(spacing: 15) {
            ProgressBarView(progress: 0.7, showPercentage: true)
            ProgressBarView(progress: 0.3, foregroundColor: .orange, showPercentage: true)
            ProgressBarView(progress: 0.9, foregroundColor: .green, height: 12)
        }
        
        HStack(spacing: 20) {
            CircularProgressView(progress: 0.75)
            CircularProgressView(progress: 0.45, foregroundColor: .orange)
            CircularProgressView(progress: 0.2, foregroundColor: .red)
        }
        
        VStack(spacing: 15) {
            EnergyBarView(energy: 85, maxEnergy: 100)
            EnergyBarView(energy: 45, maxEnergy: 100)
            EnergyBarView(energy: 15, maxEnergy: 100)
        }
        
        VStack(spacing: 15) {
            TimeProgressView(timeRemaining: 90, totalTime: 120)
            TimeProgressView(timeRemaining: 30, totalTime: 120)
            TimeProgressView(timeRemaining: 10, totalTime: 120)
        }
    }
    .padding()
    .background(Color(hex: "257792"))
}
