import SwiftUI
import SwiftData

struct EditFlashcardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @Bindable var card: Flashcard

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Główne")) {
                    TextField("Włoski", text: $card.front)
                        .font(.title3)
                    TextField("Polski", text: $card.back)
                }
                Section(header: Text("Dodatkowe")) {
                    TextField("Przykładowe zdanie...", text: Binding(get: { card.example ?? "" }, set: { card.example = $0.isEmpty ? nil : $0 }), axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Notatki...", text: Binding(get: { card.notes ?? "" }, set: { card.notes = $0.isEmpty ? nil : $0 }), axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edytuj fiszkę")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Anuluj") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Zapisz") { try? modelContext.save(); dismiss() } }
            }
        }
    }
}
