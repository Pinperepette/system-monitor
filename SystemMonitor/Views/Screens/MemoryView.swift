import SwiftUI

struct MemoryView: View {
    @EnvironmentObject var monitor: SystemMonitorViewModel
    @State private var isPurgingMemory = false
    @State private var showPurgeAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let memory = monitor.memoryMetrics {
                    // Main Memory Usage with Ring
                    HStack(spacing: 20) {
                        MetricCardWithRing(
                            title: "Memory Usage",
                            value: monitor.formatBytes(memory.used),
                            percentage: memory.usagePercentage,
                            icon: "memorychip",
                            color: MetricColors.memoryColor(usage: memory.usagePercentage)
                        )

                        VStack(spacing: 12) {
                            CompactMetricRow(
                                icon: "circle.fill",
                                title: "Total",
                                value: monitor.formatBytes(memory.totalPhysical),
                                color: .white
                            )

                            CompactMetricRow(
                                icon: "checkmark.circle.fill",
                                title: "Available",
                                value: monitor.formatBytes(memory.free),
                                color: .green
                            )

                            CompactMetricRow(
                                icon: "exclamationmark.triangle.fill",
                                title: "Pressure",
                                value: memory.memoryPressure == .normal ? "Normal" :
                                       memory.memoryPressure == .warning ? "Warning" : "Critical",
                                color: memory.memoryPressure == .normal ? .green :
                                       memory.memoryPressure == .warning ? .yellow : .red
                            )
                        }
                    }

                    // Free Memory Button
                    Button {
                        showPurgeAlert = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isPurgingMemory ? "arrow.triangle.2.circlepath" : "trash.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.cyan)
                                .rotationEffect(.degrees(isPurgingMemory ? 360 : 0))
                                .animation(isPurgingMemory ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isPurgingMemory)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Free Inactive Memory")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)

                                Text(isPurgingMemory ? "Purging memory..." : "Clear cached and inactive memory")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(16)
                        .glassCard(cornerRadius: 12, opacity: 0.5)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurgingMemory)
                    .alert("Free Memory?", isPresented: $showPurgeAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Free Memory") {
                            purgeMemory()
                        }
                    } message: {
                        Text("This will clear inactive memory and cached data. The system may slow down briefly.")
                    }

                    // Memory History Chart
                    MetricCard(
                        title: "Memory Usage History",
                        value: String(format: "%.1f%%", memory.usagePercentage),
                        subtitle: "Last 60 seconds",
                        icon: "chart.line.uptrend.xyaxis",
                        color: MetricColors.memoryColor(usage: memory.usagePercentage),
                        chart: AnyView(
                            AnimatedLineChart(
                                data: monitor.memoryHistory,
                                color: MetricColors.memoryColor(usage: memory.usagePercentage),
                                maxValue: 100
                            )
                        )
                    )

                    // Memory Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "chart.pie.fill")
                                .font(.title2)
                                .foregroundStyle(.purple)

                            Text("Memory Breakdown")
                                .font(.cardTitle)
                                .foregroundColor(.white)

                            Spacer()
                        }

                        VStack(spacing: 12) {
                            MemoryBarView(
                                label: "Active",
                                value: memory.active,
                                total: memory.totalPhysical,
                                color: .green
                            )

                            MemoryBarView(
                                label: "Wired",
                                value: memory.wired,
                                total: memory.totalPhysical,
                                color: .red
                            )

                            MemoryBarView(
                                label: "Compressed",
                                value: memory.compressed,
                                total: memory.totalPhysical,
                                color: .orange
                            )

                            MemoryBarView(
                                label: "Inactive",
                                value: memory.inactive,
                                total: memory.totalPhysical,
                                color: .blue
                            )

                            MemoryBarView(
                                label: "Free",
                                value: memory.free,
                                total: memory.totalPhysical,
                                color: .gray
                            )
                        }
                    }
                    .padding(20)
                    .glassCard()

                    // Swap Usage
                    if memory.swapTotal > 0 {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.title2)
                                    .foregroundStyle(.yellow)

                                Text("Swap Memory")
                                    .font(.cardTitle)
                                    .foregroundColor(.white)

                                Spacer()
                            }

                            HStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Used")
                                        .font(.metricSubtitle)
                                        .foregroundColor(.white.opacity(0.7))

                                    Text(monitor.formatBytes(memory.swapUsed))
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 8) {
                                    Text("Total")
                                        .font(.metricSubtitle)
                                        .foregroundColor(.white.opacity(0.7))

                                    Text(monitor.formatBytes(memory.swapTotal))
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                colors: [.yellow, .orange],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(
                                            width: memory.swapTotal > 0 ?
                                                geometry.size.width * CGFloat(Double(memory.swapUsed) / Double(memory.swapTotal)) : 0
                                        )
                                }
                            }
                            .frame(height: 16)
                        }
                        .padding(20)
                        .glassCard()
                    }
                }
            }
            .padding(20)
        }
    }

    private func purgeMemory() {
        isPurgingMemory = true

        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.launchPath = "/usr/bin/sudo"
            task.arguments = ["-n", "purge"] // -n = non-interactive

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                try task.run()
                task.waitUntilExit()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isPurgingMemory = false
                }
            } catch {
                DispatchQueue.main.async {
                    isPurgingMemory = false
                }
            }
        }
    }
}

struct MemoryBarView: View {
    let label: String
    let value: UInt64
    let total: UInt64
    let color: Color

    var percentage: Double {
        total > 0 ? Double(value) / Double(total) * 100.0 : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.metricTitle)
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Text(ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .binary))
                    .font(.metricSubtitle)
                    .foregroundColor(.white.opacity(0.7))

                Text(String(format: "%.1f%%", percentage))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
                    .frame(width: 50, alignment: .trailing)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(percentage / 100.0))
                }
            }
            .frame(height: 8)
        }
    }
}
