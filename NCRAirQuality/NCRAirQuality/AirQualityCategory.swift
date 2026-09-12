// Air quality category bands, based on India CPCB AQI breakpoints.
// Applied here to monthly average concentrations for an at-a-glance read —
// treat the label as indicative, not an official 24-hour AQI reading.
import SwiftUI

enum Pollutant: String, CaseIterable, Identifiable {
    case pm25 = "PM2.5"
    case pm10 = "PM10"

    var id: String { rawValue }
    var shortLabel: String { rawValue }
    var unit: String { "µg/m³" }
}

struct AirQualityLevel {
    let name: String
    let color: Color
}

enum AirQualityCategory {
    /// Ordered low-to-high bands: (upper bound inclusive, level).
    /// The final entry's bound is ignored — any value above the previous bound falls in it.
    private static let pm25Bands: [(Double, AirQualityLevel)] = [
        (30,  AirQualityLevel(name: "Good",         color: Color(red: 0.30, green: 0.69, blue: 0.31))),
        (60,  AirQualityLevel(name: "Satisfactory",  color: Color(red: 0.55, green: 0.76, blue: 0.29))),
        (90,  AirQualityLevel(name: "Moderate",      color: Color(red: 0.98, green: 0.75, blue: 0.18))),
        (120, AirQualityLevel(name: "Poor",          color: Color(red: 0.95, green: 0.52, blue: 0.15))),
        (250, AirQualityLevel(name: "Very Poor",     color: Color(red: 0.85, green: 0.20, blue: 0.18))),
        (.infinity, AirQualityLevel(name: "Severe",  color: Color(red: 0.50, green: 0.09, blue: 0.13))),
    ]

    private static let pm10Bands: [(Double, AirQualityLevel)] = [
        (50,  AirQualityLevel(name: "Good",         color: Color(red: 0.30, green: 0.69, blue: 0.31))),
        (100, AirQualityLevel(name: "Satisfactory",  color: Color(red: 0.55, green: 0.76, blue: 0.29))),
        (250, AirQualityLevel(name: "Moderate",      color: Color(red: 0.98, green: 0.75, blue: 0.18))),
        (350, AirQualityLevel(name: "Poor",          color: Color(red: 0.95, green: 0.52, blue: 0.15))),
        (430, AirQualityLevel(name: "Very Poor",     color: Color(red: 0.85, green: 0.20, blue: 0.18))),
        (.infinity, AirQualityLevel(name: "Severe",  color: Color(red: 0.50, green: 0.09, blue: 0.13))),
    ]

    static func level(for value: Double, pollutant: Pollutant) -> AirQualityLevel {
        let bands = pollutant == .pm25 ? pm25Bands : pm10Bands
        for (bound, level) in bands where value <= bound {
            return level
        }
        return bands.last!.1
    }

    /// All bands low-to-high, for legends.
    static func legend(for pollutant: Pollutant) -> [AirQualityLevel] {
        (pollutant == .pm25 ? pm25Bands : pm10Bands).map { $0.1 }
    }
}
