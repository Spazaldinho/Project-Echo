import Foundation
import SwiftData

@Model
final class Event {
    var timestamp: Date
    var source: String
    var type: String
    var text: String
    var meta: String? // JSON string
    
    init(timestamp: Date = Date(), source: String, type: String, text: String, meta: String? = nil) {
        self.timestamp = timestamp
        self.source = source
        self.type = type
        self.text = text
        self.meta = meta
    }
}
