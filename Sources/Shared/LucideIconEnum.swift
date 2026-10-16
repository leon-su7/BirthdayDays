import SwiftUI

/// Lucide 官方图标的原生矢量版本，路径与 24 点视框保持一致。
/// 来源：https://github.com/lucide-icons/lucide，许可见 THIRD_PARTY_NOTICES.md。
enum LucideIconEnum {
    case calendarDays
    case check
    case arrowUpRight
}

/// 以 SwiftUI 路径呈现 Lucide 图标，避免引入字体或表情符号。
struct LucideIcon: View {
    let icon: LucideIconEnum
    var size: CGFloat = 18

    var body: some View {
        LucideIconShape(icon: icon)
            .stroke(style: StrokeStyle(lineWidth: size / 12, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// 将 Lucide 源路径缩放到目标视图；不改变图标的几何比例。
private struct LucideIconShape: Shape {
    let icon: LucideIconEnum

    /// 构建图标路径，所有坐标采用官方 SVG 的 24 × 24 视框。
    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch icon {
        case .calendarDays:
            path.addRoundedRect(in: CGRect(x: 3, y: 3, width: 18, height: 18), cornerSize: CGSize(width: 2, height: 2))
            for x in [8.0, 16.0] {
                path.move(to: CGPoint(x: x, y: 2))
                path.addLine(to: CGPoint(x: x, y: 5))
            }
            path.move(to: CGPoint(x: 3, y: 9))
            path.addLine(to: CGPoint(x: 21, y: 9))
            for y in [13.0, 17.0] {
                for x in [8.0, 12.0, 16.0] {
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x + 0.01, y: y))
                }
            }
        case .check:
            path.move(to: CGPoint(x: 20, y: 6))
            path.addLine(to: CGPoint(x: 9, y: 17))
            path.addLine(to: CGPoint(x: 4, y: 12))
        case .arrowUpRight:
            path.move(to: CGPoint(x: 7, y: 7))
            path.addLine(to: CGPoint(x: 17, y: 7))
            path.addLine(to: CGPoint(x: 17, y: 17))
            path.move(to: CGPoint(x: 7, y: 17))
            path.addLine(to: CGPoint(x: 17, y: 7))
        }
        return path.applying(CGAffineTransform(scaleX: rect.width / 24, y: rect.height / 24))
    }
}
