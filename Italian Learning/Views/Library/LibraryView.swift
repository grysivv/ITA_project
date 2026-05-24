import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Flashcard.creationDate, order: .reverse) private var allCards: [Flashcard]
    
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var editingCard: Flashcard? = nil
    
    var filteredCards: [Flashcard] {
        if searchText.isEmpty { return allCards }
        return allCards.filter { $0.front.localizedCaseInsensitiveContains(searchText) || $0.back.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCards) { card in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.front)
                            .font(.headline)
                        Text(card.back)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing) {
                        Button("Edytuj") {
                            editingCard = card
                        }
                        .tint(.blue)
                    }
                }
                .onDelete(perform: deleteCards)
            }
            .navigationTitle("Twoje Fiszki")
            .searchable(text: $searchText, prompt: "Szukaj słówka...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddFlashcardView()
            }
            .sheet(item: $editingCard) { card in
                EditFlashcardView(card: card)
            }
        }
    }
    
    private func deleteCards(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredCards[index])
            }
        }
    }
}

struct AddFlashcardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var front = ""
    @State private var back = ""
    @State private var example = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Główne")) {
                    TextField("Włoski (np. la mela)", text: $front)
                        .font(.title3)
                    TextField("Tłumaczenie (np. jabłko)", text: $back)
                }
                
                Section(header: Text("Dodatkowe (Opcjonalnie)")) {
                    TextField("Przykładowe zdanie...", text: $example, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Nowa fiszka")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") {
                        saveCard()
                    }
                    .disabled(front.trimmingCharacters(in: .whitespaces).isEmpty || back.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveCard() {
        let newCard = Flashcard(front: front, back: back, example: example.isEmpty ? nil : example)
        modelContext.insert(newCard)
        dismiss()
    }
}
