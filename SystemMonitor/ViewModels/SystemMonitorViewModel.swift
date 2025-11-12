import Foundation
import Combine

@MainActor
class SystemMonitorViewModel: ObservableObject {
    // Published properties for UI
    @Published var cpuMetrics: CPUMetrics?
    @Published var gpuMetrics: GPUMetrics?
    @Published var memoryMetrics: MemoryMetrics?
    @Published var diskMetrics: DiskMetrics?
    @Published var networkMetrics: NetworkMetrics?
    @Published var processes: [AppProcess] = []

    // Historical data for charts
    @Published var cpuHistory: [Double] = []
    @Published var memoryHistory: [Double] = []
    @Published var networkDownloadHistory: [Double] = []
    @Published var networkUploadHistory: [Double] = []

    private let maxHistoryPoints = 60 // Keep 60 data points (1 minute at 1Hz)

    // Services
    private let cpuService = CPUMonitorService()
    private let gpuService = GPUMonitorService()
    private let memoryService = MemoryMonitorService()
    private let diskService = DiskMonitorService()
    private let networkService = NetworkMonitorService()
    private let processService = ProcessMonitorService()

    // Timers
    private var updateTimer: Timer?
    private var processTimer: Timer?

    // Settings
    var updateInterval: TimeInterval = 1.0 {
        didSet {
            restartTimers()
        }
    }

    init() {
        startMonitoring()
    }

    deinit {
        updateTimer?.invalidate()
        processTimer?.invalidate()
    }

    func startMonitoring() {
        // Update metrics every second
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateMetrics()
            }
        }
        updateTimer?.tolerance = 0.1

        // Update processes every 2 seconds (more expensive operation)
        processTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateProcesses()
            }
        }
        processTimer?.tolerance = 0.2

        // Immediate first update
        updateMetrics()
        updateProcesses()
    }

    func stopMonitoring() {
        updateTimer?.invalidate()
        processTimer?.invalidate()
        updateTimer = nil
        processTimer = nil
    }

    private func restartTimers() {
        stopMonitoring()
        startMonitoring()
    }

    private func updateMetrics() {
        // Update CPU
        let cpu = cpuService.getCurrentMetrics()
        cpuMetrics = cpu
        cpuHistory.append(cpu.totalUsage)
        if cpuHistory.count > maxHistoryPoints {
            cpuHistory.removeFirst()
        }

        // Update GPU
        gpuMetrics = gpuService.getCurrentMetrics()

        // Update Memory
        let memory = memoryService.getCurrentMetrics()
        memoryMetrics = memory
        memoryHistory.append(memory.usagePercentage)
        if memoryHistory.count > maxHistoryPoints {
            memoryHistory.removeFirst()
        }

        // Update Disk
        diskMetrics = diskService.getCurrentMetrics()

        // Update Network
        let network = networkService.getCurrentMetrics()
        networkMetrics = network

        let downloadSpeedMbps = Double(network.downloadSpeedBytesPerSecond) / 1_000_000.0
        let uploadSpeedMbps = Double(network.uploadSpeedBytesPerSecond) / 1_000_000.0

        networkDownloadHistory.append(downloadSpeedMbps)
        networkUploadHistory.append(uploadSpeedMbps)

        if networkDownloadHistory.count > maxHistoryPoints {
            networkDownloadHistory.removeFirst()
        }
        if networkUploadHistory.count > maxHistoryPoints {
            networkUploadHistory.removeFirst()
        }
    }

    private func updateProcesses() {
        processes = processService.getAllProcesses()
    }

    // Process management functions
    func terminateProcess(pid: Int32) -> Bool {
        return processService.terminateProcess(pid: pid)
    }

    func forceTerminateProcess(pid: Int32) -> Bool {
        return processService.forceTerminateProcess(pid: pid)
    }

    func suspendProcess(pid: Int32) -> Bool {
        return processService.suspendProcess(pid: pid)
    }

    func resumeProcess(pid: Int32) -> Bool {
        return processService.resumeProcess(pid: pid)
    }

    // Utility functions
    func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        return formatter.string(fromByteCount: Int64(bytes))
    }

    func formatBytesPerSecond(_ bytesPerSecond: UInt64) -> String {
        let mbps = Double(bytesPerSecond) / 1_000_000.0
        return String(format: "%.2f MB/s", mbps)
    }

    func formatPercentage(_ value: Double) -> String {
        return String(format: "%.1f%%", value)
    }
}
