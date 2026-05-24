import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Optymalizacja #1: Zapytanie filtrujące tylko to, co potrzebne na dzisiaj.
    @Query private var dueCards: [Flashcard]
    @AppStorage("dailyGoal") private var dailyGoal: Int = 15
    
    // Optymalizacja #2: Stan wyliczany raz, aby nie obciążać odświeżania widoku
    @State private var poznaneCount: Int = 0
    @State private var todayCount: Int = 0
    @State private var seriaCount: Int = 0
    
    @State private var isStudying = false
    @State private var isTypingMode = false

    init() {
        let now = Date()
        let predicate = #Predicate<Flashcard> { card in
            card.nextReviewDate <= now
        }
        _dueCards = Query(filter: predicate, sort: \.nextReviewDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ciao!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("Czas na codzienną dawkę włoskiego.")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.top)

                    // Hero Card (Powtórki)
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Do powtórki")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("\(dueCards.count)")
                                    .font(.system(size: 64, weight: .semibold, design: .rounded))
                            }
                            Spacer()
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 50))
                                .foregroundColor(.accentColor.opacity(0.8))
                        }
                        
                        Button(action: { isStudying = true }) {
                            Text(dueCards.isEmpty ? "Wszystko zrobione!" : "Rozpocznij naukę")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(dueCards.isEmpty ? Color.gray.opacity(0.3) : Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(dueCards.isEmpty)
                        
                        Button(action: { isTypingMode = true }) {
                            Text("Tryb wpisywania")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(dueCards.isEmpty)
                    }
                    .padding(24)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    
                    // Szybkie statystyki
                    HStack(spacing: 16) {
                        StatCard(title: "Seria", value: "\(seriaCount) dni", icon: "flame.fill", color: .orange)
                        StatCard(title: "Poznane", value: "\(poznaneCount)", icon: "checkmark.seal.fill", color: .green)
                    }
                    
                    // Cel na dzisiaj
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Dzisiejszy cel (seria)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(todayCount) / \(dailyGoal)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: min(Double(todayCount), Double(dailyGoal)), total: Double(dailyGoal))
                            .progressViewStyle(LinearProgressViewStyle(tint: todayCount >= dailyGoal ? .green : .orange))
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .background(Color.primary.opacity(0.03).ignoresSafeArea())
            .onAppear { calculateStats() }
            .onChange(of: dailyGoal) { _, _ in calculateStats() }
#if os(iOS)
            .fullScreenCover(isPresented: $isStudying, onDismiss: { calculateStats() }) {
                StudySessionView(cards: Array(dueCards))
            }
            .fullScreenCover(isPresented: $isTypingMode, onDismiss: { calculateStats() }) {
                TypingStudySessionView(cards: Array(dueCards))
            }
#else
            .sheet(isPresented: $isStudying, onDismiss: { calculateStats() }) {
                StudySessionView(cards: Array(dueCards))
                    .frame(minWidth: 400, minHeight: 500)
            }
            .sheet(isPresented: $isTypingMode, onDismiss: { calculateStats() }) {
                TypingStudySessionView(cards: Array(dueCards))
                    .frame(minWidth: 400, minHeight: 500)
            }
#endif
        }
    }
    
    private func calculateStats() {
        let todayStr = DateFormatter.yyyyMMdd.string(from: Date())
        
        // Optymalizacja: POBRANIE SAMEJ LICZBY (zamiast ściągania całej bazy do pamięci)
        let poznaneDescriptor = FetchDescriptor<Flashcard>(predicate: #Predicate { $0.repetitions > 0 })
        poznaneCount = (try? modelContext.fetchCount(poznaneDescriptor)) ?? 0
        
        let todayDescriptor = FetchDescriptor<DailyActivity>(predicate: #Predicate { $0.dateString == todayStr })
        todayCount = (try? modelContext.fetch(todayDescriptor))?.first?.count ?? 0
        
        let allActDescriptor = FetchDescriptor<DailyActivity>()
        if let allActivities = try? modelContext.fetch(allActDescriptor) {
            let calendar = Calendar.current
            let activityDict = Dictionary(uniqueKeysWithValues: allActivities.map { ($0.dateString, $0) })
            
            var currentStreak = 0
            var checkDate = Date()
            
            if (activityDict[todayStr]?.count ?? 0) >= dailyGoal {
                currentStreak += 1
            }
            
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            while true {
                let dateStr = DateFormatter.yyyyMMdd.string(from: checkDate)
                if let act = activityDict[dateStr], act.count >= dailyGoal {
                    currentStreak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                } else {
                    break
                }
            }
            seriaCount = currentStreak
        }
    }
}
