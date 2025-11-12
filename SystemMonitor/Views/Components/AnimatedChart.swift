import SwiftUI

struct AnimatedLineChart: View {
    let data: [Double]
    let color: Color
    let maxValue: Double?
    let showGradient: Bool

    @State private var animationProgress: CGFloat = 0

    init(data: [Double], color: Color, maxValue: Double? = nil, showGradient: Bool = true) {
        self.data = data
        self.color = color
        self.maxValue = maxValue
        self.showGradient = showGradient
    }

    var body: some View {
        GeometryReader { geometry in
            let maxDataValue = maxValue ?? (data.max() ?? 1.0)
            let points = normalizedPoints(
                data: data,
                maxValue: maxDataValue,
                width: geometry.size.width,
                height: geometry.size.height
            )

            ZStack(alignment: .bottom) {
                // Gradient fill
                if showGradient {
                    ChartPath(points: points, closed: true)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.4),
                                    color.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .mask(
                            Rectangle()
                                .fill()
                                .frame(width: geometry.size.width * animationProgress)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                }

                // Line stroke
                ChartPath(points: points, closed: false)
                    .trim(from: 0, to: animationProgress)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: 2.5,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 2)

                // Animated dots at data points
                if animationProgress >= 1.0 {
                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        if index % max(1, points.count / 10) == 0 { // Show every 10th point
                            Circle()
                                .fill(color)
                                .frame(width: 6, height: 6)
                                .position(point)
                                .shadow(color: color.opacity(0.6), radius: 3)
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
        .onChange(of: data) { _, _ in
            animationProgress = 0
            withAnimation(.easeOut(duration: 0.3)) {
                animationProgress = 1.0
            }
        }
    }

    private func normalizedPoints(data: [Double], maxValue: Double, width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard !data.isEmpty else { return [] }

        let xStep = width / CGFloat(max(data.count - 1, 1))
        let yScale = height / CGFloat(maxValue)

        return data.enumerated().map { index, value in
            let x = CGFloat(index) * xStep
            let y = height - (CGFloat(value) * yScale)
            return CGPoint(x: x, y: max(0, y))
        }
    }
}

struct ChartPath: Shape {
    let points: [CGPoint]
    let closed: Bool

    func path(in rect: CGRect) -> Path {
        guard points.count > 1 else { return Path() }

        var path = Path()
        path.move(to: points[0])

        for i in 1..<points.count {
            let current = points[i]
            let previous = points[i - 1]

            let controlPoint1 = CGPoint(
                x: previous.x + (current.x - previous.x) / 3,
                y: previous.y
            )
            let controlPoint2 = CGPoint(
                x: previous.x + 2 * (current.x - previous.x) / 3,
                y: current.y
            )

            path.addCurve(to: current, control1: controlPoint1, control2: controlPoint2)
        }

        if closed {
            path.addLine(to: CGPoint(x: points.last!.x, y: rect.height))
            path.addLine(to: CGPoint(x: points.first!.x, y: rect.height))
            path.closeSubpath()
        }

        return path
    }
}

// MARK: - Multi-line Chart

struct MultiLineChart: View {
    let datasets: [(data: [Double], color: Color, name: String)]
    let maxValue: Double?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid lines
                GridLines()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)

                // Charts
                ForEach(Array(datasets.enumerated()), id: \.offset) { _, dataset in
                    AnimatedLineChart(
                        data: dataset.data,
                        color: dataset.color,
                        maxValue: maxValue,
                        showGradient: false
                    )
                }
            }
        }
    }
}

struct GridLines: Shape {
    let horizontalLines = 5
    let verticalLines = 10

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Horizontal lines
        for i in 0...horizontalLines {
            let y = rect.height * CGFloat(i) / CGFloat(horizontalLines)
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }

        // Vertical lines
        for i in 0...verticalLines {
            let x = rect.width * CGFloat(i) / CGFloat(verticalLines)
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }

        return path
    }
}

// MARK: - Bar Chart

struct AnimatedBarChart: View {
    let data: [Double]
    let labels: [String]
    let color: Color

    @State private var animatedHeights: [CGFloat] = []

    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.max() ?? 1.0
            let barWidth = (geometry.size.width - CGFloat(data.count - 1) * 8) / CGFloat(data.count)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(
                                width: barWidth,
                                height: animatedHeights.count > index ?
                                    animatedHeights[index] * geometry.size.height * 0.8 : 0
                            )

                        if index < labels.count {
                            Text(labels[index])
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                                .frame(width: barWidth)
                        }
                    }
                }
            }
        }
        .onAppear {
            animateIn()
        }
        .onChange(of: data) { _, _ in
            animateIn()
        }
    }

    private func animateIn() {
        let maxValue = data.max() ?? 1.0
        animatedHeights = Array(repeating: 0, count: data.count)

        for (index, value) in data.enumerated() {
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.7)
                .delay(Double(index) * 0.05)
            ) {
                animatedHeights[index] = CGFloat(value / maxValue)
            }
        }
    }
}
