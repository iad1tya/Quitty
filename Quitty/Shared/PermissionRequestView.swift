import SwiftUI

struct PermissionRequestView: View {
    let icon: String
    let title: String
    let message: String
    let onGrant: () -> Void
    let onCheck: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text(title)
                .font(.system(size: 14, weight: .semibold))

            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            Button(action: onGrant) {
                Text("Open System Settings")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)

            Button(action: onCheck) {
                Text("I've granted access")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
        }
    }
}
