import Foundation
import SwiftData

@Model
final class DailyActivity {
    var dateString: String
    var count: Int = 0
    var studyTime: Double = 0.0 // Dodany czas nauki w sekundach
    
    init(dateString: String, count: Int = 0, studyTime: Double = 0.0) {
        self.dateString = dateString
        self.count = count
        self.studyTime = studyTime
    }
}
