import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query private var allActivities: [DailyActivity]
    @AppStorage("dailyGoal") private var dailyGoal: Int = 15

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Heatmapa (ostatnie 30 dni)"), footer: Text("Im ciemniejszy kolor, tym bliżej do realizacji dziennego celu.")) {
                    HeatmapView(activities: allActivities, dailyGoal: dailyGoal)
                        .padding(.vertical, 8)
                }
                
                Section(header: Text("Ostatnie dni"), footer: Text("Dzień zaliczony jeśli liczba poprawnych odpowiedzi >= celu dziennego. Jeśli w danym dniu nie osiągniesz celu — seria spada do zera.")) {
                    ForEach(recentDays(), id: \.self.date) { item in
                        HStack {
                            Text(item.dateLabel)
                            Spacer()
                            Text("\(item.count) / \(dailyGoal)")
                                .foregroundColor(item.count >= dailyGoal ? .green : .secondary)
                                .fontWeight(item.count >= dailyGoal ? .bold : .regular)
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
        
        for offset in (0..<14).reversed() { // Ostatnie 14 dni z listy
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

struct HeatmapView: View {
    var activities: [DailyActivity]
    var dailyGoal: Int
    
    var body: some View {
        // Generujemy 7 kolumn (na układ bardziej klasyczny)
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
            return .orange.opacity(0.7) // Zrobione częściowo
        } else {
            return .green.opacity(0.9) // Cel osiągnięty
        }
    }
    
    private func last30Days() -> [(dateStr: String, dayNumber: String, count: Int)] {
        var result: [(String, String, Int)] = []
        let calendar = Calendar.current
        let dict = Dictionary(uniqueKeysWithValues: activities.map { ($0.dateString, $0.count) })
        
        // Generujemy bloki dla równych 35 okienek (5 pełnych tygodni) lub 30 dni. Pokażmy 35 żeby siatka była ładna.
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
