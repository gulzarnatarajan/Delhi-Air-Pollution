import Foundation

extension MonthlyReading {
    /// e.g. "Aug 2026"
    var shortLabel: String {
        Self.formatter.string(from: monthDate)
    }

    /// e.g. "August 2026"
    var fullLabel: String {
        Self.fullFormatter.string(from: monthDate)
    }

    var key: String { "\(year)-\(month)" }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = .airQuality
        f.timeZone = Calendar.airQuality.timeZone
        f.dateFormat = "MMM yyyy"
        return f
    }()

    private static let fullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = .airQuality
        f.timeZone = Calendar.airQuality.timeZone
        f.dateFormat = "MMMM yyyy"
        return f
    }()
}

extension CityData {
    func reading(year: Int, month: Int) -> MonthlyReading? {
        readings.first { $0.year == year && $0.month == month }
    }

    var sortedReadings: [MonthlyReading] {
        readings.sorted { ($0.year, $0.month) < ($1.year, $1.month) }
    }
}

func value(_ reading: MonthlyReading, for pollutant: Pollutant) -> Double? {
    pollutant == .pm25 ? reading.pm25 : reading.pm10
}
