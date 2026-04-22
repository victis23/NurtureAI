import Foundation

extension TimeInterval {
    /// Human-readable short duration, e.g. "2h 15m", "45m", "30s"
    var shortDuration: String {
        let total = Int(self)
        let hours = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60

        if hours > 0 {
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        } else if mins > 0 {
            return "\(mins)m"
        } else {
            return "\(secs)s"
        }
    }
}

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var relativeDisplay: String {
        if isToday {
            return formatted(date: .omitted, time: .shortened)
        } else if isYesterday {
            return "Yesterday " + formatted(date: .omitted, time: .shortened)
        } else {
            return formatted(date: .abbreviated, time: .shortened)
        }
    }
}
