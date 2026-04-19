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

// MARK: - Saku image name from drunk level (matches getBodyImagePath in drink_helpers.dart)
private func sakuImageName(for drunkLevel: Int) -> String {
    let clamped = max(0, min(drunkLevel, 100))
    let level = (clamped / 10) * 10
    return "saku_\(String(format: "%02d", level))"
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
}

// MARK: - Saku character view (body + eyes overlay)
private struct SakuCharacterView: View {
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

// MARK: - Views
struct WeeklyWidgetView: View {
    let entry: WeeklyEntry

    private let characterSize: CGFloat = 36

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 4) {
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

            // 7-day Saku row
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    dayColumn(index: i)
                    if i < 6 {
                        Spacer(minLength: 0)
                    }
                }
            }

            Spacer(minLength: 0)
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

        return VStack(spacing: 4) {
            Text(dayLabels[index])
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(
                    index >= 5
                        ? WPalette.textSecondary
                        : WPalette.textPrimary
                )

            if day.isFuture {
                // Future: future_date image
                Image("future_date")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: characterSize, height: characterSize)
            } else if day.hasRecords {
                // Has records: Saku character with drunk level color + eyes
                SakuCharacterView(drunkLevel: day.drunkLevel, size: characterSize)
            } else {
                // No record: empty_date (grey) + eyes
                ZStack {
                    Image("empty_date")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: characterSize, height: characterSize)
                    Image("saku_eyes")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: characterSize * 0.3, height: characterSize * 0.3)
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
