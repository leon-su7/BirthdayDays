import Foundation

/// 用户自行设定的预计寿命与显示偏好；旧版本数据默认隐藏结束倒计时。
struct BirthdayLifePlan: Equatable {
    /// 预计寿命按完整周岁填写，限制输入范围以避免无效日期与误操作。
    static let expectedLifespanRange = 1...150
    /// 首次设置时使用的可编辑初始值。
    static let defaultExpectedLifespanYears = 80

    /// 从出生日期起算的预计寿命，不是从当前日期再增加的年数。
    var expectedLifespanYears = defaultExpectedLifespanYears
    /// 控制主界面及全部尺寸小组件是否展示结束倒计时。
    var showsCountdown = false
}

/// 一次读取的共享记录，让小组件同一条时间线使用相同的生日与偏好。
struct BirthdayRecord {
    let birthday: Date?
    let lifePlan: BirthdayLifePlan
}
