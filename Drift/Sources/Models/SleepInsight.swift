import Foundation

struct SleepInsight: Identifiable, Codable {
    let id: UUID
    let text: String
    let isPositive: Bool
    let date: Date

    init(id: UUID = UUID(), text: String, isPositive: Bool, date: Date = Date()) {
        self.id = id
        self.text = text
        self.isPositive = isPositive
        self.date = date
    }
}
