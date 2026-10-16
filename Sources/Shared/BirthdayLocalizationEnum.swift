import Foundation

/// 主应用与小组件共用的本地化入口，处理动态文案、参数顺序和英文复数。
enum BirthdayLocalizationEnum {
    /// 使用应用实际选中的语言，避免日期与界面文字分别采用不同语言。
    static var locale: Locale {
        Locale(identifier: Bundle.main.preferredLocalizations.first ?? "zh-Hans")
    }

    /// 从原生字符串目录读取动态键；静态 SwiftUI 文案直接使用系统本地化。
    static func text(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    /// 使用完整句子格式化参数，允许翻译调整语序，不拼接中文语法片段。
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }

    /// 输出不带千分位的天数，并由字符串目录处理英文 day / days。
    static func days(_ count: Int) -> String {
        // 不传入数字格式化区域，避免系统为五位数自动插入千分位。
        String(format: text("days.count"), arguments: [Int64(count)])
    }

    /// 输出年份数量，并由字符串目录处理英文 year / years。
    static func years(_ count: Int) -> String {
        String(format: text("years.count"), arguments: [Int64(count)])
    }

    /// 大号数字单独排版时，仍根据实际数量选择正确的英文单位。
    static func dayUnit(_ count: Int?) -> String {
        text(count == 1 ? "天（单数）" : "天")
    }

    /// 为主窗口和组件生成可调整语序的完整生命时长摘要。
    static func duration(years yearCount: Int, days dayCount: Int) -> String {
        format("生命时长摘要", years(yearCount), days(dayCount))
    }
}
