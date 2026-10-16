import Foundation

/// 主界面与小组件共用的自然日统计，年度进度以相邻两次生日为边界。
struct BirthdayMetrics {
    /// 生日与统计日期，均使用当前日历的当天零点。
    let birthday: Date
    let today: Date
    /// 从诞生之日起完整经历的天数，不包含千分位格式。
    let daysAlive: Int
    /// 已满周岁及本次生日周期内已经经历的自然天数。
    let age: Int
    let daysSinceBirthday: Int
    /// 下一次生日；生日当天指向当天，倒计时为零。
    let nextBirthday: Date
    let daysUntilBirthday: Int
    /// 本年度生日周期的进度，范围为 0 到 1。
    let yearProgress: Double
    /// 用户设定的预计寿命与对应生日；结束倒计时以这一天为零点。
    let expectedLifespanYears: Int
    let expectedEndDate: Date
    /// 距离设定结束日期的自然天数；达到或超过日期后始终为零。
    let daysRemaining: Int

    /// 是否恰好处于生日当天。
    var isBirthday: Bool { daysUntilBirthday == 0 }

    /// 下次生日对应的周岁，生日当天展示当天年龄。
    var nextAge: Int { isBirthday ? age : age + 1 }

    /// 根据生日、参考日期及预计寿命建立统计，排除未来生日与无效寿命。
    init?(birthday: Date, on referenceDate: Date,
          expectedLifespanYears: Int = BirthdayLifePlan.defaultExpectedLifespanYears) {
        let calendar = Calendar.current
        let birthDay = calendar.startOfDay(for: birthday)
        let today = calendar.startOfDay(for: referenceDate)
        guard birthDay <= today,
              BirthdayLifePlan.expectedLifespanRange.contains(expectedLifespanYears) else { return nil }

        let birthYear = calendar.component(.year, from: birthDay)
        let currentYear = calendar.component(.year, from: today)
        guard let anniversary = Self.anniversary(of: birthDay, year: currentYear, calendar: calendar),
              let previousAnniversary = Self.anniversary(of: birthDay, year: currentYear - 1, calendar: calendar),
              let followingAnniversary = Self.anniversary(of: birthDay, year: currentYear + 1, calendar: calendar),
              let expectedEndDate = Self.anniversary(of: birthDay, year: birthYear + expectedLifespanYears, calendar: calendar)
        else { return nil }

        // 非闰年的二月二十九日生日取二月最后一天，周岁和倒计时采用同一边界。
        let lastBirthday = anniversary <= today ? anniversary : previousAnniversary
        let cycleEnd = anniversary <= today ? followingAnniversary : anniversary
        let nextBirthday = anniversary >= today ? anniversary : followingAnniversary
        let elapsed = calendar.dateComponents([.day], from: lastBirthday, to: today).day ?? 0
        let cycleLength = calendar.dateComponents([.day], from: lastBirthday, to: cycleEnd).day ?? 365

        self.birthday = birthDay
        self.today = today
        daysAlive = BirthdayStore.daysAlive(on: today, birthday: birthDay)
        age = max(0, currentYear - birthYear - (anniversary > today ? 1 : 0))
        daysSinceBirthday = elapsed
        self.nextBirthday = nextBirthday
        daysUntilBirthday = calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0
        yearProgress = min(1, max(0, Double(elapsed) / Double(max(1, cycleLength))))
        self.expectedLifespanYears = expectedLifespanYears
        self.expectedEndDate = expectedEndDate
        // 使用自然日差而非年数乘 365，统一处理闰年、二月末生日及夏令时。
        daysRemaining = max(0, calendar.dateComponents([.day], from: today, to: expectedEndDate).day ?? 0)
    }

    /// 在指定年份建立生日纪念日，将不存在的日号收敛到当月最后一天。
    private static func anniversary(of birthday: Date, year: Int, calendar: Calendar) -> Date? {
        let month = calendar.component(.month, from: birthday)
        let day = calendar.component(.day, from: birthday)
        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let validDays = calendar.range(of: .day, in: .month, for: monthStart) else { return nil }
        return calendar.date(from: DateComponents(year: year, month: month, day: min(day, validDays.count)))
    }
}
