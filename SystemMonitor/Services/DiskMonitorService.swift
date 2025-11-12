import Foundation

class DiskMonitorService {
    private var previousReadBytes: UInt64 = 0
    private var previousWriteBytes: UInt64 = 0
    private var previousReadOps: UInt64 = 0
    private var previousWriteOps: UInt64 = 0
    private var lastUpdateTime: Date?

    func getCurrentMetrics() -> DiskMetrics {
        let disks = getDiskInfo()
        let (readBytes, writeBytes, readOps, writeOps) = getDiskActivity()

        let now = Date()
        var readBytesPerSecond: UInt64 = 0
        var writeBytesPerSecond: UInt64 = 0
        var readOpsPerSecond: UInt64 = 0
        var writeOpsPerSecond: UInt64 = 0

        if let lastTime = lastUpdateTime {
            let timeInterval = now.timeIntervalSince(lastTime)
            if timeInterval > 0 {
                readBytesPerSecond = UInt64(Double(readBytes - previousReadBytes) / timeInterval)
                writeBytesPerSecond = UInt64(Double(writeBytes - previousWriteBytes) / timeInterval)
                readOpsPerSecond = UInt64(Double(readOps - previousReadOps) / timeInterval)
                writeOpsPerSecond = UInt64(Double(writeOps - previousWriteOps) / timeInterval)
            }
        }

        previousReadBytes = readBytes
        previousWriteBytes = writeBytes
        previousReadOps = readOps
        previousWriteOps = writeOps
        lastUpdateTime = now

        return DiskMetrics(
            timestamp: now,
            disks: disks,
            readBytesPerSecond: readBytesPerSecond,
            writeBytesPerSecond: writeBytesPerSecond,
            readOperationsPerSecond: readOpsPerSecond,
            writeOperationsPerSecond: writeOpsPerSecond
        )
    }

    private func getDiskInfo() -> [DiskInfo] {
        var disks: [DiskInfo] = []

        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeIsLocalKey,
            .volumeIsRemovableKey
        ]

        guard let mountedVolumes = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else {
            return []
        }

        for volumeURL in mountedVolumes {
            guard let resourceValues = try? volumeURL.resourceValues(forKeys: Set(keys)),
                  let isLocal = resourceValues.volumeIsLocal,
                  let isRemovable = resourceValues.volumeIsRemovable,
                  isLocal && !isRemovable,
                  let totalCapacity = resourceValues.volumeTotalCapacity,
                  let availableCapacity = resourceValues.volumeAvailableCapacity else {
                continue
            }

            let name = resourceValues.volumeName ?? "Unknown"
            let totalSpace = UInt64(totalCapacity)
            let freeSpace = UInt64(availableCapacity)
            let usedSpace = totalSpace - freeSpace

            // Get filesystem type
            let fileSystem = getFileSystemType(for: volumeURL.path)

            let diskInfo = DiskInfo(
                name: name,
                mountPoint: volumeURL.path,
                totalSpace: totalSpace,
                usedSpace: usedSpace,
                freeSpace: freeSpace,
                fileSystem: fileSystem
            )

            disks.append(diskInfo)
        }

        return disks
    }

    private func getFileSystemType(for path: String) -> String {
        var stat = statfs()
        let result = statfs(path, &stat)

        guard result == 0 else {
            return "Unknown"
        }

        return withUnsafeBytes(of: stat.f_fstypename) { buffer in
            let ptr = buffer.baseAddress?.assumingMemoryBound(to: CChar.self)
            return ptr.flatMap { String(cString: $0) } ?? "Unknown"
        }
    }

    private func getDiskActivity() -> (readBytes: UInt64, writeBytes: UInt64, readOps: UInt64, writeOps: UInt64) {
        // This is a simplified version. Real implementation would use IOKit
        // to read disk statistics from IOBlockStorageDriver

        // For demonstration, we'll use a basic approach
        // In production, you'd want to use IOServiceGetMatchingServices with IOKit

        let readBytes: UInt64 = 0
        let writeBytes: UInt64 = 0
        let readOps: UInt64 = 0
        let writeOps: UInt64 = 0

        // Placeholder for IOKit implementation
        // Real implementation would iterate through IOBlockStorageDriver services
        // and sum up their statistics

        return (readBytes, writeBytes, readOps, writeOps)
    }
}
