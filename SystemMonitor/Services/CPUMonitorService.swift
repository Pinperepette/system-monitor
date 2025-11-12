import Foundation
import Darwin

class CPUMonitorService {
    private var previousCPUInfo: host_cpu_load_info?

    func getCurrentMetrics() -> CPUMetrics {
        let coreCount = Foundation.ProcessInfo.processInfo.processorCount
        let usage = getCPUUsage()
        let perCoreUsage = getPerCoreUsage()
        let temperature = getCPUTemperature()
        let frequency = getCPUFrequency()

        return CPUMetrics(
            timestamp: Date(),
            totalUsage: usage.total,
            userUsage: usage.user,
            systemUsage: usage.system,
            idleUsage: usage.idle,
            coreCount: coreCount,
            perCoreUsage: perCoreUsage,
            temperature: temperature,
            frequency: frequency
        )
    }

    private func getCPUUsage() -> (total: Double, user: Double, system: Double, idle: Double) {
        var cpuInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return (0, 0, 0, 0)
        }

        let userTicks = Double(cpuInfo.cpu_ticks.0)
        let systemTicks = Double(cpuInfo.cpu_ticks.1)
        let idleTicks = Double(cpuInfo.cpu_ticks.2)
        let niceTicks = Double(cpuInfo.cpu_ticks.3)

        if let previous = previousCPUInfo {
            let userDelta = userTicks - Double(previous.cpu_ticks.0)
            let systemDelta = systemTicks - Double(previous.cpu_ticks.1)
            let idleDelta = idleTicks - Double(previous.cpu_ticks.2)
            let niceDelta = niceTicks - Double(previous.cpu_ticks.3)

            let totalDelta = userDelta + systemDelta + idleDelta + niceDelta

            if totalDelta > 0 {
                let user = (userDelta + niceDelta) / totalDelta * 100.0
                let system = systemDelta / totalDelta * 100.0
                let idle = idleDelta / totalDelta * 100.0
                let total = user + system

                previousCPUInfo = cpuInfo
                return (total, user, system, idle)
            }
        }

        previousCPUInfo = cpuInfo
        return (0, 0, 0, 100)
    }

    private func getPerCoreUsage() -> [Double] {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t!
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(mach_host_self(),
                                        PROCESSOR_CPU_LOAD_INFO,
                                        &numCPUs,
                                        &cpuInfo,
                                        &numCPUInfo)

        guard result == KERN_SUCCESS else {
            return []
        }

        var coreUsages: [Double] = []

        for i in 0..<Int(numCPUs) {
            let cpuLoadInfo = cpuInfo.advanced(by: Int(CPU_STATE_MAX) * i)
            let user = Double(cpuLoadInfo[Int(CPU_STATE_USER)])
            let system = Double(cpuLoadInfo[Int(CPU_STATE_SYSTEM)])
            let idle = Double(cpuLoadInfo[Int(CPU_STATE_IDLE)])
            let nice = Double(cpuLoadInfo[Int(CPU_STATE_NICE)])

            let total = user + system + idle + nice
            if total > 0 {
                let usage = (user + system + nice) / total * 100.0
                coreUsages.append(usage)
            } else {
                coreUsages.append(0)
            }
        }

        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(numCPUInfo))

        return coreUsages
    }

    // Note: Temperature reading requires IOKit and SMC access
    // This is a placeholder that returns a simulated value
    private func getCPUTemperature() -> Double? {
        // In a real implementation, you would use IOKit to read from SMC
        // For now, return a simulated temperature
        return nil
    }

    private func getCPUFrequency() -> Double? {
        var freq: UInt64 = 0
        var size = MemoryLayout<UInt64>.size

        let result = sysctlbyname("hw.cpufrequency", &freq, &size, nil, 0)

        guard result == 0 else { return nil }

        return Double(freq) / 1_000_000_000.0 // Convert to GHz
    }
}
