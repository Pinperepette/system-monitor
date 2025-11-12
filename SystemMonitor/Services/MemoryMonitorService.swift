import Foundation
import Darwin

class MemoryMonitorService {
    func getCurrentMetrics() -> MemoryMetrics {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return createEmptyMetrics()
        }

        let pageSize = UInt64(vm_kernel_page_size)

        let free = UInt64(stats.free_count) * pageSize
        let active = UInt64(stats.active_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize

        let totalPhysical = Foundation.ProcessInfo.processInfo.physicalMemory
        let used = active + wired + compressed

        let (swapUsed, swapTotal) = getSwapInfo()
        let pressure = calculateMemoryPressure(used: used, total: totalPhysical, swapUsed: swapUsed)

        return MemoryMetrics(
            timestamp: Date(),
            totalPhysical: totalPhysical,
            used: used,
            free: free,
            active: active,
            inactive: inactive,
            wired: wired,
            compressed: compressed,
            swapUsed: swapUsed,
            swapTotal: swapTotal,
            memoryPressure: pressure
        )
    }

    private func getSwapInfo() -> (used: UInt64, total: UInt64) {
        var swapUsage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size

        let result = sysctlbyname("vm.swapusage", &swapUsage, &size, nil, 0)

        guard result == 0 else {
            return (0, 0)
        }

        return (swapUsage.xsu_used, swapUsage.xsu_total)
    }

    private func calculateMemoryPressure(used: UInt64, total: UInt64, swapUsed: UInt64) -> MemoryMetrics.MemoryPressureLevel {
        let usagePercentage = Double(used) / Double(total) * 100.0

        if swapUsed > 1_073_741_824 || usagePercentage > 90 { // 1GB swap or >90% RAM
            return .critical
        } else if swapUsed > 0 || usagePercentage > 75 {
            return .warning
        } else {
            return .normal
        }
    }

    private func createEmptyMetrics() -> MemoryMetrics {
        MemoryMetrics(
            timestamp: Date(),
            totalPhysical: 0,
            used: 0,
            free: 0,
            active: 0,
            inactive: 0,
            wired: 0,
            compressed: 0,
            swapUsed: 0,
            swapTotal: 0,
            memoryPressure: .normal
        )
    }
}
