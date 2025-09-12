//
//  OnboardingView.swift
//  ChronoPulse Forest
//
//  Created by Вячеслав on 9/11/25.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isPresented: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "257792"), Color(hex: "1a2e35")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bar
                    VStack(spacing: 16) {
                        HStack {
                            Button("Skip") {
                                viewModel.skipOnboarding()
                                isPresented = false
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text("\(viewModel.currentStep + 1) of \(viewModel.onboardingSteps.count)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        ProgressBarView(
                            progress: viewModel.progressPercentage,
                            backgroundColor: Color.white.opacity(0.2),
                            foregroundColor: Color(hex: "ffce3d"),
                            height: 4,
                            cornerRadius: 2
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Main content
                    VStack(spacing: 40) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color(hex: "40a7bb").opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .stroke(Color(hex: "40a7bb"), lineWidth: 2)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: viewModel.currentOnboardingStep.imageName)
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(Color(hex: "ffce3d"))
                                .scaleEffect(viewModel.showTutorialAnimation ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.showTutorialAnimation)
                        }
                        
                        // Text content
                        VStack(spacing: 16) {
                            Text(viewModel.currentOnboardingStep.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(viewModel.currentOnboardingStep.description)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 32)
                        
                        // Tutorial animation area
                        if viewModel.currentStep == 1 { // Rhythm synchronization step
                            RhythmTutorialView()
                                .frame(height: 100)
                        } else if viewModel.currentStep == 2 { // Energy collection step
                            EnergyTutorialView()
                                .frame(height: 100)
                        } else if viewModel.currentStep == 3 { // Obstacle avoidance step
                            ObstacleTutorialView()
                                .frame(height: 100)
                        }
                    }
                    
                    Spacer()
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        if viewModel.currentStep > 0 {
                            ButtonView(
                                title: "Back",
                                icon: "chevron.left",
                                style: .ghost
                            ) {
                                viewModel.previousStep()
                            }
                        }
                        
                        Spacer()
                        
                        if viewModel.isLastStep {
                            AnimatedButtonView(
                                title: viewModel.currentOnboardingStep.action,
                                icon: "play.fill",
                                style: .primary
                            ) {
                                viewModel.nextStep()
                                isPresented = false
                            }
                        } else {
                            ButtonView(
                                title: viewModel.currentOnboardingStep.action,
                                icon: "chevron.right",
                                style: .primary
                            ) {
                                viewModel.nextStep()
                                if viewModel.currentStep == 1 {
                                    viewModel.startTutorialAnimation()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Tutorial Components
struct RhythmTutorialView: View {
    @State private var beatAnimation: Bool = false
    @State private var tapCircles: [TapCircle] = []
    
    var body: some View {
        ZStack {
            // Beat indicator
            Circle()
                .stroke(Color(hex: "40a7bb"), lineWidth: 3)
                .frame(width: 60, height: 60)
                .scaleEffect(beatAnimation ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: false), value: beatAnimation)
            
            // Tap circles
            ForEach(tapCircles, id: \.id) { circle in
                Circle()
                    .fill(Color(hex: "ffce3d").opacity(circle.opacity))
                    .frame(width: circle.size, height: circle.size)
                    .scaleEffect(circle.scale)
                    .position(circle.position)
            }
            
            Text("Tap to the beat!")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .offset(y: 50)
        }
        .onAppear {
            startBeatAnimation()
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    addTapCircle(at: value.location)
                }
        )
    }
    
    private func startBeatAnimation() {
        beatAnimation = true
    }
    
    private func addTapCircle(at location: CGPoint) {
        let newCircle = TapCircle(position: location)
        tapCircles.append(newCircle)
        
        withAnimation(.easeOut(duration: 0.5)) {
            if let index = tapCircles.firstIndex(where: { $0.id == newCircle.id }) {
                tapCircles[index].scale = 2.0
                tapCircles[index].opacity = 0.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tapCircles.removeAll { $0.id == newCircle.id }
        }
    }
    
    struct TapCircle {
        let id = UUID()
        let position: CGPoint
        var scale: CGFloat = 0.5
        var opacity: Double = 0.8
        var size: CGFloat = 30
    }
}

struct EnergyTutorialView: View {
    @State private var energyBalls: [EnergyBall] = []
    @State private var collectedCount: Int = 0
    
    var body: some View {
        ZStack {
            // Energy collection area
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "40a7bb").opacity(0.5), lineWidth: 2)
                .frame(width: 200, height: 80)
            
            // Energy balls
            ForEach(energyBalls, id: \.id) { ball in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "ffce3d"), Color(hex: "ffce3d").opacity(0.3)],
                            center: .center,
                            startRadius: 5,
                            endRadius: 15
                        )
                    )
                    .frame(width: 20, height: 20)
                    .position(ball.position)
                    .scaleEffect(ball.scale)
                    .opacity(ball.opacity)
                    .shadow(color: Color(hex: "ffce3d").opacity(0.6), radius: 4, x: 0, y: 0)
            }
            
            Text("Collect \(collectedCount)/5 energy")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .offset(y: 50)
        }
        .onAppear {
            spawnEnergyBalls()
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    collectEnergy(at: value.location)
                }
        )
    }
    
    private func spawnEnergyBalls() {
        energyBalls.removeAll()
        
        for i in 0..<5 {
            let delay = Double(i) * 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let x = Double.random(in: -80...80)
                let y = Double.random(in: -30...30)
                let ball = EnergyBall(position: CGPoint(x: x, y: y))
                energyBalls.append(ball)
            }
        }
    }
    
    private func collectEnergy(at location: CGPoint) {
        for i in energyBalls.indices.reversed() {
            let ball = energyBalls[i]
            let distance = sqrt(pow(ball.position.x - location.x, 2) + pow(ball.position.y - location.y, 2))
            
            if distance < 30 {
                collectedCount += 1
                
                withAnimation(.easeOut(duration: 0.3)) {
                    energyBalls[i].scale = 1.5
                    energyBalls[i].opacity = 0.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    energyBalls.remove(at: i)
                }
                
                // Respawn if needed
                if collectedCount < 5 && energyBalls.count < 3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        let x = Double.random(in: -80...80)
                        let y = Double.random(in: -30...30)
                        let ball = EnergyBall(position: CGPoint(x: x, y: y))
                        energyBalls.append(ball)
                    }
                }
                
                break
            }
        }
    }
    
    struct EnergyBall {
        let id = UUID()
        let position: CGPoint
        var scale: CGFloat = 1.0
        var opacity: Double = 1.0
    }
}

struct ObstacleTutorialView: View {
    @State private var obstacles: [MovingObstacle] = []
    @State private var shipPosition: CGPoint = CGPoint(x: -80, y: 0)
    @State private var isShipSafe: Bool = true
    
    var body: some View {
        ZStack {
            // Movement area
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "40a7bb").opacity(0.5), lineWidth: 2)
                .frame(width: 200, height: 80)
            
            // Ship
            Circle()
                .fill(isShipSafe ? Color(hex: "40a7bb") : Color.red)
                .frame(width: 16, height: 16)
                .position(shipPosition)
                .shadow(color: isShipSafe ? Color(hex: "40a7bb").opacity(0.6) : Color.red.opacity(0.6), radius: 4, x: 0, y: 0)
            
            // Obstacles
            ForEach(obstacles, id: \.id) { obstacle in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                    .position(obstacle.position)
                    .shadow(color: Color.red.opacity(0.6), radius: 2, x: 0, y: 0)
            }
            
            Text("Avoid the red obstacles!")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .offset(y: 50)
        }
        .onAppear {
            startObstacleAnimation()
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    moveShip(to: value.location)
                }
        )
    }
    
    private func startObstacleAnimation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            spawnObstacle()
        }
        spawnObstacle() // Initial obstacle
    }
    
    private func spawnObstacle() {
        let y = Double.random(in: -30...30)
        let obstacle = MovingObstacle(position: CGPoint(x: 100, y: y))
        obstacles.append(obstacle)
        
        // Animate obstacle movement
        withAnimation(.linear(duration: 3.0)) {
            if let index = obstacles.firstIndex(where: { $0.id == obstacle.id }) {
                obstacles[index].position.x = -100
            }
        }
        
        // Remove obstacle after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            obstacles.removeAll { $0.id == obstacle.id }
        }
    }
    
    private func moveShip(to location: CGPoint) {
        // Constrain ship movement to the tutorial area
        let constrainedX = max(-80, min(80, location.x))
        let constrainedY = max(-30, min(30, location.y))
        let newPosition = CGPoint(x: constrainedX, y: constrainedY)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            shipPosition = newPosition
        }
        
        // Check for collisions
        checkCollisions()
    }
    
    private func checkCollisions() {
        isShipSafe = true
        
        for obstacle in obstacles {
            let distance = sqrt(pow(shipPosition.x - obstacle.position.x, 2) + pow(shipPosition.y - obstacle.position.y, 2))
            if distance < 20 {
                isShipSafe = false
                
                // Flash effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isShipSafe = true
                }
                break
            }
        }
    }
    
    struct MovingObstacle {
        let id = UUID()
        var position: CGPoint
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
