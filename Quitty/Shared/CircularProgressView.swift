import SwiftUI

struct CircularProgressView: View {
    let progress: Double // 0.0 - 1.0
    var lineWidth: CGFloat = 10
    var size: CGFloat = 120
    var trackColor: Color = Color.secondary.opacity(0.2)
    var progressColor: Color = .blue
    var label: String = ""
    var sublabel: String = ""

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(progressColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                if !sublabel.isEmpty {
                    Text(sublabel)
                        .font(.system(size: size * 0.1, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct StorageBar: View {
    let items: [(String, Double, Color)]
    let total: Double
    var height: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 1) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    let width = total > 0 ? CGFloat(item.1 / total) * geo.size.width : 0
                    RoundedRectangle(cornerRadius: 3)
                        .fill(item.2)
                        .frame(width: max(width, 2))
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
