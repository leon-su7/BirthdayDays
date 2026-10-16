import SwiftUI

/// 以六十个刻度表达从本次生日到下次生日的年度旅程，不代表预期寿命。
struct BirthdayDial: View {
    /// 本年度已走过的比例。
    let progress: Double
    /// 刻度环中央的数值与说明。
    let value: String
    let caption: String
    /// 小尺寸小组件使用更紧凑的字号。
    var compact = false

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                BirthdayTickShape(progress: 1)
                    .stroke(BirthdayDesignEnum.muted.opacity(0.36), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                BirthdayTickShape(progress: progress)
                    .stroke(BirthdayDesignEnum.accent, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                Circle()
                    .stroke(BirthdayDesignEnum.line, lineWidth: 1)
                    .padding(side * 0.155)
                Circle()
                    .trim(from: 0, to: min(1, max(0.002, progress)))
                    .stroke(BirthdayDesignEnum.accent.opacity(0.85), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(side * 0.155)
                Circle()
                    .fill(BirthdayDesignEnum.accent)
                    .frame(width: compact ? 4 : 6, height: compact ? 4 : 6)
                    .offset(y: -side * 0.345)
                    .rotationEffect(.degrees(progress * 360))
                VStack(spacing: compact ? 3 : 5) {
                    Text(value)
                        .font(.system(size: side * (compact ? 0.23 : 0.25), weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(BirthdayDesignEnum.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(LocalizedStringKey(caption))
                        .font(.system(size: compact ? 9 : 11, weight: .medium))
                        .foregroundStyle(BirthdayDesignEnum.secondary)
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(BirthdayLocalizationEnum.format("年度刻度说明", value,
            BirthdayLocalizationEnum.text(caption), String(Int(progress * 100))))
    }
}

/// 在圆周绘制等距刻度，每五格加长一次，以路径绘制兼容 WidgetKit 的静态渲染。
private struct BirthdayTickShape: Shape {
    let progress: Double

    /// 只生成已完成范围内的刻度，未完成部分由底层完整刻度承担。
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 3
        for index in 0..<60 where Double(index) / 60 < progress {
            let angle = Double(index) / 60 * .pi * 2 - .pi / 2
            let length = radius * (index.isMultiple(of: 5) ? 0.16 : 0.085)
            path.move(to: CGPoint(x: center.x + cos(angle) * (radius - length), y: center.y + sin(angle) * (radius - length)))
            path.addLine(to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
        }
        return path
    }
}
