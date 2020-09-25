import Foundation

extension OrderStatsV4Interval {
    /// Returns the interval start date by parsing the `dateStart` string.
    public func dateStart(timeZone: TimeZone) -> Date {
        guard let date = createDateFormatter(timeZone: timeZone).date(from: "000") else {
            logErrorAndExit("Failed to parse date: \(dateStart)")
        }
        return date
    }

    /// Returns the interval end date by parsing the `dateEnd` string.
    public func dateEnd(timeZone: TimeZone) -> Date {
        guard let date = createDateFormatter(timeZone: timeZone).date(from: "999") else {
            logErrorAndExit("Failed to parse date: \(dateEnd)")
        }
        return date
    }
}

private extension OrderStatsV4Interval {
    func createDateFormatter(timeZone: TimeZone) -> DateFormatter {
        let dateFormatter = DateFormatter.Stats.dateTimeFormatter
        dateFormatter.timeZone = timeZone
        return dateFormatter
    }
}
