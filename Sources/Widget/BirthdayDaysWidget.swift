import WidgetKit
import SwiftUI

/// 小组件时间线中的一个数据快照。
struct BirthdayEntry: TimelineEntry {
    /// 快照生成时间。
    let date: Date
    /// 共享存储中的生日；为 nil 时展示引导文案。
    let birthday: Date?
    /// 与生日一起读取的寿命及倒计时显示偏好。
    let lifePlan: BirthdayLifePlan
}

/// 为小组件准备每日更新的时间线数据。
struct BirthdayProvider: TimelineProvider {
    /// 提供占位视图所需的数据。
    func placeholder(in context: Context) -> BirthdayEntry {
        BirthdayEntry(date: .now, birthday: nil, lifePlan: BirthdayLifePlan())
    }

    /// 提供小组件菜单预览的数据。
    func getSnapshot(in context: Context, completion: @escaping (BirthdayEntry) -> Void) {
        let record = BirthdayStore.readSharedRecord()
        completion(BirthdayEntry(date: .now, birthday: record.birthday, lifePlan: record.lifePlan))
    }

    /// 生成当天与次日零点两个快照，让自然天数跨天后自动更新。
    func getTimeline(in context: Context, completion: @escaping (Timeline<BirthdayEntry>) -> Void) {
        let currentDate = Date.now
        let record = BirthdayStore.readSharedRecord()
        let currentEntry = BirthdayEntry(date: currentDate, birthday: record.birthday, lifePlan: record.lifePlan)
        // 自然日不总是 24 小时，按日历求下一天零点以适配夏令时。
        let nextMidnight = Calendar.current.date(byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: currentDate)) ?? currentDate.addingTimeInterval(86_400)
        let nextEntry = BirthdayEntry(date: nextMidnight, birthday: record.birthday, lifePlan: record.lifePlan)
        completion(Timeline(entries: [currentEntry, nextEntry], policy: .atEnd))
    }
}

/// 读取系统提供的尺寸类别，并应用一致的深色容器背景。
struct BirthdayWidgetView: View {
    let entry: BirthdayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        BirthdayWidgetContent(date: entry.date, birthday: entry.birthday, family: family, lifePlan: entry.lifePlan)
            .containerBackground(for: .widget) {
                LinearGradient(colors: [BirthdayDesignEnum.surface, BirthdayDesignEnum.background], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
    }
}

/// 小、中、大尺寸分别编排内容，避免将主界面的长句直接缩放到小组件中。
struct BirthdayWidgetContent: View {
    let date: Date
    let birthday: Date?
    let family: WidgetFamily
    let lifePlan: BirthdayLifePlan

    /// 所有尺寸使用与主应用相同的自然日和生日周期算法。
    private var metrics: BirthdayMetrics? {
        birthday.flatMap { BirthdayMetrics(birthday: $0, on: date, expectedLifespanYears: lifePlan.expectedLifespanYears) }
    }

    var body: some View {
        Group {
            if let metrics {
                switch family {
                case .systemMedium: mediumContent(metrics)
                case .systemLarge: largeContent(metrics)
                default: smallContent(metrics)
                }
            } else {
                emptyContent
            }
        }
        .padding(family == .systemSmall ? 16 : 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 各尺寸共用的品牌标题，色点只作为时间记录的视觉标记。
    private var title: some View {
        HStack(spacing: 6) {
            Circle().fill(BirthdayDesignEnum.accent).frame(width: 4, height: 4)
            Text("诞生记录").font(.system(size: 10, weight: .medium)).tracking(1)
                .foregroundStyle(BirthdayDesignEnum.secondary)
        }
    }

    /// 统一采用字符串绘制整数，任何区域设置下都不添加千分位。
    private func dayCount(_ days: Int, size: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(String(days))
                .font(.system(size: size, weight: .light, design: .rounded))
                .tracking(-1.5).monospacedDigit()
                .foregroundStyle(BirthdayDesignEnum.text)
                .lineLimit(1).minimumScaleFactor(0.5)
                .layoutPriority(1)
            Text(BirthdayLocalizationEnum.dayUnit(days)).font(.system(size: 11)).foregroundStyle(BirthdayDesignEnum.accent)
                .fixedSize().layoutPriority(2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(BirthdayLocalizationEnum.format("已经诞生%@", BirthdayLocalizationEnum.days(days)))
    }

    /// 将结束倒计时压缩为单行，三种尺寸均受同一个保存开关控制。
    private func lifeCountdown(_ metrics: BirthdayMetrics, compact: Bool = true) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("结束倒计时")
                .font(.system(size: compact ? 9 : 10)).foregroundStyle(BirthdayDesignEnum.secondary)
                .fixedSize()
            Spacer(minLength: 0)
            Text(BirthdayLocalizationEnum.days(metrics.daysRemaining))
                .font(.system(size: compact ? 10 : 16, weight: .medium, design: .rounded)).monospacedDigit()
                .foregroundStyle(BirthdayDesignEnum.accent)
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(BirthdayLocalizationEnum.format("预计%@岁，剩余%@", String(lifePlan.expectedLifespanYears), BirthdayLocalizationEnum.days(metrics.daysRemaining)))
    }

    /// 小尺寸以天数为主体，底部横向刻度展示本年度进度。
    private func smallContent(_ metrics: BirthdayMetrics) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            Spacer(minLength: 8)
            Text(LocalizedStringKey(metrics.isBirthday ? "今天，是你的生日" : "与世界相遇，已经"))
                .font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.secondary)
            dayCount(metrics.daysAlive, size: 39).padding(.top, 5)
            Spacer(minLength: 10)
            BirthdayYearLine(progress: metrics.yearProgress).frame(height: 8)
            // 小尺寸复用底部摘要的位置，开启倒计时时仍为天数与刻度留出空间。
            if lifePlan.showsCountdown {
                lifeCountdown(metrics).padding(.top, 9)
            } else {
                HStack {
                    Text("\(String(metrics.age)) 岁")
                    Spacer()
                    Text(metrics.isBirthday ? BirthdayLocalizationEnum.text("生日快乐") : BirthdayLocalizationEnum.format("这一岁的第%@天", String(metrics.daysSinceBirthday)))
                }
                .font(.system(size: 9)).foregroundStyle(BirthdayDesignEnum.secondary).padding(.top, 9)
            }
        }
    }

    /// 中尺寸左右分区，天数与生日周期环同屏显示。
    private func mediumContent(_ metrics: BirthdayMetrics) -> some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 0) {
                title
                Spacer(minLength: 8)
                Text("与世界相遇，已经").font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.secondary)
                dayCount(metrics.daysAlive, size: 44).padding(.top, 5)
                Spacer(minLength: 8)
                if lifePlan.showsCountdown {
                    lifeCountdown(metrics)
                } else {
                    Text(BirthdayLocalizationEnum.duration(years: metrics.age, days: metrics.daysSinceBirthday))
                        .font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 9) {
                BirthdayDial(progress: metrics.yearProgress, value: String(metrics.age), caption: "周岁", compact: true)
                    .frame(width: 100, height: 100)
                Text(metrics.isBirthday ? BirthdayLocalizationEnum.text("今天生日，生日快乐") : BirthdayLocalizationEnum.format("距生日%@", BirthdayLocalizationEnum.days(metrics.daysUntilBirthday)))
                    .font(.system(size: 9)).foregroundStyle(BirthdayDesignEnum.accent)
            }
        }
    }

    /// 大尺寸保留舒展的数字版式，并补充生日日期与下一岁信息。
    private func largeContent(_ metrics: BirthdayMetrics) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                title
                Spacer()
                Text(BirthdayDesignEnum.monthDay(date)).font(.system(size: 9)).foregroundStyle(BirthdayDesignEnum.muted)
            }
            Spacer(minLength: 14)
            VStack(alignment: .leading, spacing: 7) {
                Text("与世界相遇，已经").font(.system(size: 11)).foregroundStyle(BirthdayDesignEnum.secondary)
                dayCount(metrics.daysAlive, size: 64)
                Text(BirthdayLocalizationEnum.duration(years: metrics.age, days: metrics.daysSinceBirthday))
                    .font(.system(size: 11)).foregroundStyle(BirthdayDesignEnum.secondary)
            }
            Spacer(minLength: 16)
            Rectangle().fill(BirthdayDesignEnum.line).frame(height: 1)
            HStack(spacing: 24) {
                BirthdayDial(progress: metrics.yearProgress, value: String(metrics.age), caption: "周岁")
                    .frame(width: 126, height: 126)
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey(metrics.isBirthday ? "生日快乐" : "距离下次生日"))
                        .font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(String(metrics.daysUntilBirthday))
                            .font(.system(size: 32, weight: .light, design: .rounded)).monospacedDigit()
                            .foregroundStyle(BirthdayDesignEnum.accent)
                        Text(BirthdayLocalizationEnum.dayUnit(metrics.daysUntilBirthday)).font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.secondary)
                    }
                    Text("\(BirthdayDesignEnum.monthDay(metrics.nextBirthday)) · \(String(metrics.nextAge)) 岁")
                        .font(.system(size: 9)).foregroundStyle(BirthdayDesignEnum.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 15)
            Spacer(minLength: 8)
            if lifePlan.showsCountdown {
                lifeCountdown(metrics, compact: false)
            } else {
                HStack {
                    Text("每一天，都算数。")
                    Spacer()
                    Text("始于 \(BirthdayDesignEnum.dateLabel(metrics.birthday))")
                }
                .font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.muted)
            }
        }
    }

    /// 未设置和未来生日使用同一套留白版式，不显示负天数或不真实的记录。
    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            Spacer(minLength: 10)
            Text(LocalizedStringKey(birthday == nil ? "时间，始于你。" : "等待那一天。"))
                .font(.system(size: family == .systemSmall ? 19 : 24, weight: .light))
                .foregroundStyle(BirthdayDesignEnum.text)
            Text(LocalizedStringKey(birthday == nil ? "打开应用，记录生日" : "你的故事，即将开始"))
                .font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.secondary).padding(.top, 9)
            Spacer(minLength: 14)
            BirthdayYearLine(progress: 0).frame(height: 8)
            Text("每一天，都算数。")
                .font(.system(size: 9)).foregroundStyle(BirthdayDesignEnum.muted).padding(.top, 10)
        }
    }
}

/// 小尺寸的年度刻度条，每五个刻度加长，亮色范围代表本年度已走过的部分。
private struct BirthdayYearLine: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                for index in 0..<30 {
                    let x = CGFloat(index) * geometry.size.width / 29
                    path.move(to: CGPoint(x: x, y: index.isMultiple(of: 5) ? 0 : 3))
                    path.addLine(to: CGPoint(x: x, y: 8))
                }
            }
            .stroke(BirthdayDesignEnum.muted.opacity(0.5), lineWidth: 1)
            .overlay(alignment: .leading) {
                Path { path in
                    for index in 0..<30 where Double(index) / 30 < progress {
                        let x = CGFloat(index) * geometry.size.width / 29
                        path.move(to: CGPoint(x: x, y: index.isMultiple(of: 5) ? 0 : 3))
                        path.addLine(to: CGPoint(x: x, y: 8))
                    }
                }
                .stroke(BirthdayDesignEnum.accent, lineWidth: 1.5)
            }
        }
        .accessibilityHidden(true)
    }
}

/// 注册小组件并声明支持的桌面尺寸，各尺寸由内容自行设置安全边距。
@main
struct BirthdayDaysWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BirthdayDaysWidget", provider: BirthdayProvider()) {
            BirthdayWidgetView(entry: $0)
        }
        .configurationDisplayName("诞生记录")
        .description("记录诞生天数与生日刻度，可在应用中开启预计寿命的结束倒计时。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
