import SwiftUI

struct CPUView: View {
    @EnvironmentObject var monitor: SystemMonitorViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let cpu = monitor.cpuMetrics {
                    // Main CPU Usage Card with Ring
                    HStack(spacing: 20) {
                        MetricCardWithRing(
                            title: "Total CPU",
                            value: String(format: "%.1f%%", cpu.totalUsage),
                            percentage: cpu.totalUsage,
                            icon: "cpu",
                            color: MetricColors.cpuColor(usage: cpu.totalUsage)
                        )

                        VStack(spacing: 12) {
                            CompactMetricRow(
                                icon: "person.fill",
                                title: "User",
                                value: String(format: "%.1f%%", cpu.userUsage),
                                color: .blue
                            )

                            CompactMetricRow(
                                icon: "gear",
                                title: "System",
                                value: String(format: "%.1f%%", cpu.systemUsage),
                                color: .purple
                            )

                            CompactMetricRow(
                                icon: "moon.fill",
                                title: "Idle",
                                value: String(format: "%.1f%%", cpu.idleUsage),
                                color: .green
                            )
                        }
                    }

                    // CPU History Chart
                    MetricCard(
                        title: "CPU Usage History",
                        value: String(format: "%.1f%%", cpu.totalUsage),
                        subtitle: "Last 60 seconds",
                        icon: "chart.line.uptrend.xyaxis",
                        color: MetricColors.cpuColor(usage: cpu.totalUsage),
                        chart: AnyView(
                            AnimatedLineChart(
                                data: monitor.cpuHistory,
                                color: MetricColors.cpuColor(usage: cpu.totalUsage),
                                maxValue: 100
                            )
                        )
                    )

                    // Per-Core Usage
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.title2)
                                .foregroundStyle(.cyan)

                            Text("Per-Core Usage")
                                .font(.cardTitle)
                                .foregroundColor(.white)

                            Spacer()

                            Text("\(cpu.coreCount) Cores")
                                .font(.metricSubtitle)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(Array(cpu.perCoreUsage.enumerated()), id: \.offset) { index, usage in
                                CoreUsageView(coreNumber: index, usage: usage)
                            }
                        }
                    }
                    .padding(20)
                    .glassCard()

                    // CPU Info
                    HStack(spacing: 20) {
                        if let frequency = cpu.frequency {
                            CompactMetricRow(
                                icon: "waveform.path",
                                title: "Frequency",
                                value: String(format: "%.2f GHz", frequency),
                                color: .orange
                            )
                        }

                        if let temperature = cpu.temperature {
                            CompactMetricRow(
                                icon: "thermometer.medium",
                                title: "Temperature",
                                value: String(format: "%.1f°C", temperature),
                                color: temperature > 80 ? .red : .green
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

struct CoreUsageView: View {
    let coreNumber: Int
    let usage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Core \(coreNumber)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Text(String(format: "%.1f%%", usage))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(MetricColors.cpuColor(usage: usage))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    MetricColors.cpuColor(usage: usage),
                                    MetricColors.cpuColor(usage: usage).opacity(0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(usage / 100.0))
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
    }
}
