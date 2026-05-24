import SwiftUI
import SwiftData

enum LibraryTab: String, CaseIterable {
    case all = "Wszystkie"
    case known = "Znane"
    case unknown = "Do nauki"
}

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Flashcard.creationDate, order: .reverse) private var allCards: [Flashcard]
    
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var editingCard: Flashcard? = nil
    
    @State private var selectedTab: LibraryTab = .all
    @State private var selectedCategory: String = "Wszystkie"
    @State private var mustHaveContext: Bool = false
    
    var categories: [String] {
        var cats = Set(allCards.compactMap { $0.category }.filter { !$0.isEmpty })
        var sorted = Array(cats).sorted()
        sorted.insert("Wszystkie", at: 0)
        return sorted
    }
    
    var filteredCards: [Flashcard] {
        var result = allCards
        
        // 1. Wyszukiwanie tekstem
        if !searchText.isEmpty {
            result = result.filter { $0.front.localizedCaseInsensitiveContains(searchText) || $0.back.localizedCaseInsensitiveContains(searchText) }
        }
        
        // 2. Filtr po zakładkach
        switch selectedTab {
        case .known:
            result = result.filter { $0.repetitions > 0 }
        case .unknown:
            result = result.filter { $0.repetitions == 0 }
        case .all:
            break
        }
        
        // 3. Filtr po kategorii
        if selectedCategory != "Wszystkie" {
            result = result.filter { $0.category == selectedCategory }
        }
        
        // 4. Filtr po kontekście
        if mustHaveContext {
            result = result.filter { let ex = $0.example ?? ""; return !ex.isEmpty }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Kolekcja", selection: $selectedTab) {
                    ForEach(LibraryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                List {
                    Section(footer: Text("Liczba wyników: \(filteredCards.count)")) {
                        ForEach(filteredCards) { card in
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(card.front)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(card.back)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if let category = card.category, !category.isEmpty {
                                    Text(category)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundColor(.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingCard = card
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Edytuj") {
                                    editingCard = card
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete(perform: deleteCards)
                    }
                }
#if os(iOS)
                .listStyle(.insetGrouped)
#endif
            }
            .navigationTitle("Twoje Fiszki")
            .searchable(text: $searchText, prompt: "Szukaj słówka...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Menu {
                            Picker("Kategoria", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat).tag(cat)
                                }
                            }
                            Toggle("Tylko z przykładem", isOn: $mustHaveContext)
                        } label: {
                            Image(systemName: selectedCategory != "Wszystkie" || mustHaveContext ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.title3)
                        }
                        
                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
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
            try? modelContext.save()
        }
    }
}

struct AddFlashcardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query private var allCards: [Flashcard]
    
    @State private var front = ""
    @State private var back = ""
    @State private var example = ""
    @State private var category = ""
    
    @FocusState private var isFrontFocused: Bool
    
    var existingCategories: [String] {
        let cats = allCards.compactMap { $0.category }.filter { !$0.isEmpty }
        return Array(Set(cats)).sorted()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Główne")) {
                    TextField("Włoski (np. la mela)", text: $front)
                        .font(.title3)
                        .focused($isFrontFocused)
                    
                    TextField("Tłumaczenie (np. jabłko)", text: $back)
                }
                
                Section(header: Text("Dodatkowe (Opcjonalnie)")) {
                    TextField("Przykładowe zdanie...", text: $example, axis: .vertical)
                        .lineLimit(3...6)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Kategoria (np. Jedzenie)", text: $category)
                        
                        if !existingCategories.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(existingCategories, id: \.self) { cat in
                                        Button(action: { category = cat }) {
                                            Text(cat)
                                                .font(.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(Color.accentColor.opacity(0.1))
                                                .foregroundColor(.accentColor)
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
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
            .onAppear {
                isFrontFocused = true
            }
        }
    }
    
    private func saveCard() {
        let newCard = Flashcard(front: front, back: back, example: example.isEmpty ? nil : example, category: category.isEmpty ? nil : category)
        modelContext.insert(newCard)
        try? modelContext.save()
        dismiss()
    }
}
