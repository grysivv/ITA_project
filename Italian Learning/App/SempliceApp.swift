import SwiftUI
import SwiftData

@main
struct SempliceApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Flashcard.self,
            DailyActivity.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Nie można utworzyć ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }
            
            LibraryView()
                .tabItem { Label("Kolekcja", systemImage: "rectangle.stack.fill") }
            
            StatisticsView()
                .tabItem { Label("Statystyki", systemImage: "chart.bar.fill") }
            
            SettingsView()
                .tabItem { Label("Ustawienia", systemImage: "gearshape.fill") }
        }
        .tint(.primary)
    }
}
