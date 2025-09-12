//
//  OnboardingViewModel.swift
//  ChronoPulse Forest
//
//  Created by Вячеслав on 9/11/25.
//

import SwiftUI
import Foundation

class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var isCompleted: Bool = false
    @Published var showTutorialAnimation: Bool = false
    @Published var tutorialProgress: Double = 0.0
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    let onboardingSteps = [
        OnboardingStep(
            title: "Welcome to ChronoPulse Forest",
            description: "Navigate through time-themed levels by synchronizing with the rhythm",
            imageName: "waveform.path.ecg",
            action: "Let's Begin"
        ),
        OnboardingStep(
            title: "Rhythm Synchronization",
            description: "Tap in sync with the beats to move your time ship efficiently",
            imageName: "music.note",
            action: "Try It"
        ),
        OnboardingStep(
            title: "Collect Time Energy",
            description: "Gather glowing time energy to fuel your journey and increase your score",
            imageName: "bolt.fill",
            action: "Got It"
        ),
        OnboardingStep(
            title: "Avoid Obstacles",
            description: "Navigate around obstacles while staying in rhythm to survive",
            imageName: "exclamationmark.triangle.fill",
            action: "Understood"
        ),
        OnboardingStep(
            title: "Ready to Play!",
            description: "You're all set! Start your journey through the ChronoPulse Forest",
            imageName: "play.fill",
            action: "Start Game"
        )
    ]
    
    var currentOnboardingStep: OnboardingStep {
        guard currentStep < onboardingSteps.count else {
            return onboardingSteps.last!
        }
        return onboardingSteps[currentStep]
    }
    
    var isLastStep: Bool {
        return currentStep >= onboardingSteps.count - 1
    }
    
    var progressPercentage: Double {
        return Double(currentStep + 1) / Double(onboardingSteps.count)
    }
    
    init() {
        self.isCompleted = hasCompletedOnboarding
    }
    
    func nextStep() {
        withAnimation(.easeInOut(duration: 0.5)) {
            if currentStep < onboardingSteps.count - 1 {
                currentStep += 1
                updateTutorialProgress()
            } else {
                completeOnboarding()
            }
        }
    }
    
    func previousStep() {
        withAnimation(.easeInOut(duration: 0.5)) {
            if currentStep > 0 {
                currentStep -= 1
                updateTutorialProgress()
            }
        }
    }
    
    func skipOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        isCompleted = true
        hasCompletedOnboarding = true
        
        // Add completion haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func updateTutorialProgress() {
        tutorialProgress = progressPercentage
        
        // Add step transition haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func startTutorialAnimation() {
        showTutorialAnimation = true
        
        // Stop animation after a duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showTutorialAnimation = false
        }
    }
    
    func resetOnboarding() {
        currentStep = 0
        isCompleted = false
        hasCompletedOnboarding = false
        tutorialProgress = 0.0
        showTutorialAnimation = false
    }
}

struct OnboardingStep {
    let title: String
    let description: String
    let imageName: String
    let action: String
}
