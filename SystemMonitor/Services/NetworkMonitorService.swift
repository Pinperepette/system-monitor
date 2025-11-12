import Foundation
import SystemConfiguration

class NetworkMonitorService {
    private var previousBytesReceived: UInt64 = 0
    private var previousBytesSent: UInt64 = 0
    private var lastUpdateTime: Date?

    func getCurrentMetrics() -> NetworkMetrics {
        let interfaces = getNetworkInterfaces()

        let totalReceived = interfaces.reduce(0) { $0 + $1.bytesReceived }
        let totalSent = interfaces.reduce(0) { $0 + $1.bytesSent }

        let now = Date()
        var downloadSpeed: UInt64 = 0
        var uploadSpeed: UInt64 = 0

        if let lastTime = lastUpdateTime {
            let timeInterval = now.timeIntervalSince(lastTime)
            if timeInterval > 0 {
                downloadSpeed = UInt64(Double(totalReceived - previousBytesReceived) / timeInterval)
                uploadSpeed = UInt64(Double(totalSent - previousBytesSent) / timeInterval)
            }
        }

        previousBytesReceived = totalReceived
        previousBytesSent = totalSent
        lastUpdateTime = now

        let activeConnections = getActiveConnectionsCount()

        return NetworkMetrics(
            timestamp: now,
            interfaces: interfaces,
            totalBytesReceived: totalReceived,
            totalBytesSent: totalSent,
            downloadSpeedBytesPerSecond: downloadSpeed,
            uploadSpeedBytesPerSecond: uploadSpeed,
            activeConnections: activeConnections
        )
    }

    private func getNetworkInterfaces() -> [NetworkInterface] {
        var interfaces: [NetworkInterface] = []

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return []
        }

        defer { freeifaddrs(ifaddr) }

        var interfaceStats: [String: (received: UInt64, sent: UInt64, packetsReceived: UInt64, packetsSent: UInt64)] = [:]
        var interfaceAddresses: [String: (ip: String?, mac: String?)] = [:]
        var interfaceStatus: [String: Bool] = [:]

        // First pass: collect statistics
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let name = String(cString: interface.ifa_name)

            // Skip loopback
            if name == "lo0" { continue }

            // Get interface flags
            let flags = Int32(interface.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isRunning = (flags & IFF_RUNNING) != 0
            interfaceStatus[name] = isUp && isRunning

            // Get IP address
            if let sa = interface.ifa_addr, sa.pointee.sa_family == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(sa, socklen_t(sa.pointee.sa_len),
                           &hostname, socklen_t(hostname.count),
                           nil, 0, NI_NUMERICHOST)
                let ip = String(cString: hostname)
                interfaceAddresses[name] = (ip, interfaceAddresses[name]?.mac)
            }

            // Get interface data (this would normally use getifaddrs with AF_LINK)
            if sa_family_t(interface.ifa_addr.pointee.sa_family) == AF_LINK {
                if let data = interface.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self)
                    interfaceStats[name] = (
                        received: UInt64(networkData.pointee.ifi_ibytes),
                        sent: UInt64(networkData.pointee.ifi_obytes),
                        packetsReceived: UInt64(networkData.pointee.ifi_ipackets),
                        packetsSent: UInt64(networkData.pointee.ifi_opackets)
                    )
                }
            }
        }

        // Create NetworkInterface objects
        for (name, stats) in interfaceStats {
            let addresses = interfaceAddresses[name]
            let isActive = interfaceStatus[name] ?? false

            let displayName: String
            if name.starts(with: "en") {
                displayName = "Ethernet/Wi-Fi"
            } else if name.starts(with: "awdl") {
                displayName = "Apple Wireless Direct Link"
            } else if name.starts(with: "utun") || name.starts(with: "ipsec") {
                displayName = "VPN"
            } else {
                displayName = name
            }

            let interface = NetworkInterface(
                name: name,
                displayName: displayName,
                ipAddress: addresses?.ip,
                macAddress: addresses?.mac,
                bytesReceived: stats.received,
                bytesSent: stats.sent,
                packetsReceived: stats.packetsReceived,
                packetsSent: stats.packetsSent,
                isActive: isActive
            )

            interfaces.append(interface)
        }

        return interfaces.sorted { $0.bytesReceived + $0.bytesSent > $1.bytesReceived + $1.bytesSent }
    }

    private func getActiveConnectionsCount() -> Int {
        // Temporarily disabled - Process() execution causes SIGTERM
        // TODO: Implement using BSD socket APIs instead of executing external commands
        return 0
    }
}
