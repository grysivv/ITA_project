import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("dailyGoal") private var dailyGoal: Int = 15
    @AppStorage("showPolishOnFront") private var showPolishOnFront: Bool = true
    
    @State private var isImportingCSV = false
    @State private var showCSVTemplate = false
    @State private var csvTemplateText: String = "front,back,example,notes\nla mela,jabłko,La mela è rossa.,\nciao,cześć,,\n"
    
    @State private var showDeleteAllAlert = false
    @State private var showDeleteActivitiesAlert = false
    @State private var isProcessingCSV = false // Wskaźnik ładowania zoptymalizowanego

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Cel dzienny")) {
                    Stepper(value: $dailyGoal, in: 1...200) {
                        HStack {
                            Text("Ustaw cel dzienny")
                            Spacer()
                            Text("\(dailyGoal) słówek")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Wygląd fiszek")) {
                    Toggle(isOn: $showPolishOnFront) {
                        Text("Przód karty: Polski")
                    }
                }

                Section(header: Text("Import CSV"), footer: Text("Format: front,back,example,notes")) {
                    Button { showCSVTemplate = true } label: {
                        Label("Pokaż szablon CSV", systemImage: "doc.text")
                    }
                    
                    if isProcessingCSV {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Importowanie danych...")
                        }
                    } else {
                        Button { isImportingCSV = true } label: {
                            Label("Importuj CSV", systemImage: "square.and.arrow.down")
                        }
                    }
                }

                Section(header: Text("Baza danych")) {
                    Button(role: .destructive) { showDeleteAllAlert = true } label: {
                        Label("Usuń wszystkie fiszki", systemImage: "trash.fill")
                    }
                    Button(role: .destructive) { showDeleteActivitiesAlert = true } label: {
                        Label("Wyczyść historię aktywności", systemImage: "calendar.badge.exclamationmark")
                    }
                }
            }
            .navigationTitle("Ustawienia")
            .alert("Usunąć wszystkie fiszki?", isPresented: $showDeleteAllAlert) {
                Button("Anuluj", role: .cancel) {}
                Button("Usuń", role: .destructive) { deleteAllFlashcards() }
            }
            .alert("Wyczyścić historię?", isPresented: $showDeleteActivitiesAlert) {
                Button("Anuluj", role: .cancel) {}
                Button("Wyczyść", role: .destructive) { deleteAllActivities() }
            }
            .fileImporter(isPresented: $isImportingCSV, allowedContentTypes: [.commaSeparatedText]) { result in
                switch result {
                case .success(let url): importCSV(from: url)
                case .failure: break
                }
            }
            .sheet(isPresented: $showCSVTemplate) {
                NavigationStack {
                    ScrollView { Text(csvTemplateText).monospaced().padding() }
                        .navigationTitle("Szablon CSV")
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button("Zamknij") { showCSVTemplate = false }
                            }
                        }
                }
            }
        }
    }

    private func deleteAllFlashcards() {
        let descriptor = FetchDescriptor<Flashcard>()
        if let cards = try? modelContext.fetch(descriptor) {
            cards.forEach { modelContext.delete($0) }
            try? modelContext.save()
        }
    }

    private func deleteAllActivities() {
        let descriptor = FetchDescriptor<DailyActivity>()
        if let activities = try? modelContext.fetch(descriptor) {
            activities.forEach { modelContext.delete($0) }
            try? modelContext.save()
        }
    }

    private func importCSV(from url: URL) {
        isProcessingCSV = true
        
        // Optymalizacja: Uruchomienie parsowania tekstów w tle, żeby nie mrozić aplikacji
        Task {
            guard let data = try? Data(contentsOf: url),
                  var content = String(data: data, encoding: .utf8) else {
                await MainActor.run { isProcessingCSV = false }
                return
            }
            
            content = content.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
            let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
            guard lines.count > 1 else {
                await MainActor.run { isProcessingCSV = false }
                return
            }
            
            let rows = lines.dropFirst()
            var parsedCards: [(String, String, String?, String?)] = []
            
            for row in rows {
                let cols = row.split(separator: ",", omittingEmptySubsequences: false)
                if cols.count >= 2 {
                    let front = String(cols[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let back = String(cols[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let example = cols.count > 2 ? String(cols[2]).trimmingCharacters(in: .whitespacesAndNewlines) : nil
                    let notes = cols.count > 3 ? String(cols[3]).trimmingCharacters(in: .whitespacesAndNewlines) : nil
                    
                    if !front.isEmpty && !back.isEmpty {
                        parsedCards.append((front, back, example?.isEmpty == true ? nil : example, notes?.isEmpty == true ? nil : notes))
                    }
                }
            }
            
            // Bezpieczny powrót na główny wątek, by dokonać wstawienia do bazy (ModelContext nie jest współbieżny)
            await MainActor.run {
                let descriptor = FetchDescriptor<Flashcard>()
                let existing = (try? modelContext.fetch(descriptor)) ?? []
                var existingSet = Set(existing.map { "\($0.front.lowercased())|\($0.back.lowercased())" })
                
                var inserted = 0
                for (front, back, example, notes) in parsedCards {
                    let key = "\(front.lowercased())|\(back.lowercased())"
                    if !existingSet.contains(key) {
                        let card = Flashcard(front: front, back: back, example: example, notes: notes)
                        modelContext.insert(card)
                        existingSet.insert(key)
                        inserted += 1
                    }
                }
                if inserted > 0 { try? modelContext.save() }
                isProcessingCSV = false
            }
        }
    }
}
