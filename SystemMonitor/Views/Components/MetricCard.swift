import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let chart: AnyView?

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color,
        chart: AnyView? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.chart = chart
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(title)
                    .font(.cardTitle)
                    .foregroundColor(.white)

                Spacer()
            }

            // Value
            Text(value)
                .font(.metricValue)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, color.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.metricSubtitle)
                    .foregroundColor(.white.opacity(0.7))
            }

            // Chart
            if let chart = chart {
                chart
                    .frame(height: 80)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

// MARK: - Compact Metric Row

struct CompactMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.metricTitle)
                    .foregroundColor(.white.opacity(0.7))

                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 12, opacity: 0.5)
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let color: Color
    let lineWidth: CGFloat

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: animatedProgress)
        }
        .onAppear {
            animatedProgress = min(max(progress, 0), 1)
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = min(max(newValue, 0), 1)
            }
        }
    }
}

// MARK: - Metric Card with Ring

struct MetricCardWithRing: View {
    let title: String
    let value: String
    let percentage: Double // 0.0 to 100.0
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Text(title)
                    .font(.cardTitle)
                    .foregroundColor(.white)

                Spacer()
            }

            // Ring and value
            ZStack {
                ProgressRing(
                    progress: percentage / 100.0,
                    color: color,
                    lineWidth: 12
                )
                .frame(width: 120, height: 120)

                VStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(String(format: "%.1f%%", percentage))
                        .font(.metricSubtitle)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}
