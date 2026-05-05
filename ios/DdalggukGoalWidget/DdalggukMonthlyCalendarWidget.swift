import SwiftUI
import WidgetKit

// MARK: - Shared constants
private let appGroupId = "group.com.aidiot.ddalgguk"

private let kCalYear = "cal_year"
private let kCalMonth = "cal_month"
private let kCalDaysInMonth = "cal_days_in_month"
private let kCalFirstWeekday = "cal_first_weekday"
private let kCalDrinkingDays = "cal_drinking_days"
private let kCalSoberDays = "cal_sober_days"
private let kCalNoRecordDays = "cal_no_record_days"

// Day status: 0 = no record (past), 1 = drinking, 2 = sober, 3 = future
private func dayStatusKey(_ day: Int) -> String { "cal_day_\(day)_status" }
private func dayDrunkLevelKey(_ day: Int) -> String { "cal_day_\(day)_drunk_level" }

private let dayLabels = ["월", "화", "수", "목", "금", "토", "일"]

private func sakuImageName(for drunkLevel: Int) -> String {
    let clamped = max(0, min(drunkLevel, 100))
    let level = (clamped / 10) * 10
    return "saku_\(String(format: "%02d", level))"
}

// MARK: - Entry
struct MonthlyCalendarEntry: TimelineEntry {
    let date: Date
    let year: Int
    let month: Int
    let daysInMonth: Int
    let firstWeekday: Int       // 1=Mon, 7=Sun
    let dayStatuses: [Int]      // index 0 = day 1, values: 0/1/2/3
    let dayDrunkLevels: [Int]   // index 0 = day 1, values: 0-100
    let drinkingDays: Int
    let soberDays: Int
    let noRecordDays: Int
}

// MARK: - Provider
struct MonthlyCalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthlyCalendarEntry {
        let cal = Calendar.current
        let now = Date()
        let month = cal.component(.month, from: now)
        let year = cal.component(.year, from: now)
        let range = cal.range(of: .day, in: .month, for: now)!
        let daysInMonth = range.count

        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        let firstDate = cal.date(from: comps)!
        let isoWeekday = cal.component(.weekday, from: firstDate)
        let firstWeekday = isoWeekday == 1 ? 7 : isoWeekday - 1

        return MonthlyCalendarEntry(
            date: now, year: year, month: month,
            daysInMonth: daysInMonth, firstWeekday: firstWeekday,
            dayStatuses: Array(repeating: 0, count: daysInMonth),
            dayDrunkLevels: Array(repeating: 0, count: daysInMonth),
            drinkingDays: 0, soberDays: 0, noRecordDays: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthlyCalendarEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthlyCalendarEntry>) -> Void) {
        let entry = readEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
            ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readEntry() -> MonthlyCalendarEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let cal = Calendar.current
        let now = Date()

        let year = defaults?.integer(forKey: kCalYear)
            ?? cal.component(.year, from: now)
        let month = defaults?.integer(forKey: kCalMonth)
            ?? cal.component(.month, from: now)
        let daysInMonth = defaults?.integer(forKey: kCalDaysInMonth)
            ?? { () -> Int in
                let range = cal.range(of: .day, in: .month, for: now)!
                return range.count
            }()
        let firstWeekday = defaults?.integer(forKey: kCalFirstWeekday)
            ?? { () -> Int in
                var comps = DateComponents()
                comps.year = year
                comps.month = month
                comps.day = 1
                let firstDate = cal.date(from: comps)!
                let wd = cal.component(.weekday, from: firstDate)
                return wd == 1 ? 7 : wd - 1
            }()

        var statuses: [Int] = []
        var drunkLevels: [Int] = []
        for d in 1...daysInMonth {
            statuses.append(defaults?.integer(forKey: dayStatusKey(d)) ?? 0)
            drunkLevels.append(defaults?.integer(forKey: dayDrunkLevelKey(d)) ?? 0)
        }

        let drinkingDays = defaults?.integer(forKey: kCalDrinkingDays) ?? 0
        let soberDays = defaults?.integer(forKey: kCalSoberDays) ?? 0
        let noRecordDays = defaults?.integer(forKey: kCalNoRecordDays) ?? 0

        return MonthlyCalendarEntry(
            date: now, year: year,
            month: month == 0 ? cal.component(.month, from: now) : month,
            daysInMonth: daysInMonth, firstWeekday: firstWeekday,
            dayStatuses: statuses, dayDrunkLevels: drunkLevels,
            drinkingDays: drinkingDays, soberDays: soberDays,
            noRecordDays: noRecordDays
        )
    }
}

// MARK: - Palette
private enum CalPalette {
    static let textPrimary = Color.black.opacity(0.87)
    static let textSecondary = Color.black.opacity(0.55)
    static let drinkingDot = Color(red: 1.0, green: 0.64, blue: 0.64)   // #FFA3A3
    static let soberDot = Color(red: 0.61, green: 0.88, blue: 0.75)     // #9CE0C0
    static let noRecordDot = Color(red: 0.74, green: 0.74, blue: 0.74)  // #BDBDBD
    static let todayRing = Color(red: 0xF2 / 255, green: 0x7B / 255, blue: 0x7B / 255)
}

// MARK: - Saku character view (reused from weekly widget)
private struct CalSakuView: View {
    let drunkLevel: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            Image(sakuImageName(for: drunkLevel))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
            Image("saku_eyes")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.3, height: size * 0.3)
        }
    }
}

// MARK: - View
struct MonthlyCalendarWidgetView: View {
    let entry: MonthlyCalendarEntry

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let sakuSize: CGFloat = 36

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                Text("\(entry.month)월")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(CalPalette.textPrimary)
                Spacer()
                statDotsRow
            }

            // Day-of-week header
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(dayLabels[i])
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(i >= 5 ? CalPalette.textSecondary : CalPalette.textPrimary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 2)

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 2) {
                // Empty cells before day 1
                ForEach(0..<(entry.firstWeekday - 1), id: \.self) { _ in
                    Color.clear.frame(height: sakuSize + 12)
                }

                // Day cells
                ForEach(1...entry.daysInMonth, id: \.self) { day in
                    dayCell(day: day)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(EdgeInsets(top: 14, leading: 12, bottom: 10, trailing: 12))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "ddalgguk://calendar"))

        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(Color.white, for: .widget)
        } else {
            content.background(Color.white)
        }
    }

    private func dayCell(day: Int) -> some View {
        let status = entry.dayStatuses[day - 1]
        let drunkLevel = entry.dayDrunkLevels[day - 1]
        let isToday = isDateToday(day: day)

        return ZStack {
            // Today background
            if isToday {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.08))
            }

            VStack(spacing: 1) {
            // Day number
            Text("\(day)")
                .font(.system(size: 9, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? CalPalette.todayRing : dayNumberColor(status: status))

            // Saku character or placeholder
            Group {
                if status == 1 {
                    CalSakuView(drunkLevel: drunkLevel, size: sakuSize)
                } else if status == 2 {
                    CalSakuView(drunkLevel: 0, size: sakuSize)
                } else if status == 3 {
                    Image("future_date")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: sakuSize, height: sakuSize)
                } else {
                    ZStack {
                        Image("empty_date")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: sakuSize, height: sakuSize)
                        Image("saku_eyes")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: sakuSize * 0.3, height: sakuSize * 0.3)
                    }
                }
            }
            .frame(width: sakuSize, height: sakuSize)
            }
        }
        .frame(height: sakuSize + 12)
    }

    private func dayNumberColor(status: Int) -> Color {
        switch status {
        case 3: return CalPalette.textSecondary.opacity(0.4)
        default: return CalPalette.textPrimary
        }
    }

    private func isDateToday(day: Int) -> Bool {
        let cal = Calendar.current
        let now = Date()
        return cal.component(.year, from: now) == entry.year
            && cal.component(.month, from: now) == entry.month
            && cal.component(.day, from: now) == day
    }

    private var statDotsRow: some View {
        HStack(spacing: 8) {
            if entry.drinkingDays > 0 {
                statDot(color: CalPalette.drinkingDot, count: entry.drinkingDays)
            }
            if entry.soberDays > 0 {
                statDot(color: CalPalette.soberDot, count: entry.soberDays)
            }
            if entry.noRecordDays > 0 {
                statDot(color: CalPalette.noRecordDot, count: entry.noRecordDays)
            }
        }
    }

    private func statDot(color: Color, count: Int) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text("\(count)")
                .font(.system(size: 11))
                .foregroundColor(CalPalette.textPrimary)
        }
    }
}

// MARK: - Widget
struct DdalggukMonthlyCalendarWidget: Widget {
    let kind: String = "DdalggukMonthlyCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthlyCalendarProvider()) { entry in
            MonthlyCalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("이번 달 캘린더")
        .description("이번 달 음주 기록 현황을 한눈에 확인하세요.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview
struct DdalggukMonthlyCalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        MonthlyCalendarWidgetView(entry: MonthlyCalendarEntry(
            date: Date(),
            year: 2026, month: 5,
            daysInMonth: 31,
            firstWeekday: 5,  // May 2026 starts on Friday
            dayStatuses: [
                1, 0, 2, 1, 0,   // 1-5
                3, 3, 1, 0, 1,   // 6-10
                2, 0, 0, 1, 0,   // 11-15
                1, 2, 0, 0, 1,   // 16-20
                0, 0, 1, 0, 2,   // 21-25
                3, 3, 3, 3, 3, 3 // 26-31
            ],
            dayDrunkLevels: [
                30, 0, 0, 50, 0,     // 1-5
                0, 0, 40, 0, 70,     // 6-10
                0, 0, 0, 60, 0,      // 11-15
                80, 0, 0, 0, 20,     // 16-20
                0, 0, 90, 0, 0,      // 21-25
                0, 0, 0, 0, 0, 0     // 26-31
            ],
            drinkingDays: 7, soberDays: 3, noRecordDays: 10
        ))
        .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
