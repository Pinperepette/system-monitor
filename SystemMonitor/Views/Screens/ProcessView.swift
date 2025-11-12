import SwiftUI

struct ProcessView: View {
    @EnvironmentObject var monitor: SystemMonitorViewModel
    @State private var searchText = ""
    @State private var sortBy: SortOption = .cpu
    @State private var selectedProcess: AppProcess?
    @State private var showingKillAlert = false
    @State private var showingForceKillAlert = false

    enum SortOption: String, CaseIterable {
        case cpu = "CPU"
        case memory = "Memory"
        case name = "Name"
        case pid = "PID"
    }

    var filteredProcesses: [AppProcess] {
        let filtered = searchText.isEmpty ? monitor.processes :
            monitor.processes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        return filtered.sorted { lhs, rhs in
            switch sortBy {
            case .cpu:
                return lhs.cpuUsage > rhs.cpuUsage
            case .memory:
                return lhs.memoryUsage > rhs.memoryUsage
            case .name:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .pid:
                return lhs.pid < rhs.pid
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with search and sort
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "gearshape.2.fill")
                        .font(.title)
                        .foregroundStyle(.orange)

                    Text("Processes")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(filteredProcesses.count) processes")
                        .font(.metricSubtitle)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.leading, 60)

                HStack(spacing: 12) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.5))

                        TextField("Search processes...", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .opacity(0.5)
                    )

                    // Sort picker
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortBy = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if sortBy == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(sortBy.rawValue)
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.ultraThinMaterial)
                                .opacity(0.5)
                        )
                    }
                }
            }
            .padding(20)

            // Process list header
            HStack {
                Text("Process")
                    .frame(width: 200, alignment: .leading)

                Text("PID")
                    .frame(width: 80, alignment: .center)

                Text("CPU")
                    .frame(width: 100, alignment: .trailing)

                Text("Memory")
                    .frame(width: 120, alignment: .trailing)

                Text("Threads")
                    .frame(width: 80, alignment: .trailing)

                Spacer()
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))

            // Process list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredProcesses) { process in
                        ProcessRow(
                            process: process,
                            monitor: monitor,
                            isSelected: selectedProcess?.pid == process.pid
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedProcess = process
                        }
                        .contextMenu {
                            Button {
                                selectedProcess = process
                                showingKillAlert = true
                            } label: {
                                Label("Terminate", systemImage: "xmark.circle")
                            }

                            Button(role: .destructive) {
                                selectedProcess = process
                                showingForceKillAlert = true
                            } label: {
                                Label("Force Quit", systemImage: "exclamationmark.triangle")
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .alert("Terminate Process?", isPresented: $showingKillAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Terminate", role: .destructive) {
                if let process = selectedProcess {
                    _ = monitor.terminateProcess(pid: process.pid)
                }
            }
        } message: {
            if let process = selectedProcess {
                Text("Are you sure you want to terminate \(process.name) (PID: \(process.pid))?")
            }
        }
        .alert("Force Quit Process?", isPresented: $showingForceKillAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Force Quit", role: .destructive) {
                if let process = selectedProcess {
                    _ = monitor.forceTerminateProcess(pid: process.pid)
                }
            }
        } message: {
            if let process = selectedProcess {
                Text("Force quitting \(process.name) (PID: \(process.pid)) may cause data loss. This action cannot be undone.")
            }
        }
    }
}

struct ProcessRow: View {
    let process: AppProcess
    let monitor: SystemMonitorViewModel
    let isSelected: Bool

    var body: some View {
        HStack {
            // Process name with icon
            HStack(spacing: 8) {
                if let iconName = process.icon {
                    Image(systemName: iconName)
                        .foregroundStyle(.cyan)
                        .frame(width: 20)
                }

                Text(process.name)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(width: 200, alignment: .leading)

            // PID
            Text("\(process.pid)")
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 80, alignment: .center)

            // CPU usage
            HStack(spacing: 4) {
                Text(String(format: "%.1f%%", process.cpuUsage))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(MetricColors.cpuColor(usage: process.cpuUsage))

                // CPU usage bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))

                        RoundedRectangle(cornerRadius: 2)
                            .fill(MetricColors.cpuColor(usage: process.cpuUsage))
                            .frame(width: geometry.size.width * CGFloat(min(process.cpuUsage / 100.0, 1.0)))
                    }
                }
                .frame(height: 4)
            }
            .frame(width: 100, alignment: .trailing)

            // Memory usage
            Text(monitor.formatBytes(process.memoryUsage))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 120, alignment: .trailing)

            // Thread count
            Text("\(process.threadCount)")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 80, alignment: .trailing)

            Spacer()

            // Action button
            Button {
                // Quick terminate action
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red.opacity(0.8))
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .opacity(isSelected ? 1.0 : 0.3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}
