//
//  ButtonView.swift
//  ChronoPulse Forest
//
//  Created by Вячеслав on 9/11/25.
//

import SwiftUI

struct ButtonView: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let style: ButtonStyle
    let isEnabled: Bool
    
    @State private var isPressed: Bool = false
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case ghost
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Color(hex: "40a7bb")
            case .secondary: return Color(hex: "f0dcbc")
            case .destructive: return Color.red
            case .ghost: return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return Color(hex: "1a2e35")
            case .destructive: return .white
            case .ghost: return Color(hex: "40a7bb")
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .ghost: return Color(hex: "40a7bb")
            default: return nil
            }
        }
    }
    
    init(title: String, icon: String? = nil, style: ButtonStyle = .primary, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if isEnabled {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                action()
            }
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(isEnabled ? style.foregroundColor : style.foregroundColor.opacity(0.5))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? style.backgroundColor : style.backgroundColor.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style.borderColor ?? Color.clear, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .disabled(!isEnabled)
    }
}

// MARK: - Animated Button
struct AnimatedButtonView: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let style: ButtonView.ButtonStyle
    let isEnabled: Bool
    
    @State private var isAnimating: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    
    init(title: String, icon: String? = nil, style: ButtonView.ButtonStyle = .primary, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        ButtonView(title: title, icon: icon, style: style, isEnabled: isEnabled, action: action)
            .scaleEffect(pulseScale)
            .onAppear {
                startPulseAnimation()
            }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
    }
}

// MARK: - Icon Button
struct IconButtonView: View {
    let icon: String
    let action: () -> Void
    let style: ButtonView.ButtonStyle
    let size: CGFloat
    let isEnabled: Bool
    
    @State private var isPressed: Bool = false
    
    init(icon: String, style: ButtonView.ButtonStyle = .primary, size: CGFloat = 44, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.icon = icon
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if isEnabled {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(isEnabled ? style.foregroundColor : style.foregroundColor.opacity(0.5))
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isEnabled ? style.backgroundColor : style.backgroundColor.opacity(0.3))
                        .overlay(
                            Circle()
                                .stroke(style.borderColor ?? Color.clear, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.2), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
                )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .disabled(!isEnabled)
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    let backgroundColor: Color
    let foregroundColor: Color
    
    @State private var isVisible: Bool = false
    @State private var rotationAngle: Double = 0
    
    init(icon: String, backgroundColor: Color = Color(hex: "40a7bb"), foregroundColor: Color = .white, action: @escaping () -> Void) {
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                rotationAngle += 360
            }
            
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(foregroundColor)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(backgroundColor)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .rotationEffect(.degrees(rotationAngle))
        }
        .scaleEffect(isVisible ? 1.0 : 0.0)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ButtonView(title: "Primary Button", icon: "play.fill", style: .primary) {}
        ButtonView(title: "Secondary Button", icon: "gear", style: .secondary) {}
        ButtonView(title: "Destructive Button", icon: "trash", style: .destructive) {}
        ButtonView(title: "Ghost Button", icon: "info.circle", style: .ghost) {}
        ButtonView(title: "Disabled Button", style: .primary, isEnabled: false) {}
        
        HStack(spacing: 20) {
            IconButtonView(icon: "play.fill") {}
            IconButtonView(icon: "pause.fill", style: .secondary) {}
            IconButtonView(icon: "stop.fill", style: .destructive) {}
        }
        
        AnimatedButtonView(title: "Animated Button", icon: "star.fill") {}
        
        FloatingActionButton(icon: "plus") {}
    }
    .padding()
    .background(Color(hex: "257792"))
}
