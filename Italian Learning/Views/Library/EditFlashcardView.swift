import SwiftUI
import SwiftData

struct EditFlashcardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @Bindable var card: Flashcard
    @Query private var allCards: [Flashcard]
    
    var isKnown: Bool { card.repetitions > 0 }
    
    var existingCategories: [String] {
        let cats = allCards.compactMap { $0.category }.filter { !$0.isEmpty }
        return Array(Set(cats)).sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WŁOSKI").font(.caption).foregroundColor(.secondary).bold()
                        TextField("Słówko", text: $card.front).font(.title2.bold())
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("POLSKI").font(.caption).foregroundColor(.secondary).bold()
                        TextField("Tłumaczenie", text: $card.back).font(.title3)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("KONTEKST I KATEGORIA").font(.caption).foregroundColor(.secondary)) {
                    TextField("Przykładowe zdanie...", text: Binding(
                        get: { card.example ?? "" },
                        set: { card.example = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Kategoria (np. Czasowniki)", text: Binding(
                            get: { card.category ?? "" },
                            set: { card.category = $0.isEmpty ? nil : $0 }
                        ))
                        
                        if !existingCategories.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(existingCategories, id: \.self) { cat in
                                        Button(action: { card.category = cat }) {
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
                
                Section {
                    Button(role: .destructive, action: resetProgress) {
                        HStack {
                            Spacer()
                            Text(isKnown ? "Zresetuj znajomość słówka" : "Słówko jeszcze nie poznane")
                            Spacer()
                        }
                    }
                    .disabled(!isKnown)
                }
            }
            .navigationTitle("Edycja")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gotowe") {
                        try? modelContext.save()
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
    
    private func resetProgress() {
        card.repetitions = 0
        card.interval = 0
        card.easeFactor = 2.5
        card.nextReviewDate = Date()
        try? modelContext.save()
    }
}
