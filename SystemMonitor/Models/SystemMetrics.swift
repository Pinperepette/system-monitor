import Foundation

// MARK: - CPU Metrics
struct CPUMetrics: Identifiable {
    let id = UUID()
    let timestamp: Date
    let totalUsage: Double // 0-100
    let userUsage: Double
    let systemUsage: Double
    let idleUsage: Double
    let coreCount: Int
    let perCoreUsage: [Double]
    let temperature: Double? // Celsius
    let frequency: Double? // GHz
}

// MARK: - GPU Metrics
struct GPUMetrics: Identifiable {
    let id = UUID()
    let timestamp: Date
    let usage: Double // 0-100
    let temperature: Double? // Celsius
    let memoryUsed: UInt64 // Bytes
    let memoryTotal: UInt64 // Bytes
}

// MARK: - Memory Metrics
struct MemoryMetrics: Identifiable {
    let id = UUID()
    let timestamp: Date
    let totalPhysical: UInt64 // Bytes
    let used: UInt64
    let free: UInt64
    let active: UInt64
    let inactive: UInt64
    let wired: UInt64
    let compressed: UInt64
    let swapUsed: UInt64
    let swapTotal: UInt64
    let memoryPressure: MemoryPressureLevel

    var usagePercentage: Double {
        Double(used) / Double(totalPhysical) * 100.0
    }

    enum MemoryPressureLevel {
        case normal, warning, critical

        var color: String {
            switch self {
            case .normal: return "green"
            case .warning: return "yellow"
            case .critical: return "red"
            }
        }
    }
}

// MARK: - Disk Metrics
struct DiskMetrics: Identifiable {
    let id = UUID()
    let timestamp: Date
    let disks: [DiskInfo]
    let readBytesPerSecond: UInt64
    let writeBytesPerSecond: UInt64
    let readOperationsPerSecond: UInt64
    let writeOperationsPerSecond: UInt64
}

struct DiskInfo: Identifiable {
    let id = UUID()
    let name: String
    let mountPoint: String
    let totalSpace: UInt64 // Bytes
    let usedSpace: UInt64
    let freeSpace: UInt64
    let fileSystem: String

    var usagePercentage: Double {
        Double(usedSpace) / Double(totalSpace) * 100.0
    }
}

// MARK: - Network Metrics
struct NetworkMetrics: Identifiable {
    let id = UUID()
    let timestamp: Date
    let interfaces: [NetworkInterface]
    let totalBytesReceived: UInt64
    let totalBytesSent: UInt64
    let downloadSpeedBytesPerSecond: UInt64
    let uploadSpeedBytesPerSecond: UInt64
    let activeConnections: Int
}

struct NetworkInterface: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    let ipAddress: String?
    let macAddress: String?
    let bytesReceived: UInt64
    let bytesSent: UInt64
    let packetsReceived: UInt64
    let packetsSent: UInt64
    let isActive: Bool
}

// MARK: - Process Info
struct AppProcess: Identifiable {
    let id = UUID()
    let pid: Int32
    let name: String
    let cpuUsage: Double
    let memoryUsage: UInt64 // Bytes
    let threadCount: Int
    let icon: String?
}
