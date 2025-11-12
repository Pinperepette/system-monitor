import SwiftUI

// MARK: - Glassmorphism Modifiers

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.7

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

struct GlassBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Animated gradient background
                    AnimatedGradientBackground()

                    // Blur overlay
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                }
                .ignoresSafeArea()
            )
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    let colors: [Color] = [
        Color(red: 0.2, green: 0.4, blue: 0.8),
        Color(red: 0.4, green: 0.2, blue: 0.8),
        Color(red: 0.8, green: 0.2, blue: 0.6),
        Color(red: 0.2, green: 0.6, blue: 0.8)
    ]

    var body: some View {
        LinearGradient(
            colors: animateGradient ? colors : colors.reversed(),
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 5.0)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = 20, opacity: Double = 0.7) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, opacity: opacity))
    }

    func glassBackground() -> some View {
        modifier(GlassBackgroundModifier())
    }
}

// MARK: - Metric Status Colors

struct MetricColors {
    static func cpuColor(usage: Double) -> Color {
        switch usage {
        case 0..<50:
            return Color.green
        case 50..<80:
            return Color.yellow
        default:
            return Color.red
        }
    }

    static func memoryColor(usage: Double) -> Color {
        switch usage {
        case 0..<60:
            return Color.green
        case 60..<85:
            return Color.yellow
        default:
            return Color.red
        }
    }

    static func diskColor(usage: Double) -> Color {
        switch usage {
        case 0..<70:
            return Color.green
        case 70..<90:
            return Color.yellow
        default:
            return Color.red
        }
    }

    static let networkDownload = Color.blue
    static let networkUpload = Color.purple

    static let chartGradient = LinearGradient(
        colors: [
            Color.blue.opacity(0.8),
            Color.purple.opacity(0.6)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography

extension Font {
    static let metricTitle = Font.system(size: 14, weight: .medium, design: .rounded)
    static let metricValue = Font.system(size: 32, weight: .bold, design: .rounded)
    static let metricSubtitle = Font.system(size: 12, weight: .regular, design: .rounded)
    static let cardTitle = Font.system(size: 18, weight: .semibold, design: .rounded)
}
