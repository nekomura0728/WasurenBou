//
//  DesignSystem.swift
//  WasurenBou
//
//  Created by Claude on 2025/08/07.
//

import SwiftUI

// MARK: - Card Style Modifier
struct CardStyle: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color(.systemBackground))
            .cornerRadius(cornerRadius)
            .shadow(color: Color(.systemGray).opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Button Style Modifiers
struct PrimaryButtonStyle: ViewModifier {
    var isPressed: Bool = false
    
    func body(content: Content) -> some View {
        content
            .font(.body)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.themePrimaryBlue)
            .cornerRadius(12)
            .shadow(color: Color.themePrimaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

struct SecondaryButtonStyle: ViewModifier {
    var isPressed: Bool = false
    
    func body(content: Content) -> some View {
        content
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Loading Skeleton
struct SkeletonModifier: ViewModifier {
    @State private var opacity: Double = 0.4
    
    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray5).opacity(0.3),
                        Color(.systemGray4).opacity(0.5),
                        Color(.systemGray5).opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: opacity
                )
            )
            .onAppear {
                opacity = 1.0
            }
    }
}

// MARK: - Accessibility Modifiers
struct AccessibleText: ViewModifier {
    var maxSize: DynamicTypeSize = .accessibility2
    
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...maxSize)
    }
}

// MARK: - Error State Modifier
struct ErrorStateModifier: ViewModifier {
    var message: String
    var onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color("Danger"))
                        
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(.primary)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        
                        Spacer()
                        
                        Button("×") {
                            onDismiss()
                        }
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("エラーメッセージを閉じる")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color(.systemGray).opacity(0.2), radius: 4, x: 0, y: 2)
                    .padding()
                }
                .animation(.easeInOut, value: message)
            )
    }
}

// MARK: - Responsive Layout Helper
struct ResponsiveLayout: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var compactPadding: CGFloat = 16
    var regularPadding: CGFloat = 32
    
    private var padding: CGFloat {
        horizontalSizeClass == .regular ? regularPadding : compactPadding
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, padding)
    }
}

// MARK: - Extension for Easy Usage
extension View {
    func cardStyle(padding: CGFloat = 16, cornerRadius: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding, cornerRadius: cornerRadius))
    }
    
    func primaryButton(isPressed: Bool = false) -> some View {
        modifier(PrimaryButtonStyle(isPressed: isPressed))
    }
    
    func secondaryButton(isPressed: Bool = false) -> some View {
        modifier(SecondaryButtonStyle(isPressed: isPressed))
    }
    
    func skeleton() -> some View {
        modifier(SkeletonModifier())
    }
    
    func accessibleText(maxSize: DynamicTypeSize = .accessibility2) -> some View {
        modifier(AccessibleText(maxSize: maxSize))
    }
    
    func errorState(message: String, onDismiss: @escaping () -> Void) -> some View {
        modifier(ErrorStateModifier(message: message, onDismiss: onDismiss))
    }
    
    func responsiveLayout(compact: CGFloat = 16, regular: CGFloat = 32) -> some View {
        modifier(ResponsiveLayout(compactPadding: compact, regularPadding: regular))
    }
}

// MARK: - Haptic Feedback Helper
struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Animation Presets
extension Animation {
    static let cardPress = Animation.easeInOut(duration: 0.1)
    static let slideIn = Animation.easeOut(duration: 0.3)
    static let fadeIn = Animation.easeIn(duration: 0.2)
    static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.6)
}

// MARK: - Color Theme
extension Color {
    // Custom theme colors
    static let themePrimaryBlue = Color(red: 0.243, green: 0.569, blue: 0.933)
    static let themeSuccessGreen = Color(red: 0.298, green: 0.733, blue: 0.400)
    static let themeWarningOrange = Color(red: 1.0, green: 0.647, blue: 0.0)
    static let themeDangerRed = Color(red: 0.878, green: 0.353, blue: 0.380)
    
    // System colors for convenience
    static let systemCardBackground = Color(.systemBackground)
    static let systemGroupedBackground = Color(.systemGroupedBackground)
    static let systemSecondaryBackground = Color(.secondarySystemBackground)
    static let systemTertiaryBackground = Color(.tertiarySystemBackground)
}