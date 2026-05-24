import SwiftUI
import SwiftData

struct TypingStudySessionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State var cards: [Flashcard]
    @State private var currentIndex = 0
    @State private var userAnswer = ""
    @State private var showFeedback = false
    @State private var wasCorrect = false

    var progress: Double {
        guard !cards.isEmpty else { return 1.0 }
        return Double(currentIndex) / Double(cards.count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .primary))
                    .padding(.horizontal)
                    .padding(.top)

                Spacer()

                if currentIndex < cards.count {
                    let card = cards[currentIndex]
                    VStack(spacing: 16) {
                        Text("Przetłumacz na włoski:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(card.back)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        TextField("Wpisz po włosku...", text: $userAnswer)
                            .textFieldStyle(.roundedBorder)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
#endif

                        if showFeedback {
                            HStack(spacing: 8) {
                                Image(systemName: wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(wasCorrect ? .green : .red)
                                Text(wasCorrect ? "Dobrze!" : "Poprawna odpowiedź: \(card.front)")
                                    .foregroundColor(wasCorrect ? .green : .red)
                            }
                        }

                        HStack(spacing: 12) {
                            Button(action: { submit(answerIsCorrect: false) }) {
                                Text("Pomiń")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.secondary.opacity(0.15))
                                    .foregroundColor(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { checkAnswer() }) {
                                Text("Sprawdź")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.primary)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        Text("Koniec na dzisiaj!")
                            .font(.title)
                            .bold()
                        
                        Button(action: { dismiss() }) {
                            Text("Zakończ")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
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
                    .buttonStyle(.plain)
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

    private func checkAnswer() {
        let card = cards[currentIndex]
        let normalizedUser = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedCorrect = card.front.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correct = normalizedUser == normalizedCorrect
        submit(answerIsCorrect: correct)
    }

    private func submit(answerIsCorrect: Bool) {
        showFeedback = true
        wasCorrect = answerIsCorrect

        let card = cards[currentIndex]
        let quality: ReviewQuality = answerIsCorrect ? .good : .again
        SRSAlgorithm.processReview(for: card, quality: quality)

        // Zaliczenie do statystyk TYLKO przy stuprocentowo poprawnej odpowiedzi
        if answerIsCorrect {
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
        }
        
        try? modelContext.save()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
                userAnswer = ""
                showFeedback = false
            }
        }
    }
}
