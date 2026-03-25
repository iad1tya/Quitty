import SwiftUI
import Combine

struct RAMBoosterView: View {
    @ObservedObject var manager: RAMBoosterManager
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Text("RAM Booster")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            CircularProgressView(
                progress: manager.usagePercent,
                lineWidth: 12,
                size: 140,
                progressColor: progressColor,
                label: "\(Int(manager.usagePercent * 100))%",
                sublabel: "Used"
            )
            .padding(.top, 8)

            // RAM breakdown
            VStack(spacing: 8) {
                RAMInfoRow(label: "Total", value: RAMBoosterManager.formatBytes(manager.totalRAM), color: .primary)
                RAMInfoRow(label: "Used", value: RAMBoosterManager.formatBytes(manager.usedRAM), color: .red)
                RAMInfoRow(label: "Free", value: RAMBoosterManager.formatBytes(manager.freeRAM), color: .green)
                Divider()
                RAMInfoRow(label: "Active", value: RAMBoosterManager.formatBytes(manager.activeRAM), color: .orange)
                RAMInfoRow(label: "Wired", value: RAMBoosterManager.formatBytes(manager.wiredRAM), color: .purple)
                RAMInfoRow(label: "Compressed", value: RAMBoosterManager.formatBytes(manager.compressedRAM), color: .blue)
            }
            .padding(.horizontal, 16)

            Spacer()

            Button(action: { manager.freeRAMAction() }) {
                HStack {
                    if manager.isFreeing {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                    }
                    Text(manager.isFreeing ? "Freeing RAM..." : "Free RAM")
                        .font(.system(size: 13, weight: .medium))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .controlSize(.large)
            .disabled(manager.isFreeing)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .onReceive(timer) { _ in
            manager.refresh()
        }
    }

    var progressColor: Color {
        if manager.usagePercent < 0.6 { return .green }
        if manager.usagePercent < 0.8 { return .orange }
        return .red
    }
}

struct RAMInfoRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
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
