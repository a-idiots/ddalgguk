import SwiftUI
import WidgetKit

// MARK: - Shared constants
// Keep in sync with lib/features/profile/data/services/weekly_home_widget_service.dart
private let appGroupId = "group.com.aidiot.ddalgguk"

// Keys for each day (0 = Monday, 6 = Sunday)
private func dayKey(_ index: Int, _ field: String) -> String {
    "weekly_day_\(index)_\(field)"
}

private let kWeeklyDateRange = "weekly_date_range"
private let kWeeklySoberDays = "weekly_sober_days"
private let kWeeklyDrinkingDays = "weekly_drinking_days"

// MARK: - Day labels (Korean)
private let dayLabels = ["월", "화", "수", "목", "금", "토", "일"]

// MARK: - Saku gradient colors (matches AppColors.sakuGradientColors)
private let sakuGradientColors: [Int: Color] = [
    0:   Color(red: 0xD9/255, green: 0xD9/255, blue: 0xD9/255),
    10:  Color(red: 0xFF/255, green: 0xCD/255, blue: 0xC2/255),
    20:  Color(red: 0xFB/255, green: 0xB5/255, blue: 0xAB/255),
    30:  Color(red: 0xFB/255, green: 0xA9/255, blue: 0x9E/255),
    40:  Color(red: 0xFF/255, green: 0x97/255, blue: 0x8C/255),
    50:  Color(red: 0xFF/255, green: 0x93/255, blue: 0xB3/255),
    60:  Color(red: 0xE6/255, green: 0xB5/255, blue: 0xFF/255),
    70:  Color(red: 0xAF/255, green: 0x8B/255, blue: 0xFA/255),
    80:  Color(red: 0xBC/255, green: 0x6D/255, blue: 0xF4/255),
    90:  Color(red: 0xAE/255, green: 0x39/255, blue: 0x95/255),
    100: Color(red: 0x2C/255, green: 0x62/255, blue: 0x70/255),
]

private func sakuColor(for drunkLevel: Int) -> Color {
    let level = (drunkLevel / 10) * 10
    return sakuGradientColors[min(level, 100)] ?? sakuGradientColors[0]!
}

// MARK: - Entry
struct WeeklyEntry: TimelineEntry {
    let date: Date
    let dateRange: String
    let days: [DayData]
    let soberDays: Int
    let drinkingDays: Int

    struct DayData {
        let drunkLevel: Int    // 0-100
        let hasRecords: Bool
        let isFuture: Bool
    }
}

// MARK: - Provider
struct WeeklyProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeeklyEntry {
        WeeklyEntry(
            date: Date(),
            dateRange: "04.14. ~ 04.20.",
            days: [
                .init(drunkLevel: 30, hasRecords: true, isFuture: false),
                .init(drunkLevel: 0, hasRecords: true, isFuture: false),
                .init(drunkLevel: 60, hasRecords: true, isFuture: false),
                .init(drunkLevel: 0, hasRecords: false, isFuture: false),
                .init(drunkLevel: 40, hasRecords: true, isFuture: false),
                .init(drunkLevel: 0, hasRecords: false, isFuture: true),
                .init(drunkLevel: 0, hasRecords: false, isFuture: true),
            ],
            soberDays: 2,
            drinkingDays: 3
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyEntry>) -> Void) {
        let entry = readEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
            ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readEntry() -> WeeklyEntry {
        let defaults = UserDefaults(suiteName: appGroupId)

        let dateRange = defaults?.string(forKey: kWeeklyDateRange) ?? ""
        let soberDays = defaults?.integer(forKey: kWeeklySoberDays) ?? 7
        let drinkingDays = defaults?.integer(forKey: kWeeklyDrinkingDays) ?? 0

        var days: [WeeklyEntry.DayData] = []
        for i in 0..<7 {
            let drunkLevel = defaults?.integer(forKey: dayKey(i, "drunk_level")) ?? 0
            let hasRecords = defaults?.bool(forKey: dayKey(i, "has_records")) ?? false
            let isFuture = defaults?.bool(forKey: dayKey(i, "is_future")) ?? false
            days.append(.init(drunkLevel: drunkLevel, hasRecords: hasRecords, isFuture: isFuture))
        }

        return WeeklyEntry(
            date: Date(),
            dateRange: dateRange,
            days: days,
            soberDays: soberDays,
            drinkingDays: drinkingDays
        )
    }
}

// MARK: - Palette
private enum WPalette {
    static let textPrimary = Color.black.opacity(0.87)
    static let textSecondary = Color.black.opacity(0.55)
    static let futureCircle = Color(white: 0.90)
    static let emptyCircle = Color(red: 0xD9/255, green: 0xD9/255, blue: 0xD9/255)
    static let greenAccent = Color(red: 0x27/255, green: 0xD6/255, blue: 0x81/255)
}

// MARK: - Views
struct WeeklyWidgetView: View {
    let entry: WeeklyEntry

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                Text("지난 일주일")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(WPalette.textPrimary)
                Spacer()
                Text(entry.dateRange)
                    .font(.system(size: 11))
                    .foregroundColor(WPalette.textSecondary)
            }

            Spacer(minLength: 0)

            // 7-day circles row
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    dayColumn(index: i)
                    if i < 6 {
                        Spacer(minLength: 0)
                    }
                }
            }

            Spacer(minLength: 0)

            // Bottom summary
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(sakuColor(for: 30))
                        .frame(width: 8, height: 8)
                    Text("음주 \(entry.drinkingDays)일")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(WPalette.textSecondary)
                }
                HStack(spacing: 4) {
                    Circle()
                        .fill(WPalette.greenAccent)
                        .frame(width: 8, height: 8)
                    Text("금주 \(entry.soberDays)일")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(WPalette.textSecondary)
                }
                Spacer()
            }
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "ddalgguk://profile"))

        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(Color.white, for: .widget)
        } else {
            content.background(Color.white)
        }
    }

    private func dayColumn(index: Int) -> some View {
        let day = entry.days[index]

        return VStack(spacing: 6) {
            Text(dayLabels[index])
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(
                    index >= 5
                        ? WPalette.textSecondary
                        : WPalette.textPrimary
                )

            ZStack {
                if day.isFuture {
                    // Future: dashed outline circle
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                        .foregroundColor(WPalette.futureCircle)
                        .frame(width: 32, height: 32)
                } else if day.hasRecords && day.drunkLevel > 0 {
                    // Had drinks: colored circle with level
                    Circle()
                        .fill(sakuColor(for: day.drunkLevel))
                        .frame(width: 32, height: 32)
                    Text("\(day.drunkLevel)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                } else if day.hasRecords && day.drunkLevel == 0 {
                    // Recorded sober
                    Circle()
                        .fill(WPalette.greenAccent.opacity(0.3))
                        .frame(width: 32, height: 32)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(WPalette.greenAccent)
                } else {
                    // No record (past)
                    Circle()
                        .fill(WPalette.emptyCircle.opacity(0.4))
                        .frame(width: 32, height: 32)
                    Text("–")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(WPalette.textSecondary)
                }
            }
        }
    }
}

// MARK: - Widget
struct DdalggukWeeklyWidget: Widget {
    let kind: String = "DdalggukWeeklyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyProvider()) { entry in
            WeeklyWidgetView(entry: entry)
        }
        .configurationDisplayName("지난 일주일")
        .description("이번 주 음주 기록을 한눈에 확인하세요.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview
struct DdalggukWeeklyWidget_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyWidgetView(entry: WeeklyEntry(
            date: Date(),
            dateRange: "04.14. ~ 04.20.",
            days: [
                .init(drunkLevel: 30, hasRecords: true, isFuture: false),
                .init(drunkLevel: 0, hasRecords: true, isFuture: false),
                .init(drunkLevel: 60, hasRecords: true, isFuture: false),
                .init(drunkLevel: 0, hasRecords: false, isFuture: false),
                .init(drunkLevel: 40, hasRecords: true, isFuture: false),
                .init(drunkLevel: 0, hasRecords: false, isFuture: true),
                .init(drunkLevel: 0, hasRecords: false, isFuture: true),
            ],
            soberDays: 2,
            drinkingDays: 3
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
