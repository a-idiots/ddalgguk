import SwiftUI
import WidgetKit

// MARK: - Shared constants
// Keep in sync with lib/features/profile/data/services/goal_home_widget_service.dart
private let appGroupId = "group.com.aidiot.ddalgguk"
private let kHasGoal = "has_goal"
private let kMonthNum = "month_num"
private let kGoalBudget = "goal_budget"
private let kHasBudget = "has_budget"
private let kGoalAlcohol = "goal_alcohol"
private let kHasAlcohol = "has_alcohol"
private let kCurrentSpending = "current_spending"
private let kCurrentAlcohol = "current_alcohol"

// home_widget writes keys to the App Group UserDefaults verbatim
// (no "flutter." prefix — that's shared_preferences, not home_widget).
private let flutterPrefix = ""

// MARK: - Entry
struct GoalEntry: TimelineEntry {
    let date: Date
    let hasGoal: Bool
    let monthNum: Int
    let hasBudget: Bool
    let budget: Int
    let currentSpending: Int
    let hasAlcohol: Bool
    let alcoholGoal: Double
    let currentAlcohol: Double
}

// MARK: - Provider
struct GoalProvider: TimelineProvider {
    func placeholder(in context: Context) -> GoalEntry {
        GoalEntry(
            date: Date(),
            hasGoal: true,
            monthNum: Calendar.current.component(.month, from: Date()),
            hasBudget: true,
            budget: 300_000,
            currentSpending: 120_000,
            hasAlcohol: true,
            alcoholGoal: 8,
            currentAlcohol: 3.5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalEntry>) -> Void) {
        let entry = readEntry()
        // Refresh every hour; the Flutter app triggers an immediate update
        // via WidgetCenter whenever the user changes their goal or logs a drink.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func readEntry() -> GoalEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let now = Date()
        let monthNum = defaults?.integer(forKey: flutterPrefix + kMonthNum)
            ?? Calendar.current.component(.month, from: now)
        let hasGoal = defaults?.bool(forKey: flutterPrefix + kHasGoal) ?? false
        let hasBudget = defaults?.bool(forKey: flutterPrefix + kHasBudget) ?? false
        let hasAlcohol = defaults?.bool(forKey: flutterPrefix + kHasAlcohol) ?? false
        let budget = defaults?.integer(forKey: flutterPrefix + kGoalBudget) ?? 0
        let alcoholGoal = defaults?.double(forKey: flutterPrefix + kGoalAlcohol) ?? 0
        let currentSpending = defaults?.integer(forKey: flutterPrefix + kCurrentSpending) ?? 0
        let currentAlcohol = defaults?.double(forKey: flutterPrefix + kCurrentAlcohol) ?? 0

        return GoalEntry(
            date: now,
            hasGoal: hasGoal,
            monthNum: monthNum == 0 ? Calendar.current.component(.month, from: now) : monthNum,
            hasBudget: hasBudget,
            budget: budget,
            currentSpending: currentSpending,
            hasAlcohol: hasAlcohol,
            alcoholGoal: alcoholGoal,
            currentAlcohol: currentAlcohol
        )
    }
}

// MARK: - Palette
private enum Palette {
    static let primaryPink = Color(red: 0xF2 / 255, green: 0x7B / 255, blue: 0x7B / 255)
    static let budgetBar = Color(red: 0xF7 / 255, green: 0xB6 / 255, blue: 0xB6 / 255)
    static let alcoholBar = Color(red: 0xAD / 255, green: 0xE4 / 255, blue: 0xC3 / 255)
    static let barBackground = Color(white: 0.92)
    static let overGoal = Color(red: 0xEF / 255, green: 0x55 / 255, blue: 0x50 / 255)
    static let dividerGray = Color(red: 0xEE / 255, green: 0xEE / 255, blue: 0xEE / 255)
    static let textPrimary = Color.black.opacity(0.87)
    static let textSecondary = Color.black.opacity(0.55)
    static let textDisabled = Color.black.opacity(0.38)
}

// MARK: - Formatters
private func formatWon(_ v: Int) -> String {
    let nf = NumberFormatter()
    nf.numberStyle = .decimal
    nf.groupingSeparator = ","
    return (nf.string(from: NSNumber(value: v)) ?? "\(v)") + "원"
}

private func formatBottle(_ v: Double) -> String {
    if v == v.rounded() {
        return "\(Int(v))병"
    }
    return String(format: "%.1f병", v)
}

// MARK: - Views
struct GoalBarRow: View {
    let label: String
    let markerText: String
    let ratio: Double
    let isOverGoal: Bool
    let barColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Palette.textPrimary)
                Spacer()
                Text(markerText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isOverGoal ? Palette.overGoal : barColor.darker())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Palette.barBackground)
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOverGoal ? Palette.overGoal : barColor)
                        .frame(
                            width: max(0, min(geo.size.width, geo.size.width * CGFloat(ratio))),
                            height: 7
                        )
                }
            }
            .frame(height: 7)
        }
    }
}

private extension Color {
    func darker(_ amount: Double = 0.35) -> Color {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let k = 1 - CGFloat(amount)
        return Color(red: Double(r * k), green: Double(g * k), blue: Double(b * k), opacity: Double(a))
    }
}

struct GoalWidgetView: View {
    let entry: GoalEntry

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(entry.monthNum)월달 음주 잔고")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Palette.textPrimary)
                Spacer()
                Image(systemName: "arrow.forward")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Palette.textSecondary)
            }

            if !entry.hasGoal {
                emptyState
                Spacer(minLength: 0)
            } else {
                goalBody
            }
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "ddalgguk://goal"))

        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(Color.white, for: .widget)
        } else {
            content.background(Color.white)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            disabledBar(label: "예산")
            disabledBar(label: "음주량")
            Text("목표를 설정해보세요")
                .font(.system(size: 11))
                .foregroundColor(Palette.textDisabled)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
        }
    }

    private func disabledBar(label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Palette.textDisabled)
            RoundedRectangle(cornerRadius: 4)
                .fill(Palette.barBackground)
                .frame(height: 7)
        }
    }

    private var goalBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            if entry.hasBudget {
                GoalBarRow(
                    label: "예산",
                    markerText: formatWon(entry.currentSpending),
                    ratio: entry.budget > 0
                        ? min(1.0, Double(entry.currentSpending) / Double(entry.budget))
                        : 0,
                    isOverGoal: entry.currentSpending > entry.budget,
                    barColor: Palette.budgetBar
                )
            }
            if entry.hasAlcohol {
                GoalBarRow(
                    label: "음주량",
                    markerText: formatBottle(entry.currentAlcohol),
                    ratio: entry.alcoholGoal > 0
                        ? min(1.0, entry.currentAlcohol / entry.alcoholGoal)
                        : 0,
                    isOverGoal: entry.currentAlcohol > entry.alcoholGoal,
                    barColor: Palette.alcoholBar
                )
                .padding(.top, 4)
            }

            Spacer(minLength: 0)

            Divider().background(Palette.dividerGray)

            summaryRow
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 10) {
            if entry.hasBudget {
                let over = entry.currentSpending > entry.budget
                let remaining = entry.budget - entry.currentSpending
                summaryCell(
                    dot: over ? Palette.overGoal.opacity(0.5) : Palette.budgetBar.opacity(0.6),
                    label: "잔액",
                    value: over
                        ? "\(formatWon(-remaining)) 초과"
                        : formatWon(remaining),
                    overGoal: over
                )
            }
            if entry.hasAlcohol {
                let goalTenths = Int((entry.alcoholGoal * 10).rounded())
                let currentTenths = Int((entry.currentAlcohol * 10).rounded())
                let diff = currentTenths - goalTenths
                let over = diff > 0
                summaryCell(
                    dot: over ? Palette.overGoal.opacity(0.5) : Palette.alcoholBar.opacity(0.7),
                    label: "잔여 음주량",
                    value: over
                        ? "\(formatBottle(Double(diff) / 10.0)) 초과"
                        : formatBottle(Double(-diff) / 10.0),
                    overGoal: over
                )
            }
        }
    }

    private func summaryCell(dot: Color, label: String, value: String, overGoal: Bool) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(dot)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Palette.textSecondary)
                .lineLimit(1)
            Spacer(minLength: 2)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(overGoal ? Palette.overGoal : Palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget
struct DdalggukGoalWidget: Widget {
    let kind: String = "DdalggukGoalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoalProvider()) { entry in
            GoalWidgetView(entry: entry)
        }
        .configurationDisplayName("음주 잔고")
        .description("이번 달 예산과 음주량 목표를 한눈에 확인하세요.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview
struct DdalggukGoalWidget_Previews: PreviewProvider {
    static var previews: some View {
        GoalWidgetView(entry: GoalEntry(
            date: Date(),
            hasGoal: true,
            monthNum: 4,
            hasBudget: true,
            budget: 300_000,
            currentSpending: 180_000,
            hasAlcohol: true,
            alcoholGoal: 8,
            currentAlcohol: 5.5
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
