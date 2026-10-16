import Foundation
import Combine
import WidgetKit
import os

/// 管理生日、预计寿命及倒计时偏好，并通过 App Group 与桌面小组件共享。
final class BirthdayStore: ObservableObject {
    private static let logger = Logger(subsystem: "local.birthday.app", category: "storage")
    /// UserDefaults 中保存生日时间戳的键。
    private static let birthdayKey = "birthday.timeIntervalSince1970"
    /// 预计寿命和显示开关作为同一份字典保存，避免小组件读到半更新的偏好。
    private static let lifePlanKey = "birthday.lifePlan"

    /// 当前已保存的生日；为 nil 表示用户尚未选择。
    @Published private(set) var birthday: Date?
    /// 当前已保存的预计寿命和结束倒计时开关。
    @Published private(set) var lifePlan: BirthdayLifePlan

    /// 共享组不可用时明确提示，避免把仅保存在主应用中的数据误报为已同步。
    let isSharedStorageAvailable: Bool

    /// 与共享存储绑定的 UserDefaults 实例。
    private let defaults: UserDefaults
    /// 注入存储用于预览或验证时，禁止清除真实应用的本地数据。
    private let usesAppStorage: Bool

    /// 创建共享存储管理器；App Group 不可用时回退到本地沙盒存储。
    init(defaults suppliedDefaults: UserDefaults? = nil) {
        let sharedDefaults = suppliedDefaults ?? Self.sharedDefaults()
        isSharedStorageAvailable = sharedDefaults != nil
        defaults = sharedDefaults ?? .standard
        usesAppStorage = suppliedDefaults == nil
        birthday = Self.readBirthday(from: defaults)
        lifePlan = Self.readLifePlan(from: defaults)

        // 旧版本回退到应用本地存储时，首次连接共享组便迁移已有生日。
        if birthday == nil, suppliedDefaults == nil,
           let localBirthday = Self.readBirthday(from: .standard) {
            birthday = localBirthday
            defaults.set(localBirthday.timeIntervalSince1970, forKey: Self.birthdayKey)
        }
        // 共享组恢复后同样迁移本地偏好，已经存在的共享设置始终优先。
        if suppliedDefaults == nil, defaults.object(forKey: Self.lifePlanKey) == nil,
           let localPlan = UserDefaults.standard.dictionary(forKey: Self.lifePlanKey) {
            defaults.set(localPlan, forKey: Self.lifePlanKey)
            lifePlan = Self.readLifePlan(from: defaults)
        }
    }

    /// 校验并一起保存生日和时间规划，写入全部数据后再请求小组件刷新。
    /// - Returns: 输入有效且完成保存时返回 true，无效输入保持已保存数据不变。
    @discardableResult
    func saveBirthday(_ date: Date, lifePlan: BirthdayLifePlan) -> Bool {
        guard date.timeIntervalSince1970.isFinite,
              Calendar.current.startOfDay(for: date) <= Calendar.current.startOfDay(for: Date()),
              BirthdayLifePlan.expectedLifespanRange.contains(lifePlan.expectedLifespanYears) else {
            Self.logger.error("生日或预计寿命无效，未保存诞生记录")
            return false
        }
        // 正午标准化延续旧版本的存储方式，统计仍以自然日为边界。
        let normalizedDate = Self.noonDate(from: date)
        defaults.set(normalizedDate.timeIntervalSince1970, forKey: Self.birthdayKey)
        defaults.set([
            "expectedLifespanYears": lifePlan.expectedLifespanYears,
            "showsCountdown": lifePlan.showsCountdown
        ], forKey: Self.lifePlanKey)
        birthday = normalizedDate
        self.lifePlan = lifePlan
        WidgetCenter.shared.reloadTimelines(ofKind: "BirthdayDaysWidget")
        return true
    }

    /// 清除生日并返回引导状态；保留寿命及显示偏好，便于重新录入生日。
    func clearBirthday() {
        birthday = nil
        defaults.removeObject(forKey: Self.birthdayKey)
        if usesAppStorage {
            UserDefaults.standard.removeObject(forKey: Self.birthdayKey)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "BirthdayDaysWidget")
    }

    /// 从签名团队对应的共享组一次读取生日与时间规划，供小组件生成时间线。
    static func readSharedRecord() -> BirthdayRecord {
        guard let defaults = sharedDefaults() else {
            return BirthdayRecord(birthday: nil, lifePlan: BirthdayLifePlan())
        }
        return BirthdayRecord(birthday: readBirthday(from: defaults), lifePlan: readLifePlan(from: defaults))
    }

    /// 校验共享组权限后创建偏好存储；仅构造 suite 无法证明签名授权有效。
    private static func sharedDefaults() -> UserDefaults? {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String,
              !identifier.contains("$("),
              FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil,
              let defaults = UserDefaults(suiteName: identifier) else {
            logger.error("生日共享组不可用，请检查应用与小组件的签名及 AppGroupIdentifier")
            return nil
        }
        return defaults
    }

    /// 使用键是否存在判断空值，确保 Unix 纪元当天的有效生日也能读取。
    private static func readBirthday(from defaults: UserDefaults) -> Date? {
        guard let timestamp = defaults.object(forKey: birthdayKey) as? NSNumber,
              timestamp.doubleValue.isFinite else { return nil }
        return Date(timeIntervalSince1970: timestamp.doubleValue)
    }

    /// 缺少新字段时使用兼容默认值，损坏的寿命输入回退而不影响原有生日。
    private static func readLifePlan(from defaults: UserDefaults) -> BirthdayLifePlan {
        guard let stored = defaults.dictionary(forKey: lifePlanKey) else { return BirthdayLifePlan() }
        guard let years = stored["expectedLifespanYears"] as? NSNumber,
              years.doubleValue.isFinite,
              years.doubleValue == Double(years.intValue),
              BirthdayLifePlan.expectedLifespanRange.contains(years.intValue) else {
            logger.error("预计寿命存储无效，已恢复默认值并隐藏结束倒计时")
            return BirthdayLifePlan()
        }
        return BirthdayLifePlan(expectedLifespanYears: years.intValue,
                                showsCountdown: stored["showsCountdown"] as? Bool ?? false)
    }

    /// 将任意日期标准化为当日正午，保证跨天计算始终以自然日为准。
    static func noonDate(from date: Date) -> Date {
        Calendar.current.date(
            bySettingHour: 12,
            minute: 0,
            second: 0,
            of: date
        ) ?? date
    }

    /// 计算已完整经历的自然天数；生日当天返回 0，次日返回 1。
    static func daysAlive(on date: Date, birthday: Date) -> Int {
        let startDay = Calendar.current.startOfDay(for: date)
        let birthdayDay = Calendar.current.startOfDay(for: birthday)
        let elapsedDays = Calendar.current.dateComponents(
            [.day],
            from: birthdayDay,
            to: startDay
        ).day ?? 0
        return elapsedDays
    }
}
