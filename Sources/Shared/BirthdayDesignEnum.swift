import SwiftUI

/// 应用与小组件共用的颜色和日期格式，保持同一套深色时间刻度主题。
enum BirthdayDesignEnum {
    static let background = Color(red: 0.047, green: 0.063, blue: 0.067)
    static let surface = Color(red: 0.076, green: 0.094, blue: 0.098)
    static let accent = Color(red: 0.49, green: 0.89, blue: 0.76)
    static let text = Color(red: 0.94, green: 0.96, blue: 0.94)
    static let secondary = Color(red: 0.59, green: 0.65, blue: 0.63)
    static let muted = Color(red: 0.39, green: 0.46, blue: 0.44)
    static let line = Color.white.opacity(0.085)

    /// 日期语言跟随当前应用选中的本地化，支持 macOS 的单独应用语言设置。
    static func dateLabel(_ date: Date) -> String {
        date.formatted(.dateTime.locale(BirthdayLocalizationEnum.locale).year().month(.twoDigits).day(.twoDigits))
    }

    /// 简短月日，用于年度周期与小组件中的日期标记。
    static func monthDay(_ date: Date) -> String {
        date.formatted(.dateTime.locale(BirthdayLocalizationEnum.locale).month(.twoDigits).day(.twoDigits))
    }
}
