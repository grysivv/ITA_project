import Foundation

enum ReviewQuality: Int {
    case again = 0
    case hard = 1
    case good = 2
}

struct SRSAlgorithm {
    static func processReview(for card: Flashcard, quality: ReviewQuality) {
        let now = Date()
        
        switch quality {
        case .again:
            card.repetitions = 0
            card.interval = 0
            card.nextReviewDate = now
            
        case .hard:
            card.interval = 1
            card.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
            
        case .good:
            if card.repetitions == 0 {
                card.interval = 3
            } else if card.repetitions == 1 {
                card.interval = 7
            } else {
                card.interval = Int(round(Double(card.interval) * card.easeFactor))
            }
            card.repetitions += 1
            card.nextReviewDate = Calendar.current.date(byAdding: .day, value: card.interval, to: now) ?? now
        }
    }
}
