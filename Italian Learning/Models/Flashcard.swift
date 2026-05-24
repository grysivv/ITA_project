import Foundation
import SwiftData

@Model
final class Flashcard {
    var front: String
    var back: String
    var example: String?
    var notes: String?
    var category: String? 

    var repetitions: Int = 0
    var interval: Int = 0
    var easeFactor: Double = 2.5
    var nextReviewDate: Date = Date()

    var creationDate: Date = Date()

    init(front: String, back: String, example: String? = nil, notes: String? = nil, category: String? = nil) {
        self.front = front
        self.back = back
        self.example = example
        self.notes = notes
        self.category = category
    }
}
