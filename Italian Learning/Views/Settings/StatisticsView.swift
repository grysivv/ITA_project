import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query private var allActivities: [DailyActivity]
    @Query private var allCards: [Flashcard]
    @AppStorage("dailyGoal") private var dailyGoal: Int = 15

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Ostatnie 7 dni"), footer: Text("Dzień zaliczony jeśli liczba poprawnych odpowiedzi osiągnie cel dzienny.")) {
                    Chart {
                        ForEach(last7Days(), id: \.dateStr) { item in
                            BarMark(
                                x: .value("Dzień", item.label),
                                y: .value("Odpowiedzi", item.count)
                            )
                            .foregroundStyle(item.count >= dailyGoal ? Color.green.gradient : Color.orange.gradient)
                            .annotation(position: .top) {
                                Text("\(item.count)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        RuleMark(y: .value("Cel", dailyGoal))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .foregroundStyle(.red.opacity(0.8))
                            .annotation(position: .top, alignment: .leading) {
                                Text("Cel")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                    }
                    .frame(height: 220)
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Heatmapa (ostatnie 30 dni)"), footer: Text("Im ciemniejszy kolor, tym bliżej do realizacji dziennego celu.")) {
                    HeatmapView(activities: allActivities, dailyGoal: dailyGoal)
                        .padding(.vertical, 8)
                }
                
                Section(header: Text("Czas i Zaangażowanie")) {
                    HStack {
                        Text("Czas nauki (7 dni)")
                        Spacer()
                        Text(formatFullTime(last7Days().reduce(0) { $0 + $1.studyTime }))
                            .fontWeight(.bold)
                    }
                    HStack {
                        Text("Średnio dziennie")
                        Spacer()
                        Text(formatFullTime(last7Days().reduce(0) { $0 + $1.studyTime } / 7))
                            .fontWeight(.bold)
                    }
                }
                
                Section(header: Text("Podsumowanie bazy")) {
                    HStack {
                        Text("Wszystkie fiszki")
                        Spacer()
                        Text("\(allCards.count)")
                            .fontWeight(.bold)
                    }
                    HStack {
                        Text("W trakcie nauki")
                        Spacer()
                        Text("\(allCards.filter { $0.repetitions > 0 }.count)")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    HStack {
                        Text("Nienauczone")
                        Spacer()
                        Text("\(allCards.filter { $0.repetitions == 0 }.count)")
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Statystyki")
        }
    }
    
    private func formatFullTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes) min"
    }

    private func last7Days() -> [(dateStr: String, label: String, count: Int, studyTime: Double)] {
        var result: [(String, String, Int, Double)] = []
        let calendar = Calendar.current
        let dict = Dictionary(uniqueKeysWithValues: allActivities.map { ($0.dateString, $0) })
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        for offset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -offset, to: Date()) {
                let key = DateFormatter.yyyyMMdd.string(from: date)
                let label = formatter.string(from: date)
                let count = dict[key]?.count ?? 0
                let studyTime = dict[key]?.studyTime ?? 0.0
                result.append((key, label, count, studyTime))
            }
        }
        return result
    }
}

// Pozostała struktura "HeatmapView" bez zmian (skrócona z powodu przejrzystości, ale w projekcie ją zostaw)
struct HeatmapView: View {
    var activities: [DailyActivity]
    var dailyGoal: Int
    
    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(last30Days(), id: \.dateStr) { day in
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(colorFor(count: day.count))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Text("\(day.dayNumber)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(day.count > 0 ? .white : .primary.opacity(0.4))
                    )
            }
        }
    }
    
    private func colorFor(count: Int) -> Color {
        if count == 0 {
            return Color.secondary.opacity(0.15)
        } else if count < dailyGoal {
            return .orange.opacity(0.7)
        } else {
            return .green.opacity(0.9)
        }
    }
    
    private func last30Days() -> [(dateStr: String, dayNumber: String, count: Int)] {
        var result: [(String, String, Int)] = []
        let calendar = Calendar.current
        let dict = Dictionary(uniqueKeysWithValues: activities.map { ($0.dateString, $0.count) })
        for offset in (0..<35).reversed() {
            if let date = calendar.date(byAdding: .day, value: -offset, to: Date()) {
                let key = DateFormatter.yyyyMMdd.string(from: date)
                let dayNum = String(calendar.component(.day, from: date))
                let count = dict[key] ?? 0
                result.append((key, dayNum, count))
            }
        }
        return result
    }
}
