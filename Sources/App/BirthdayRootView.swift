import SwiftUI
import Combine
import WidgetKit

/// 以累计天数、生日年度刻度和独立设置区呈现与世界相遇后的时间。
struct BirthdayRootView: View {
    @StateObject private var store: BirthdayStore
    @State private var selectedDate = Date()
    @State private var hasEditedDate = false
    @State private var expectedLifespanInput = String(BirthdayLifePlan.defaultExpectedLifespanYears)
    @State private var showsLifeCountdown = false
    @State private var saveFailed = false
    @State private var referenceDate = Date()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let clock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    /// 可注入仓库供本地预览使用；正常运行使用 App Group 中的生日。
    init(store: BirthdayStore = BirthdayStore()) {
        _store = StateObject(wrappedValue: store)
        _selectedDate = State(initialValue: store.birthday ?? Date())
        _expectedLifespanInput = State(initialValue: String(store.lifePlan.expectedLifespanYears))
        _showsLifeCountdown = State(initialValue: store.lifePlan.showsCountdown)
    }

    /// 编辑过程中即时预览草稿，保存前不会修改小组件读取的数据。
    private var metrics: BirthdayMetrics? {
        guard let birthday = hasEditedDate ? selectedDate : store.birthday else { return nil }
        return BirthdayMetrics(birthday: birthday, on: referenceDate,
                               expectedLifespanYears: selectedLifePlan?.expectedLifespanYears ?? store.lifePlan.expectedLifespanYears)
    }

    /// 保留输入文本以识别空值和越界输入，合法整数才转换为可保存的时间规划。
    private var selectedLifePlan: BirthdayLifePlan? {
        guard let years = Int(expectedLifespanInput),
              BirthdayLifePlan.expectedLifespanRange.contains(years) else { return nil }
        return BirthdayLifePlan(expectedLifespanYears: years, showsCountdown: showsLifeCountdown)
    }

    /// 同时比较生日与时间规划；生日按自然日比较，避免正午标准化造成误判。
    private var hasUnsavedChanges: Bool {
        guard let saved = store.birthday else { return true }
        return !Calendar.current.isDate(saved, inSameDayAs: selectedDate) || selectedLifePlan != store.lifePlan
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header.padding(.bottom, 22)
                    Rectangle().fill(BirthdayDesignEnum.line).frame(height: 1)
                    mainSection(compact: geometry.size.width < 800).padding(.vertical, 24)
                    yearSection
                    footer.padding(.top, 20)
                }
                .padding(.horizontal, geometry.size.width < 800 ? 32 : 44)
                .padding(.top, 36)
                .padding(.bottom, 24)
                .frame(maxWidth: 1120)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .scrollIndicators(.hidden)
        }
        .background(background)
        .preferredColorScheme(.dark)
        .tint(BirthdayDesignEnum.accent)
        .onAppear {
            selectedDate = store.birthday ?? Date()
            expectedLifespanInput = String(store.lifePlan.expectedLifespanYears)
            showsLifeCountdown = store.lifePlan.showsCountdown
            referenceDate = Date()
            // 应用升级后主动请求重新渲染，让已添加的小组件采用当前版本的布局。
            WidgetCenter.shared.reloadTimelines(ofKind: "BirthdayDaysWidget")
        }
        .onReceive(clock) { referenceDate = $0 }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in referenceDate = Date() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { referenceDate = Date() }
        }
    }

    /// 仅在边缘加入柔和绿色光晕，保证数字与表单的对比度。
    private var background: some View {
        ZStack {
            BirthdayDesignEnum.background
            RadialGradient(colors: [BirthdayDesignEnum.accent.opacity(0.045), .clear], center: .topLeading, startRadius: 20, endRadius: 600)
        }
        .ignoresSafeArea()
    }

    /// 标题、轻量说明与当天日期。
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 10) {
                    Circle().fill(BirthdayDesignEnum.accent).frame(width: 7, height: 7)
                    Text("诞生记录")
                        .font(.system(size: 23, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(BirthdayDesignEnum.text)
                }
                Text("每一天，都算数。")
                    .font(.system(size: 12))
                    .foregroundStyle(BirthdayDesignEnum.secondary)
                    .padding(.leading, 17)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Text("今天").font(.system(size: 10, weight: .medium)).foregroundStyle(BirthdayDesignEnum.muted)
                Text(BirthdayDesignEnum.dateLabel(referenceDate))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(BirthdayDesignEnum.secondary)
            }
        }
    }

    /// 左侧累计天数与右侧生日设置共享基线，窄窗口适当缩小数字。
    private func mainSection(compact: Bool) -> some View {
        HStack(alignment: .center, spacing: compact ? 24 : 40) {
            lifeSection(compact: compact).frame(maxWidth: .infinity, alignment: .leading)
            birthdayEditor.frame(width: compact ? 238 : 266)
        }
    }

    /// 大字号天数是主视觉，年数与余日提供易读的时间参照。
    private func lifeSection(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text("与世界相遇，已经").font(.system(size: 13, weight: .medium)).foregroundStyle(BirthdayDesignEnum.secondary)
                if hasUnsavedChanges && (hasEditedDate || selectedLifePlan != store.lifePlan) {
                    Text("预览")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(BirthdayDesignEnum.accent)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(BirthdayDesignEnum.accent.opacity(0.08), in: Capsule())
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                // 将整数转为字符串，避免 SwiftUI 的本地化数字插值自动添加千分位。
                Text(metrics.map { String($0.daysAlive) } ?? "—")
                    .font(.system(size: compact ? 76 : 104, weight: .light, design: .rounded))
                    .tracking(-4).monospacedDigit()
                    .foregroundStyle(BirthdayDesignEnum.text)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.numericText())
                    .accessibilityLabel(metrics.map { BirthdayLocalizationEnum.format("已经诞生%@", BirthdayLocalizationEnum.days($0.daysAlive)) } ?? BirthdayLocalizationEnum.text("尚未记录生日"))
                Text(BirthdayLocalizationEnum.dayUnit(metrics?.daysAlive)).font(.system(size: 23)).foregroundStyle(BirthdayDesignEnum.accent)
                    .fixedSize().layoutPriority(2)
            }
            .padding(.top, 16).padding(.bottom, 19)
            .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: metrics?.daysAlive)
            if let metrics {
                Text(BirthdayLocalizationEnum.duration(years: metrics.age, days: metrics.daysSinceBirthday))
                .font(.system(size: 14)).foregroundStyle(BirthdayDesignEnum.secondary)
                Text("从 \(BirthdayDesignEnum.dateLabel(metrics.birthday)) 开始的故事")
                    .font(.system(size: 11)).foregroundStyle(BirthdayDesignEnum.muted).padding(.top, 12)
            } else {
                Text("记录生日，让时间有迹可循。")
                    .font(.system(size: 14)).foregroundStyle(BirthdayDesignEnum.secondary)
                Text("你的每一天，都值得被看见。")
                    .font(.system(size: 11)).foregroundStyle(BirthdayDesignEnum.muted).padding(.top, 12)
            }
            if showsLifeCountdown, let plan = selectedLifePlan {
                lifeCountdown(plan: plan)
                    .padding(.top, 24)
            }
        }
        .padding(.vertical, 16)
    }

    /// 结束倒计时仅在开启时出现，与累计天数保持清晰层次和安全间距。
    private func lifeCountdown(plan: BirthdayLifePlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle().fill(BirthdayDesignEnum.line).frame(height: 1).padding(.bottom, 6)
            Text("结束倒计时 · 预计 \(String(plan.expectedLifespanYears)) 岁")
                .font(.system(size: 11)).foregroundStyle(BirthdayDesignEnum.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(metrics.map { String($0.daysRemaining) } ?? "—")
                    .font(.system(size: 38, weight: .light, design: .rounded)).monospacedDigit()
                    .foregroundStyle(BirthdayDesignEnum.accent)
                    .contentTransition(.numericText())
                Text(BirthdayLocalizationEnum.dayUnit(metrics?.daysRemaining)).font(.system(size: 12)).foregroundStyle(BirthdayDesignEnum.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(metrics.map { BirthdayLocalizationEnum.format("预计%@岁，剩余%@", String(plan.expectedLifespanYears), BirthdayLocalizationEnum.days($0.daysRemaining)) } ?? BirthdayLocalizationEnum.text("保存生日后开始结束倒计时"))
            Text(metrics.map {
                referenceDate >= $0.expectedEndDate ? String(localized: "已到设定日期 · \(BirthdayDesignEnum.dateLabel($0.expectedEndDate))") : String(localized: "设定日期 · \(BirthdayDesignEnum.dateLabel($0.expectedEndDate))")
            } ?? BirthdayLocalizationEnum.text("记录生日后，计算剩余天数"))
                .font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.muted)
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: metrics?.daysRemaining)
    }

    /// 日期、寿命输入、开关与保存操作均保持独立点击区及安全间距。
    private var birthdayEditor: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                LucideIcon(icon: .calendarDays, size: 15)
                Text("时间的起点").font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(BirthdayDesignEnum.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(BirthdayDesignEnum.monthDay(selectedDate))
                    .font(.system(size: 26, weight: .light)).foregroundStyle(BirthdayDesignEnum.text)
                Spacer(minLength: 0)
                Text(String(Calendar.current.component(.year, from: selectedDate)))
                    .font(.system(size: 12, design: .monospaced)).foregroundStyle(BirthdayDesignEnum.muted)
            }
            .padding(.top, 20).padding(.bottom, 16)
            DatePicker("生日", selection: Binding(get: { selectedDate }, set: {
                selectedDate = $0
                hasEditedDate = true
            }), in: Date.distantPast...referenceDate, displayedComponents: [.date])
                .datePickerStyle(.field).labelsHidden().controlSize(.large)
                .environment(\.locale, BirthdayLocalizationEnum.locale)
                .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                .padding(.horizontal, 12)
                .background(BirthdayDesignEnum.background.opacity(0.75), in: RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(BirthdayDesignEnum.line))
            lifePlanEditor.padding(.top, 18)
            Button {
                guard let plan = selectedLifePlan else { return }
                saveFailed = !store.saveBirthday(selectedDate, lifePlan: plan)
                if !saveFailed { hasEditedDate = false }
            } label: {
                HStack(spacing: 8) {
                    Text(LocalizedStringKey(hasUnsavedChanges ? "保存设置" : "设置已保存"))
                    Spacer()
                    LucideIcon(icon: hasUnsavedChanges ? .arrowUpRight : .check, size: 16)
                }
                .font(.system(size: 12, weight: .semibold)).padding(.horizontal, 14).frame(height: 42)
            }
            .buttonStyle(BirthdayActionButtonStyle()).disabled(!hasUnsavedChanges || selectedLifePlan == nil).padding(.top, 18)
            if saveFailed {
                Text("保存失败，请检查生日和预计寿命")
                    .font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.secondary).padding(.top, 10)
            }
            HStack {
                Text(LocalizedStringKey(hasUnsavedChanges ? "保存后同步到小组件" : "预计寿命可随时调整"))
                    .font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.muted)
                Spacer(minLength: 4)
                if store.birthday != nil {
                    Button("清除") {
                        store.clearBirthday()
                        selectedDate = Date()
                        expectedLifespanInput = String(store.lifePlan.expectedLifespanYears)
                        showsLifeCountdown = store.lifePlan.showsCountdown
                        hasEditedDate = false
                        saveFailed = false
                    }
                    .buttonStyle(.plain).font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.secondary)
                    .padding(.vertical, 6).help("清除生日并重置桌面小组件")
                }
            }
            .frame(height: 24).padding(.top, 12)
        }
        .padding(22)
        .background(BirthdayDesignEnum.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(BirthdayDesignEnum.line))
    }

    /// 寿命支持直接输入和步进调整；隐藏倒计时不会丢失已填写的寿命。
    private var lifePlanEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("预计寿命").font(.system(size: 11)).foregroundStyle(BirthdayDesignEnum.secondary)
                Spacer(minLength: 4)
                TextField("80", text: $expectedLifespanInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17, weight: .medium, design: .rounded)).monospacedDigit()
                    .multilineTextAlignment(.trailing).frame(width: 42)
                    .accessibilityLabel("预计寿命，填写 1 至 150 岁")
                Text(BirthdayLocalizationEnum.text(selectedLifePlan?.expectedLifespanYears == 1 ? "年（单数）" : "岁")).font(.system(size: 11)).foregroundStyle(BirthdayDesignEnum.secondary)
                Stepper("调整预计寿命", value: Binding(
                    get: { selectedLifePlan?.expectedLifespanYears ?? store.lifePlan.expectedLifespanYears },
                    set: { expectedLifespanInput = String($0) }
                ), in: BirthdayLifePlan.expectedLifespanRange)
                    .labelsHidden().fixedSize()
            }
            .frame(minHeight: 42).padding(.horizontal, 12)
            .background(BirthdayDesignEnum.background.opacity(0.75), in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(BirthdayDesignEnum.line))
            if selectedLifePlan == nil {
                Text("请输入 1–150 之间的整数")
                    .font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.secondary)
            }
            Toggle("显示结束倒计时", isOn: $showsLifeCountdown)
                .toggleStyle(.switch).controlSize(.small)
                .font(.system(size: 11)).foregroundStyle(BirthdayDesignEnum.secondary)
            Text("按生日和预计寿命计算剩余天数")
                .font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.muted)
        }
    }

    /// 年度环与下次生日并排，提供生命总天数之外的近程时间感。
    private var yearSection: some View {
        HStack(spacing: 26) {
            BirthdayDial(progress: metrics?.yearProgress ?? 0, value: metrics.map { String($0.age) } ?? "—", caption: metrics == nil ? "岁月待启" : "周岁")
                .frame(width: 124, height: 124)
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey(metrics == nil ? "你的时间，正待展开。" : metrics?.isBirthday == true ? "今天，是你的生日。" : "这一岁，正在继续。"))
                    .font(.system(size: 18, weight: .medium)).foregroundStyle(BirthdayDesignEnum.text)
                Text(metrics.map { BirthdayLocalizationEnum.format("本年度已走过%@", BirthdayLocalizationEnum.days($0.daysSinceBirthday)) } ?? BirthdayLocalizationEnum.text("从生日出发，走过属于你的一圈。"))
                    .font(.system(size: 12)).foregroundStyle(BirthdayDesignEnum.secondary)
                HStack(spacing: 6) {
                    Circle().fill(BirthdayDesignEnum.accent).frame(width: 4, height: 4)
                    Text("一圈刻度，一年时光").font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.muted)
                }
            }
            Spacer(minLength: 8)
            Rectangle().fill(BirthdayDesignEnum.line).frame(width: 1, height: 80)
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey(metrics?.isBirthday == true ? "生日快乐" : "距离下次生日"))
                    .font(.system(size: 11)).foregroundStyle(BirthdayDesignEnum.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(metrics.map { String($0.daysUntilBirthday) } ?? "—")
                        .font(.system(size: 36, weight: .light, design: .rounded)).monospacedDigit()
                        .foregroundStyle(BirthdayDesignEnum.accent)
                    Text(BirthdayLocalizationEnum.dayUnit(metrics?.daysUntilBirthday)).font(.system(size: 11)).foregroundStyle(BirthdayDesignEnum.secondary)
                }
                Text(metrics.map { String(localized: "\(BirthdayDesignEnum.monthDay($0.nextBirthday)) · \(String($0.nextAge)) 岁") } ?? BirthdayLocalizationEnum.text("等待你的时间起点"))
                    .font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.muted)
            }
            .frame(minWidth: 114, alignment: .leading)
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(BirthdayDesignEnum.surface.opacity(0.45), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(BirthdayDesignEnum.line))
    }

    /// 明确区分共享存储未配置、尚未保存和自动同步状态。
    private var footer: some View {
        HStack(spacing: 12) {
            Text("每天零点，添一格新的刻度。")
                .font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.muted)
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(store.isSharedStorageAvailable ? BirthdayDesignEnum.accent : BirthdayDesignEnum.secondary)
                    .frame(width: 4, height: 4)
                Text(LocalizedStringKey(!store.isSharedStorageAvailable ? "小组件同步暂不可用" : store.birthday == nil ? "保存后自动同步小组件" : "小组件自动同步"))
                    .font(.system(size: 10)).foregroundStyle(BirthdayDesignEnum.secondary)
            }
        }
    }
}

/// 提供克制的悬停和按压反馈，已保存状态使用低对比度背景。
private struct BirthdayActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    /// 构建按钮样式，并遵循系统的减少动态效果设置。
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? BirthdayDesignEnum.background : BirthdayDesignEnum.accent)
            .background(isEnabled ? BirthdayDesignEnum.accent.opacity(isHovered ? 0.88 : 1) : BirthdayDesignEnum.accent.opacity(0.075), in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(isEnabled ? .clear : BirthdayDesignEnum.accent.opacity(0.13)))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .onHover { isHovered = $0 }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHovered)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
