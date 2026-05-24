import Foundation
import SwiftData

@Model
final class DailyActivity {
    var dateString: String
    var count: Int = 0
    
    init(dateString: String, count: Int = 0) {
        self.dateString = dateString
        self.count = count
    }
}
