# System Monitor for macOS

<div align="center">

![System Monitor Icon](./images/app-icon.png)

**A beautiful, modern system monitoring app for macOS with glassmorphism design**

[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Latest-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[Download](#-download) • [Features](#-features) • [Screenshots](#-screenshots) • [Building](#-building)

</div>

---

## 📸 Screenshots

<div align="center">

### Main Interface
![Main Interface](./Image/Screenshot%202025-11-12%20alle%2021.29.01.png)

### Process Manager
![Process Manager](./Image/Screenshot%202025-11-12%20alle%2021.29.15.png)

### CPU Monitoring
![CPU Monitor](https://raw.githubusercontent.com/Pinperepette/system-monitor/main/Image/Screenshot%202025-11-12%20alle%2021.28.32.png)

### Memory Overview
![Memory Monitor](./Image/Screenshot%202025-11-12%20alle%2021.28.50.png)

</div>

---

## ✨ Features

### Real-Time Monitoring
- **CPU**: Total and per-core usage, frequency, user/system breakdown
- **GPU**: Basic info via Metal API (name, VRAM)
- **Memory**: Physical RAM, swap, memory pressure, detailed breakdown
- **Disk**: Storage usage, I/O speeds for all volumes
- **Network**: Upload/download speeds, active interfaces, connections

### Process Management
- Complete process list with search and filtering
- Sort by CPU, memory, name, or PID
- Terminate or force quit processes
- Real-time CPU and memory usage per process

### Beautiful UI
- **Glassmorphism Design**: Modern blur effects and transparency
- **Animated Gradients**: Smooth 4-color background animation
- **Real-Time Charts**: Smooth bezier curves with 60-second history
- **Progress Rings**: Animated circular indicators
- **Dark Mode**: Optimized for macOS dark appearance
- **Collapsible Sidebar**: Clean navigation between sections

### Advanced Features
- **Free Memory**: One-click to purge inactive memory
- **Network Filter**: Toggle to show/hide inactive network interfaces
- **Color-Coded Status**: Green/Yellow/Red indicators based on usage
- **Smooth Animations**: 60fps hardware-accelerated rendering

---

## 📥 Download

### Latest Release

**[⬇️ Download System Monitor v1.0.0 (DMG)](./download/SystemMonitor.dmg)**

### System Requirements
- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac
- ~100MB RAM
- Full Disk Access permission (for process monitoring)

### Installation

1. Download the DMG file
2. Open `SystemMonitor.dmg`
3. Drag **System Monitor** to your Applications folder
4. Launch the app
5. Grant **Full Disk Access** when prompted:
   - System Preferences → Security & Privacy → Privacy → Full Disk Access
   - Add System Monitor to the list

---

## 🎨 Design

### Color Palette
- **Primary Blue**: `rgb(51, 102, 204)`
- **Primary Purple**: `rgb(102, 51, 204)`
- **Primary Pink**: `rgb(204, 51, 153)`
- **Primary Cyan**: `rgb(51, 153, 204)`

### Typography
- **SF Rounded** for all text
- Bold weights for values
- Consistent hierarchy throughout

### Components
- Glassmorphic cards with blur effects
- Animated line and bar charts
- Progress rings with gradients
- SF Symbols icons

---

## 🛠 Building from Source

### Prerequisites

- Xcode 15.0 or later
- macOS 13.0+ SDK
- Swift 5.9+

### Clone and Build

```bash
# Clone the repository
git clone https://github.com/pinperepette/system-monitor.git
cd system-monitor

# Open in Xcode
open SystemMonitor.xcodeproj

# Build and run (⌘ + R in Xcode)
```

### Configuration

1. **Disable App Sandbox**:
   - Target → Signing & Capabilities
   - Set App Sandbox to `false`

2. **Configure Entitlements**:
   - Already set in `SystemMonitor.entitlements`
   - Required for process monitoring

3. **Build Settings**:
   - Deployment Target: macOS 13.0
   - Swift Version: 5.9

---

## 📂 Project Structure

```
SystemMonitor/
├── Sources/
│   └── SystemMonitorApp.swift          # App entry point
├── Models/
│   └── SystemMetrics.swift             # Data models
├── Services/                           # System monitoring services
│   ├── CPUMonitorService.swift
│   ├── GPUMonitorService.swift
│   ├── MemoryMonitorService.swift
│   ├── DiskMonitorService.swift
│   ├── NetworkMonitorService.swift
│   └── ProcessMonitorService.swift
├── ViewModels/
│   └── SystemMonitorViewModel.swift    # Business logic
├── Views/
│   ├── MainView.swift                  # Navigation
│   ├── Components/                     # Reusable UI
│   │   ├── MetricCard.swift
│   │   └── AnimatedChart.swift
│   └── Screens/                        # Main screens
│       ├── CPUView.swift
│       ├── MemoryView.swift
│       ├── DiskNetworkView.swift
│       └── ProcessView.swift
└── Utilities/
    └── GlassmorphismStyle.swift       # Design system
```

---

## 🔧 Technical Details

### System APIs Used
- **Darwin/Mach**: `host_statistics`, `task_info`, `proc_listallpids`
- **Metal**: GPU detection and capabilities
- **SystemConfiguration**: Network interfaces
- **Foundation**: File system and process info

### Architecture
- **Pattern**: MVVM (Model-View-ViewModel)
- **Framework**: SwiftUI with Combine
- **Update Rate**: 1 second for metrics, 2 seconds for processes
- **History**: 60 data points (1 minute)

### Performance
- **CPU Usage**: ~2-5% (with all animations)
- **Memory**: ~100MB stable
- **Frame Rate**: 60fps smooth animations

---

## 🐛 Known Limitations

1. **GPU Monitoring**: Limited to Metal API info (usage % requires IOKit)
2. **Temperature**: CPU/GPU temp not available (requires SMC access)
3. **Disk I/O**: Simplified implementation (full stats need IOKit)
4. **Sandboxing**: App must run without sandbox for full functionality
5. **Permissions**: Requires Full Disk Access on recent macOS versions

---

## 🗺 Roadmap

### v1.1 (Planned)
- [ ] Menu bar widget with quick stats
- [ ] Custom alert thresholds with notifications
- [ ] Export metrics to CSV/JSON
- [ ] Settings panel for customization

### v1.2 (Future)
- [ ] IOKit integration for accurate GPU stats
- [ ] CPU/GPU temperature monitoring
- [ ] Historical data storage
- [ ] Custom themes and color schemes

### v2.0 (Long-term)
- [ ] Per-app network usage
- [ ] Battery monitoring (for MacBooks)
- [ ] Shortcuts integration
- [ ] App Store release

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Areas for Improvement

- IOKit integration for GPU/temperature/disk I/O
- Unit and UI tests
- Performance optimizations
- Accessibility improvements
- Localization

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built with **SwiftUI** and **macOS native APIs**
- Icons from **SF Symbols**
- Inspired by **iOS 15+** and **macOS Monterey+** design language
- Glassmorphism design trend

---

## 📧 Contact

**Author**: Your Name
- GitHub: [@pinperepette](https://github.com/pinperepette)

**Project Link**: [https://github.com/pinperepette/system-monitor](https://github.com/pinperepette/system-monitor)

---

<div align="center">

**Made with ❤️ using Swift and SwiftUI**

⭐ Star this repo if you find it useful!

</div>
