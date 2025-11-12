import SwiftUI

struct DiskNetworkView: View {
    @EnvironmentObject var monitor: SystemMonitorViewModel
    @State private var showInactiveNetworks = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Disk Section
                diskSection

                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, 10)

                // Network Section
                networkSection
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private var diskSection: some View {
        if let disk = monitor.diskMetrics {
            VStack(alignment: .leading, spacing: 20) {
                // Section Header
                HStack {
                    Image(systemName: "internaldrive.fill")
                        .font(.title)
                        .foregroundStyle(.cyan)

                    Text("Storage")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.leading, 60)

                // Disk I/O Activity
                HStack(spacing: 20) {
                    MetricCard(
                        title: "Read Speed",
                        value: monitor.formatBytesPerSecond(disk.readBytesPerSecond),
                        subtitle: "\(disk.readOperationsPerSecond) ops/s",
                        icon: "arrow.down.circle.fill",
                        color: .blue
                    )

                    MetricCard(
                        title: "Write Speed",
                        value: monitor.formatBytesPerSecond(disk.writeBytesPerSecond),
                        subtitle: "\(disk.writeOperationsPerSecond) ops/s",
                        icon: "arrow.up.circle.fill",
                        color: .purple
                    )
                }

                // Individual Disks
                ForEach(disk.disks) { diskInfo in
                    DiskInfoCard(disk: diskInfo, monitor: monitor)
                }
            }
        }
    }

    @ViewBuilder
    private var networkSection: some View {
        if let network = monitor.networkMetrics {
            VStack(alignment: .leading, spacing: 20) {
                // Section Header
                HStack {
                    Image(systemName: "network")
                        .font(.title)
                        .foregroundStyle(.green)

                    Text("Network")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    // Toggle for inactive networks
                    Button {
                        withAnimation {
                            showInactiveNetworks.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: showInactiveNetworks ? "eye.fill" : "eye.slash.fill")
                                .font(.system(size: 14))
                            Text(showInactiveNetworks ? "Hide Inactive" : "Show Inactive")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                                .opacity(0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 60)

                // Network Speed Overview
                HStack(spacing: 20) {
                    MetricCard(
                        title: "Download",
                        value: monitor.formatBytesPerSecond(network.downloadSpeedBytesPerSecond),
                        subtitle: "Total: \(monitor.formatBytes(network.totalBytesReceived))",
                        icon: "arrow.down.circle.fill",
                        color: .blue,
                        chart: AnyView(
                            AnimatedLineChart(
                                data: monitor.networkDownloadHistory,
                                color: .blue,
                                maxValue: nil
                            )
                        )
                    )

                    MetricCard(
                        title: "Upload",
                        value: monitor.formatBytesPerSecond(network.uploadSpeedBytesPerSecond),
                        subtitle: "Total: \(monitor.formatBytes(network.totalBytesSent))",
                        icon: "arrow.up.circle.fill",
                        color: .purple,
                        chart: AnyView(
                            AnimatedLineChart(
                                data: monitor.networkUploadHistory,
                                color: .purple,
                                maxValue: nil
                            )
                        )
                    )
                }

                // Combined Network Chart
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.title2)
                            .foregroundStyle(.cyan)

                        Text("Network Activity")
                            .font(.cardTitle)
                            .foregroundColor(.white)

                        Spacer()

                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                                Text("Download")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.purple)
                                    .frame(width: 8, height: 8)
                                Text("Upload")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }

                    MultiLineChart(
                        datasets: [
                            (data: monitor.networkDownloadHistory, color: .blue, name: "Download"),
                            (data: monitor.networkUploadHistory, color: .purple, name: "Upload")
                        ],
                        maxValue: nil
                    )
                    .frame(height: 150)
                }
                .padding(20)
                .glassCard()

                // Active Connections
                CompactMetricRow(
                    icon: "link.circle.fill",
                    title: "Active Connections",
                    value: "\(network.activeConnections)",
                    color: .green
                )

                // Network Interfaces
                ForEach(network.interfaces.filter { showInactiveNetworks || $0.isActive }) { interface in
                    NetworkInterfaceCard(interface: interface, monitor: monitor)
                }
            }
        }
    }
}

struct DiskInfoCard: View {
    let disk: DiskInfo
    let monitor: SystemMonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "externaldrive.fill")
                    .font(.title3)
                    .foregroundStyle(MetricColors.diskColor(usage: disk.usagePercentage))

                VStack(alignment: .leading, spacing: 4) {
                    Text(disk.name)
                        .font(.cardTitle)
                        .foregroundColor(.white)

                    Text("\(disk.mountPoint) • \(disk.fileSystem)")
                        .font(.metricSubtitle)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Text(String(format: "%.1f%%", disk.usagePercentage))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(MetricColors.diskColor(usage: disk.usagePercentage))
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Used")
                        .font(.metricSubtitle)
                        .foregroundColor(.white.opacity(0.7))

                    Text(monitor.formatBytes(disk.usedSpace))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Free")
                        .font(.metricSubtitle)
                        .foregroundColor(.white.opacity(0.7))

                    Text(monitor.formatBytes(disk.freeSpace))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.metricSubtitle)
                        .foregroundColor(.white.opacity(0.7))

                    Text(monitor.formatBytes(disk.totalSpace))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
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
                                colors: [
                                    MetricColors.diskColor(usage: disk.usagePercentage),
                                    MetricColors.diskColor(usage: disk.usagePercentage).opacity(0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(disk.usagePercentage / 100.0))
                }
            }
            .frame(height: 16)
        }
        .padding(20)
        .glassCard()
    }
}

struct NetworkInterfaceCard: View {
    let interface: NetworkInterface
    let monitor: SystemMonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title3)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text(interface.displayName)
                        .font(.cardTitle)
                        .foregroundColor(.white)

                    if let ip = interface.ipAddress {
                        Text("IP: \(ip)")
                            .font(.metricSubtitle)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                Circle()
                    .fill(interface.isActive ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "arrow.down")
                            .foregroundStyle(.blue)
                        Text("Received")
                            .font(.metricSubtitle)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Text(monitor.formatBytes(interface.bytesReceived))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Image(systemName: "arrow.up")
                            .foregroundStyle(.purple)
                        Text("Sent")
                            .font(.metricSubtitle)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Text(monitor.formatBytes(interface.bytesSent))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 12, opacity: 0.5)
    }
}
