//
//  AnimationSystem.swift
//  WasurenBou
//
//  Created by Claude on 2025/08/07.
//

import SwiftUI

// MARK: - Skeleton Loading View
struct SkeletonView: View {
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemGray5)
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray5),
                        Color(.systemGray4).opacity(0.5),
                        Color(.systemGray5)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geometry.size.width * 0.4)
                .offset(x: shimmerOffset * geometry.size.width)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: shimmerOffset
                )
            }
        }
        .onAppear {
            shimmerOffset = 2
        }
    }
}

// MARK: - Loading State View
struct LoadingStateView: View {
    let message: String
    @State private var dots = ""
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text(message + dots)
                .font(.body)
                .foregroundColor(.secondary)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        }
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.systemGray).opacity(0.2), radius: 8, x: 0, y: 4)
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation {
                dots = dots.count >= 3 ? "" : dots + "."
            }
        }
    }
}

// MARK: - Transition Animations
extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var scaleAndFade: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }
    
    static var bottomSheet: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
}

// MARK: - Animated Card Press
struct CardPressModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(
                minimumDuration: .infinity,
                maximumDistance: .infinity,
                pressing: { pressing in
                    isPressed = pressing
                },
                perform: {}
            )
    }
}

// MARK: - Pulse Animation
struct PulseModifier: ViewModifier {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                ) {
                    scale = 1.1
                    opacity = 0.7
                }
            }
    }
}

// MARK: - Slide In Animation
struct SlideInModifier: ViewModifier {
    @State private var appeared = false
    var delay: Double = 0
    var edge: Edge = .bottom
    
    func body(content: Content) -> some View {
        content
            .offset(y: appeared ? 0 : (edge == .bottom ? 50 : -50))
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(
                    Animation.spring(response: 0.5, dampingFraction: 0.8)
                        .delay(delay)
                ) {
                    appeared = true
                }
            }
    }
}

// MARK: - Stagger Animation Helper
struct StaggeredAnimation<Content: View>: View {
    let items: [AnyHashable]
    let content: (AnyHashable, Int) -> Content
    let staggerDelay: Double
    
    @State private var appeared = false
    
    init(
        items: [AnyHashable],
        staggerDelay: Double = 0.05,
        @ViewBuilder content: @escaping (AnyHashable, Int) -> Content
    ) {
        self.items = items
        self.staggerDelay = staggerDelay
        self.content = content
    }
    
    var body: some View {
        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
            content(item, index)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(
                    Animation.spring(response: 0.4, dampingFraction: 0.8)
                        .delay(Double(index) * staggerDelay),
                    value: appeared
                )
        }
        .onAppear {
            appeared = true
        }
    }
}

// MARK: - Animated Number
struct AnimatedNumber: View {
    let value: Int
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .onAppear {
                animate()
            }
            .onChange(of: value) {
                animate()
            }
    }
    
    private func animate() {
        let duration = 0.5
        let steps = 20
        let stepDuration = duration / Double(steps)
        let stepValue = (value - displayValue) / steps
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.linear(duration: stepDuration)) {
                    if i == steps - 1 {
                        displayValue = value
                    } else {
                        displayValue += stepValue
                    }
                }
            }
        }
    }
}

// MARK: - Success Animation View
struct SuccessAnimationView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var checkmarkScale: CGFloat = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 100, height: 100)
                .scaleEffect(scale)
                .opacity(opacity)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .scaleEffect(checkmarkScale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
                checkmarkScale = 1.0
            }
            
            // Auto dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                    scale = 1.2
                }
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func cardPress() -> some View {
        modifier(CardPressModifier())
    }
    
    func pulse() -> some View {
        modifier(PulseModifier())
    }
    
    func slideIn(delay: Double = 0, edge: Edge = .bottom) -> some View {
        modifier(SlideInModifier(delay: delay, edge: edge))
    }
    
    func shimmer() -> some View {
        overlay(SkeletonView())
            .clipped()
    }
    
    func loadingOverlay(isLoading: Bool, message: String = "読み込み中") -> some View {
        overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
                    LoadingStateView(message: message)
                        .transition(.scaleAndFade)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        )
    }
}