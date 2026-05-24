import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("dailyGoal") private var dailyGoal: Int = 15
    @AppStorage("showPolishOnFront") private var showPolishOnFront: Bool = true
    
    @Query private var allCards: [Flashcard]
    
    @State private var isImportingCSV = false
    @State private var isExportingCSV = false
    @State private var csvDocument: CSVDocument?
    
    @State private var showCSVTemplate = false
    @State private var csvTemplateText: String = "front,back,example,category\nla mela,jabłko,La mela è rossa.,Jedzenie\nciao,cześć,,\n"
    
    @State private var showDeleteAllAlert = false
    @State private var showDeleteActivitiesAlert = false
    @State private var showResetProgressAlert = false
    @State private var isProcessingCSV = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Nauka").font(.caption).bold()) {
                    HStack {
                        Label("Cel dzienny", systemImage: "target")
                        Spacer()
                        Text("\(dailyGoal) słówek")
                            .foregroundColor(.secondary)
                        Stepper("", value: $dailyGoal, in: 1...200)
                            .labelsHidden()
                    }
                    
                    Toggle(isOn: $showPolishOnFront) {
                        Label("Przód karty: Polski", systemImage: "character.book.closed")
                    }
                }
                
                Section(header: Text("Import i Eksport").font(.caption).bold(), footer: Text("Format pliku: front,back,example,category")) {
                    Button {
                        showCSVTemplate = true
                    } label: {
                        Label("Pokaż szablon CSV", systemImage: "doc.text")
                    }
                    .buttonStyle(.borderless)
                    
                    if isProcessingCSV {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.trailing, 8)
                            Text("Przetwarzanie danych...")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button {
                            isImportingCSV = true
                        } label: {
                            Label("Importuj z pliku CSV", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            exportCSV()
                        } label: {
                            Label("Eksportuj do pliku CSV", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Section(header: Text("Zarządzanie bazą").font(.caption).bold(), footer: Text("Liczba fiszek w kolekcji: \(allCards.count)")) {
                    Button(role: .destructive) {
                        showResetProgressAlert = true
                    } label: {
                        Label("Zresetuj algorytm i naukę", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.borderless)
                    
                    Button(role: .destructive) {
                        showDeleteAllAlert = true
                    } label: {
                        Label("Usuń wszystkie fiszki", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                    
                    Button(role: .destructive) {
                        showDeleteActivitiesAlert = true
                    } label: {
                        Label("Wyczyść historię aktywności", systemImage: "calendar.badge.exclamationmark")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                }
            }
#if os(iOS)
            .listStyle(.insetGrouped)
#else
            .listStyle(.inset)
#endif
            .navigationTitle("Ustawienia")
            .alert("Zresetować naukę?", isPresented: $showResetProgressAlert) {
                Button("Anuluj", role: .cancel) {}
                Button("Zresetuj", role: .destructive) { resetAllProgress() }
            } message: {
                Text("Wszystkie statystyki zapamiętywania wrócą do początku dla każdej fiszki w bazie.")
            }
            .alert("Usunąć wszystkie fiszki?", isPresented: $showDeleteAllAlert) {
                Button("Anuluj", role: .cancel) {}
                Button("Usuń", role: .destructive) { deleteAllFlashcards() }
            } message: {
                Text("Tej operacji nie można cofnąć. Wszystkie słówka zostaną permanentnie usunięte z pamięci aplikacji.")
            }
            .alert("Wyczyścić historię?", isPresented: $showDeleteActivitiesAlert) {
                Button("Anuluj", role: .cancel) {}
                Button("Wyczyść", role: .destructive) { deleteAllActivities() }
            } message: {
                Text("Twoje codzienne postępy oraz statystyki sesji zostaną trwale wyzerowane.")
            }
            .fileImporter(isPresented: $isImportingCSV, allowedContentTypes: [.commaSeparatedText]) { result in
                switch result {
                case .success(let url): importCSV(from: url)
                case .failure: break
                }
            }
            .fileExporter(isPresented: $isExportingCSV, document: csvDocument, contentType: .commaSeparatedText, defaultFilename: "MojeFiszki") { _ in }
            .sheet(isPresented: $showCSVTemplate) {
                NavigationStack {
                    ScrollView {
                        Text(csvTemplateText)
                            .monospaced()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .navigationTitle("Szablon CSV")
#if os(macOS)
                    .frame(minWidth: 400, minHeight: 250)
#else
                    .navigationBarTitleDisplayMode(.inline)
#endif
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Zamknij") { showCSVTemplate = false }
                        }
                    }
                }
#if os(iOS)
                .presentationDetents([.medium, .large])
#endif
            }
        }
    }

    private func resetAllProgress() {
        for card in allCards {
            card.repetitions = 0
            card.interval = 0
            card.easeFactor = 2.5
            card.nextReviewDate = Date()
        }
        try? modelContext.save()
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

    private func exportCSV() {
        var csvString = "front,back,example,category\n"
        for card in allCards {
            let f = card.front.replacingOccurrences(of: ",", with: " ")
            let b = card.back.replacingOccurrences(of: ",", with: " ")
            let e = card.example?.replacingOccurrences(of: ",", with: " ") ?? ""
            let c = card.category?.replacingOccurrences(of: ",", with: " ") ?? ""
            
            csvString += "\(f),\(b),\(e),\(c)\n"
        }
        csvDocument = CSVDocument(text: csvString)
        isExportingCSV = true
    }

    private func importCSV(from url: URL) {
        isProcessingCSV = true
        
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
                    let category = cols.count > 3 ? String(cols[3]).trimmingCharacters(in: .whitespacesAndNewlines) : nil
                    
                    if !front.isEmpty && !back.isEmpty {
                        parsedCards.append((front, back, example?.isEmpty == true ? nil : example, category?.isEmpty == true ? nil : category))
                    }
                }
            }
            
            await MainActor.run {
                let descriptor = FetchDescriptor<Flashcard>()
                let existing = (try? modelContext.fetch(descriptor)) ?? []
                var existingSet = Set(existing.map { "\($0.front.lowercased())|\($0.back.lowercased())" })
                var inserted = 0
                for (front, back, example, category) in parsedCards {
                    let key = "\(front.lowercased())|\(back.lowercased())"
                    if !existingSet.contains(key) {
                        let card = Flashcard(front: front, back: back, example: example, category: category)
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
