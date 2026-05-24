import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allCards: [Flashcard]
    
    var dueCards: [Flashcard] {
        let now = Date()
        return allCards.filter { $0.nextReviewDate <= now }.sorted { $0.nextReviewDate < $1.nextReviewDate }
    }
    
    @AppStorage("dailyGoal") private var dailyGoal: Int = 15
    
    @State private var poznaneCount: Int = 0
    @State private var todayCount: Int = 0
    @State private var seriaCount: Int = 0
    @State private var todayStudyTime: Double = 0.0 // Czas nauki dzisiaj
    
    @State private var isStudying = false
    @State private var isTypingMode = false
    @State private var isFreePractice = false

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
                    VStack(spacing: 16) {
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
                        .buttonStyle(.borderless)
                        
                        HStack(spacing: 12) {
                            Button(action: { isTypingMode = true }) {
                                Text("Wpisywanie")
                                    .font(.subheadline).bold()
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .disabled(dueCards.isEmpty)
                            .buttonStyle(.borderless)
                            
                            Button(action: { isFreePractice = true }) {
                                Text("Wolny Trening")
                                    .font(.subheadline).bold()
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(24)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    
                    // Szybkie statystyki
                    HStack(spacing: 12) {
                        StatCard(title: "Seria", value: "\(seriaCount) dni", icon: "flame.fill", color: .orange)
                        StatCard(title: "Czas", value: formatTime(todayStudyTime), icon: "clock.fill", color: .blue)
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
                StudySessionView(cards: dueCards, isFreePractice: false)
            }
            .fullScreenCover(isPresented: $isTypingMode, onDismiss: { calculateStats() }) {
                TypingStudySessionView(cards: dueCards, isFreePractice: false)
            }
#else
            .sheet(isPresented: $isStudying, onDismiss: { calculateStats() }) {
                StudySessionView(cards: dueCards, isFreePractice: false)
                    .frame(minWidth: 400, minHeight: 500)
            }
            .sheet(isPresented: $isTypingMode, onDismiss: { calculateStats() }) {
                TypingStudySessionView(cards: dueCards, isFreePractice: false)
                    .frame(minWidth: 400, minHeight: 500)
            }
#endif
            .sheet(isPresented: $isFreePractice) {
                FreePracticeConfigView()
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        if minutes == 0 { return "< 1 min" }
        return "\(minutes) min"
    }
    
    private func calculateStats() {
        let todayStr = DateFormatter.yyyyMMdd.string(from: Date())
        
        let poznaneDescriptor = FetchDescriptor<Flashcard>(predicate: #Predicate { $0.repetitions > 0 })
        poznaneCount = (try? modelContext.fetchCount(poznaneDescriptor)) ?? 0
        
        let allActDescriptor = FetchDescriptor<DailyActivity>()
        if let allActivities = try? modelContext.fetch(allActDescriptor) {
            let activityDict = Dictionary(uniqueKeysWithValues: allActivities.map { ($0.dateString, $0) })
            
            todayCount = activityDict[todayStr]?.count ?? 0
            todayStudyTime = activityDict[todayStr]?.studyTime ?? 0.0
            
            var currentStreak = 0
            var checkDate = Date()
            let calendar = Calendar.current
            
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
