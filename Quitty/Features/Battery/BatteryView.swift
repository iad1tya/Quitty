import SwiftUI
import Combine

struct BatteryView: View {
    @ObservedObject var manager: BatteryManager
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Text("Battery Monitor")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            if !manager.hasBattery {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "bolt.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No battery detected")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text("This Mac is running on AC power only")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                Spacer()
            } else {
                // Battery gauge
                CircularProgressView(
                    progress: Double(manager.chargePercent) / 100.0,
                    lineWidth: 12,
                    size: 130,
                    progressColor: batteryColor,
                    label: "\(manager.chargePercent)%",
                    sublabel: manager.isCharging ? "Charging" : (manager.isPluggedIn ? "Plugged In" : "Battery")
                )

                if !manager.timeRemaining.isEmpty {
                    Text(manager.timeRemaining)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // Details
                VStack(spacing: 8) {
                    BatteryInfoRow(icon: "heart.fill", label: "Health", value: "\(manager.health)%",
                                   color: manager.health >= 80 ? .green : (manager.health >= 50 ? .orange : .red))
                    BatteryInfoRow(icon: "arrow.triangle.2.circlepath", label: "Cycle Count", value: "\(manager.cycleCount)", color: .blue)
                    if manager.temperature > 0 {
                        BatteryInfoRow(icon: "thermometer.medium", label: "Temperature", value: String(format: "%.1f°C", manager.temperature), color: .orange)
                    }
                    BatteryInfoRow(icon: "bolt.fill", label: "Power Source",
                                   value: manager.isPluggedIn ? "AC Power" : "Battery", color: .purple)
                    if manager.designCapacity > 0 {
                        BatteryInfoRow(icon: "battery.100", label: "Design Capacity", value: "\(manager.designCapacity) mAh", color: .secondary)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
        }
        .onReceive(timer) { _ in
            manager.refresh()
        }
    }

    var batteryColor: Color {
        if manager.isCharging { return .green }
        if manager.chargePercent > 50 { return .green }
        if manager.chargePercent > 20 { return .orange }
        return .red
    }
}

struct BatteryInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}
