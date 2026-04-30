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

extension Int {
    /// Display-only formatter for a minute count: "1h 23m" when >= 60, "23m" when < 60.
    var hmDisplay: String {
        let currentValue = self
		let total = Swift.max(0, currentValue)
        let h = total / 60
        let m = total % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

