//
//  ChronoPulseApp.swift
//  ChronoPulse Forest
//
//  Created by Вячеслав on 9/11/25.
//

import SwiftUI

@main
struct ChronoPulseApp: App {
    @StateObject private var gameViewModel = GameViewModel()
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameViewModel)
                .environmentObject(onboardingViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
