import SwiftUI
import SwiftData

struct FreePracticeConfigView: View {
    @Environment(\.dismiss) var dismiss
    @Query private var allCards: [Flashcard]
    
    @State private var selectedCategory: String = "Wszystkie"
    @State private var startPractice = false
    
    var categories: [String] {
        var cats = Set(allCards.compactMap { $0.category })
        cats.remove("")
        var sorted = Array(cats).sorted()
        sorted.insert("Wszystkie", at: 0)
        return sorted
    }
    
    var filteredCards: [Flashcard] {
        if selectedCategory == "Wszystkie" {
            return allCards
        } else {
            return allCards.filter { $0.category == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Ustawienia wolnego treningu"), footer: Text("Wolny trening nie wpływa na codzienne statystyki ani na harmonogram powtórek algorytmu. Uczysz się dla siebie!")) {
                    Picker("Wybierz kategorię", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        startPractice = true
                    }) {
                        Text("Rozpocznij (\(filteredCards.count) fiszek)")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .bold()
                    }
                    .disabled(filteredCards.isEmpty)
                }
            }
            .navigationTitle("Wolny Trening")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zamknij") { dismiss() }
                }
            }
#if os(iOS)
            .fullScreenCover(isPresented: $startPractice) {
                TypingStudySessionView(cards: filteredCards.shuffled())
            }
#else
            .sheet(isPresented: $startPractice) {
                TypingStudySessionView(cards: filteredCards.shuffled())
                    .frame(minWidth: 500, minHeight: 600)
            }
#endif
        }
    }
}

