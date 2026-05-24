import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query private var allActivities: [DailyActivity]
    @AppStorage("dailyGoal") private var dailyGoal: Int = 15

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Ostatnie dni"), footer: Text("Dzień zaliczony jeśli liczba \"zapamiętanych\" >= celu dziennego. Jeśli w danym dniu nie osiągniesz celu — seria spada do zera.")) {
                    ForEach(recentDays(), id: \.self.date) { item in
                        HStack {
                            Text(item.dateLabel)
                            Spacer()
                            Text("\(item.count)")
                                .foregroundColor(item.count >= dailyGoal ? .green : .secondary)
                        }
                    }
                }
            }
            .navigationTitle("Statystyki")
        }
    }

    private func recentDays() -> [(date: String, dateLabel: String, count: Int)] {
        var result: [(String, String, Int)] = []
        let calendar = Calendar.current
        let dict = Dictionary(uniqueKeysWithValues: allActivities.map { ($0.dateString, $0.count) })
        
        for offset in (0..<14).reversed() { // Ostatnie 14 dni
            if let date = calendar.date(byAdding: .day, value: -offset, to: Date()) {
                let key = DateFormatter.yyyyMMdd.string(from: date)
                let label = DateFormatter.mediumDate.string(from: date)
                let count = dict[key] ?? 0
                result.append((key, label, count))
            }
        }
        return result
    }
}
