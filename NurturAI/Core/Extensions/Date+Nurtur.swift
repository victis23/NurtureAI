import Foundation

extension Date {

    var relativeDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: .now)
    }

    var timeDisplay: String {
        formatted(date: .omitted, time: .shortened)
    }

    var shortDateTimeDisplay: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Today \(timeDisplay)"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday \(timeDisplay)"
        } else {
            return formatted(date: .abbreviated, time: .shortened)
        }
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func minutesAgo() -> Int {
        Int(Date().timeIntervalSince(self)) / 60
    }

    static func hoursAgo(_ hours: Double) -> Date {
        Date().addingTimeInterval(-hours * 3600)
    }
}
