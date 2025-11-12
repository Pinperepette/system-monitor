import SwiftUI

enum NavigationItem: String, CaseIterable {
    case overview = "Overview"
    case cpu = "CPU"
    case memory = "Memory"
    case diskNetwork = "Disk & Network"
    case processes = "Processes"

    var icon: String {
        switch self {
        case .overview:
            return "gauge.with.dots.needle.67percent"
        case .cpu:
            return "cpu"
        case .memory:
            return "memorychip"
        case .diskNetwork:
            return "externaldrive.connected.to.line.below"
        case .processes:
            return "gearshape.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .overview:
            return .cyan
        case .cpu:
            return .blue
        case .memory:
            return .purple
        case .diskNetwork:
            return .green
        case .processes:
            return .orange
        }
    }
}

struct MainView: View {
    @EnvironmentObject var monitor: SystemMonitorViewModel
    @State private var selectedItem: NavigationItem = .overview
    @State private var isSidebarVisible = true

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            if isSidebarVisible {
                sidebar
                    .frame(width: 200)
                    .transition(.move(edge: .leading))
            }

            // Main content area
            contentView
        }
        .glassBackground()
    }

    @ViewBuilder
    private var sidebar: some View {
        VStack(spacing: 0) {
            // App header
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("System Monitor")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Real-time Analytics")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 30)
            .padding(.bottom, 20)

            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical, 10)

            // Navigation items
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(NavigationItem.allCases, id: \.self) { item in
                        NavigationButton(
                            item: item,
                            isSelected: selectedItem == item
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedItem = item
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
            }

            Spacer()

            // System status indicators
            VStack(spacing: 8) {
                if let cpu = monitor.cpuMetrics {
                    MiniStatusIndicator(
                        icon: "cpu",
                        value: String(format: "%.0f%%", cpu.totalUsage),
                        color: MetricColors.cpuColor(usage: cpu.totalUsage)
                    )
                }

                if let memory = monitor.memoryMetrics {
                    MiniStatusIndicator(
                        icon: "memorychip",
                        value: String(format: "%.0f%%", memory.usagePercentage),
                        color: MetricColors.memoryColor(usage: memory.usagePercentage)
                    )
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
            )
            .padding(12)
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        )
    }

    @ViewBuilder
    private var contentView: some View {
        ZStack(alignment: .topLeading) {
            // Main content
            Group {
                switch selectedItem {
                case .overview:
                    OverviewView()
                case .cpu:
                    CPUView()
                case .memory:
                    MemoryView()
                case .diskNetwork:
                    DiskNetworkView()
                case .processes:
                    ProcessView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Sidebar toggle button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isSidebarVisible.toggle()
                }
            } label: {
                Image(systemName: isSidebarVisible ? "sidebar.left" : "sidebar.right")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.7)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
            .padding(.leading, 20)
        }
    }
}

struct NavigationButton: View {
    let item: NavigationItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundStyle(
                        isSelected ?
                            LinearGradient(
                                colors: [item.color, item.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 24)

                Text(item.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? item.color.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? item.color.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct MiniStatusIndicator: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 16)

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)

            Spacer()
        }
    }
}

// MARK: - Overview View

struct OverviewView: View {
    @EnvironmentObject var monitor: SystemMonitorViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Welcome header
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Overview")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Real-time system performance monitoring")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 60)
                .padding(.bottom, 10)

                // Quick stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    if let cpu = monitor.cpuMetrics {
                        MetricCardWithRing(
                            title: "CPU Usage",
                            value: String(format: "%.1f%%", cpu.totalUsage),
                            percentage: cpu.totalUsage,
                            icon: "cpu",
                            color: MetricColors.cpuColor(usage: cpu.totalUsage)
                        )
                    }

                    if let memory = monitor.memoryMetrics {
                        MetricCardWithRing(
                            title: "Memory",
                            value: monitor.formatBytes(memory.used),
                            percentage: memory.usagePercentage,
                            icon: "memorychip",
                            color: MetricColors.memoryColor(usage: memory.usagePercentage)
                        )
                    }
                }

                // Combined activity chart
                if let network = monitor.networkMetrics {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .font(.title2)
                                .foregroundStyle(.cyan)

                            Text("System Activity")
                                .font(.cardTitle)
                                .foregroundColor(.white)

                            Spacer()
                        }

                        VStack(spacing: 20) {
                            // CPU and Memory
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(.blue)
                                            .frame(width: 8, height: 8)
                                        Text("CPU")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    AnimatedLineChart(
                                        data: monitor.cpuHistory,
                                        color: .blue,
                                        maxValue: 100
                                    )
                                    .frame(height: 80)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(.purple)
                                            .frame(width: 8, height: 8)
                                        Text("Memory")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    AnimatedLineChart(
                                        data: monitor.memoryHistory,
                                        color: .purple,
                                        maxValue: 100
                                    )
                                    .frame(height: 80)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .glassCard()
                }

                // Quick actions or additional info
                HStack(spacing: 20) {
                    if let disk = monitor.diskMetrics {
                        CompactMetricRow(
                            icon: "internaldrive.fill",
                            title: "Disk Activity",
                            value: "\(monitor.formatBytesPerSecond(disk.readBytesPerSecond)) R / \(monitor.formatBytesPerSecond(disk.writeBytesPerSecond)) W",
                            color: .cyan
                        )
                    }
                }

                if let network = monitor.networkMetrics {
                    HStack(spacing: 20) {
                        CompactMetricRow(
                            icon: "arrow.down.circle.fill",
                            title: "Download",
                            value: monitor.formatBytesPerSecond(network.downloadSpeedBytesPerSecond),
                            color: .blue
                        )

                        CompactMetricRow(
                            icon: "arrow.up.circle.fill",
                            title: "Upload",
                            value: monitor.formatBytesPerSecond(network.uploadSpeedBytesPerSecond),
                            color: .purple
                        )
                    }
                }
            }
            .padding(20)
        }
    }
}
