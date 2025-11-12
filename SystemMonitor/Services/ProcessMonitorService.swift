import Foundation
import AppKit
import Darwin

class ProcessMonitorService {
    func getAllProcesses() -> [AppProcess] {
        var processes: [AppProcess] = []

        var count: Int32 = 0
        var result = proc_listallpids(nil, 0)
        count = result

        guard count > 0 else { return [] }

        var pids = [Int32](repeating: 0, count: Int(count))
        result = proc_listallpids(&pids, Int32(MemoryLayout<Int32>.size * Int(count)))

        guard result > 0 else { return [] }

        for pid in pids where pid > 0 {
            if let processInfo = getProcessInfo(pid: pid) {
                processes.append(processInfo)
            }
        }

        return processes.sorted { $0.cpuUsage > $1.cpuUsage }
    }

    func getProcessInfo(pid: Int32) -> AppProcess? {
        let maxPathSize = 4096 // PROC_PIDPATHINFO_MAXSIZE equivalent
        var pathBuffer = [CChar](repeating: 0, count: maxPathSize)
        let pathLength = proc_pidpath(pid, &pathBuffer, UInt32(maxPathSize))

        guard pathLength > 0 else { return nil }

        let path = String(cString: pathBuffer)
        let name = (path as NSString).lastPathComponent

        let cpuUsage = getProcessCPUUsage(pid: pid)
        let memoryUsage = getProcessMemoryUsage(pid: pid)
        let threadCount = getProcessThreadCount(pid: pid)

        // Try to get app icon
        let icon = getAppIcon(for: path)

        return AppProcess(
            pid: pid,
            name: name,
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            threadCount: threadCount,
            icon: icon
        )
    }

    private func getProcessCPUUsage(pid: Int32) -> Double {
        var taskInfo = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size / MemoryLayout<integer_t>.size)

        var taskPort: mach_port_t = 0
        let kr = task_for_pid(mach_task_self_, pid, &taskPort)

        guard kr == KERN_SUCCESS else { return 0.0 }

        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(taskPort, task_flavor_t(TASK_BASIC_INFO), $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0.0 }

        // Get thread information for CPU usage
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        guard task_threads(taskPort, &threadList, &threadCount) == KERN_SUCCESS,
              let threads = threadList else {
            return 0.0
        }

        defer {
            vm_deallocate(mach_task_self_,
                         vm_address_t(bitPattern: threads),
                         vm_size_t(threadCount * UInt32(MemoryLayout<thread_t>.size)))
        }

        var totalCPUUsage = 0.0

        for i in 0..<Int(threadCount) {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

            let kr = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(threadInfoCount)) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                }
            }

            if kr == KERN_SUCCESS {
                if threadInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalCPUUsage += Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
                }
            }
        }

        return totalCPUUsage
    }

    private func getProcessMemoryUsage(pid: Int32) -> UInt64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)

        var taskPort: mach_port_t = 0
        let kr = task_for_pid(mach_task_self_, pid, &taskPort)

        guard kr == KERN_SUCCESS else { return 0 }

        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(taskPort, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        return taskInfo.resident_size
    }

    private func getProcessThreadCount(pid: Int32) -> Int {
        var taskPort: mach_port_t = 0
        let kr = task_for_pid(mach_task_self_, pid, &taskPort)

        guard kr == KERN_SUCCESS else { return 0 }

        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0

        guard task_threads(taskPort, &threadList, &threadCount) == KERN_SUCCESS else {
            return 0
        }

        if let threads = threadList {
            vm_deallocate(mach_task_self_,
                         vm_address_t(bitPattern: threads),
                         vm_size_t(threadCount * UInt32(MemoryLayout<thread_t>.size)))
        }

        return Int(threadCount)
    }

    private func getAppIcon(for path: String) -> String? {
        let workspace = NSWorkspace.shared
        let icon = workspace.icon(forFile: path)

        // For simplicity, return SF Symbol names based on app type
        // In a real app, you'd cache and use actual NSImage
        if path.contains(".app") {
            return "app.fill"
        } else if path.contains("MacOS") || path.contains("bin") {
            return "terminal.fill"
        } else {
            return "gear"
        }
    }

    func terminateProcess(pid: Int32) -> Bool {
        let result = kill(pid, SIGTERM)
        return result == 0
    }

    func forceTerminateProcess(pid: Int32) -> Bool {
        let result = kill(pid, SIGKILL)
        return result == 0
    }

    func suspendProcess(pid: Int32) -> Bool {
        let result = kill(pid, SIGSTOP)
        return result == 0
    }

    func resumeProcess(pid: Int32) -> Bool {
        let result = kill(pid, SIGCONT)
        return result == 0
    }
}
