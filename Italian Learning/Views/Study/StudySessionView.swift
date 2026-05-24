import SwiftUI
import SwiftData

struct StudySessionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State var cards: [Flashcard]
    @State private var currentIndex = 0
    @State private var isFlipped = false
    
    var progress: Double {
        guard !cards.isEmpty else { return 1.0 }
        return Double(currentIndex) / Double(cards.count)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .primary))
                    .padding(.horizontal)
                    .padding(.top)
                
                Spacer()
                
                if currentIndex < cards.count {
                    FlashcardView(card: cards[currentIndex], isFlipped: $isFlipped)
                        .padding(.horizontal, 24)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isFlipped.toggle()
                            }
                        }
                    
                    Spacer()
                    
                    if isFlipped {
                        HStack(spacing: 16) {
                            StudyButton(title: "Nie umiem", color: .red) {
                                processAnswer(quality: .again)
                            }
                            StudyButton(title: "Średnio", color: .orange) {
                                processAnswer(quality: .hard)
                            }
                            StudyButton(title: "Umiem", color: .green) {
                                processAnswer(quality: .good)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        Text("Koniec na dzisiaj!")
                            .font(.title)
                            .bold()
                        Button("Zakończ") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.primary)
                    }
                    Spacer()
                }
            }
            .background(Color.primary.opacity(0.03).ignoresSafeArea())
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("\(currentIndex) / \(cards.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func processAnswer(quality: ReviewQuality) {
        let card = cards[currentIndex]
        SRSAlgorithm.processReview(for: card, quality: quality)
        
        // Zoptymalizowane użycie statycznego formatera daty
        let todayStr = DateFormatter.yyyyMMdd.string(from: Date())
        
        let descriptor = FetchDescriptor<DailyActivity>()
        if let activities = try? modelContext.fetch(descriptor) {
            if let todayActivity = activities.first(where: { $0.dateString == todayStr }) {
                todayActivity.count += 1
            } else {
                let newActivity = DailyActivity(dateString: todayStr, count: 1)
                modelContext.insert(newActivity)
            }
        }
        
        try? modelContext.save()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentIndex += 1
            isFlipped = false
        }
    }
}
