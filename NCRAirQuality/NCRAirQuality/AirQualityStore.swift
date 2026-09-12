import Foundation
import Combine

/// Loads air quality data from a live source (a published Google Sheet CSV link)
/// and falls back to the bundled sample data if that source isn't reachable —
/// so the app always shows *something*, online or off.
@MainActor
final class AirQualityStore: ObservableObject {
    @Published private(set) var cities: [CityData]
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?

    /// Paste the link you get from Google Sheets → File → Share → Publish to web →
    /// pick the sheet → format "Comma-separated values (.csv)" → Publish.
    /// Until this is a real link, the app just shows the bundled sample data.
    static let remoteCSVURLString = "PASTE_YOUR_PUBLISHED_GOOGLE_SHEET_CSV_LINK_HERE"

    private static let cacheFileName = "cached_air_quality.csv"

    var isConfigured: Bool {
        URL(string: Self.remoteCSVURLString)?.scheme?.hasPrefix("http") == true
    }

    init() {
        // Start with the bundled sample data so there's always something to show immediately.
        cities = AirQualityData.cities
        // If we've fetched successfully before, prefer that cached copy.
        if let cachedCSV = Self.readCache(), let parsed = Self.parse(csv: cachedCSV), !parsed.isEmpty {
            cities = parsed
            lastUpdated = Self.cacheDate()
        }
    }

    /// Downloads the latest CSV and updates `cities` on success.
    /// On any failure, leaves the existing data (cache or bundled sample) in place.
    func refresh() async {
        guard isConfigured, let url = URL(string: Self.remoteCSVURLString) else {
            loadError = "No live data source set up yet — showing sample data."
            return
        }
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            guard let text = String(data: data, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }
            guard let parsed = Self.parse(csv: text), !parsed.isEmpty else {
                throw URLError(.cannotParseResponse)
            }
            cities = parsed
            lastUpdated = Date()
            Self.writeCache(text)
        } catch {
            loadError = "Couldn't refresh (showing the last data available)."
        }
    }

    // MARK: - CSV parsing
    // Expected columns (any order, case-insensitive): City, Year, Month, PM25, PM10
    // One row per city per month. Leave PM25/PM10 blank for a month with no reading.

    private static func parse(csv text: String) -> [CityData]? {
        var lines = text.split(whereSeparator: \.isNewline).map(String.init)
        guard !lines.isEmpty else { return nil }

        let header = lines.removeFirst()
            .split(separator: ",", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

        guard let cityIdx = header.firstIndex(of: "city"),
              let yearIdx = header.firstIndex(of: "year"),
              let monthIdx = header.firstIndex(of: "month"),
              let pm25Idx = header.firstIndex(of: "pm25"),
              let pm10Idx = header.firstIndex(of: "pm10")
        else { return nil }

        var byCity: [String: [MonthlyReading]] = [:]
        var order: [String] = []

        for line in lines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            let fields = line
                .split(separator: ",", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard fields.count > max(cityIdx, yearIdx, monthIdx, pm25Idx, pm10Idx) else { continue }

            let city = fields[cityIdx]
            guard !city.isEmpty,
                  let year = Int(fields[yearIdx]),
                  let month = Int(fields[monthIdx])
            else { continue }

            let pm25 = Double(fields[pm25Idx])
            let pm10 = Double(fields[pm10Idx])

            if byCity[city] == nil {
                byCity[city] = []
                order.append(city)
            }
            byCity[city]?.append(MonthlyReading(year: year, month: month, pm25: pm25, pm10: pm10))
        }

        // Keep the familiar 16-city order first (even a city with zero rows still shows up,
        // as "not monitored"), then tack on anything new the sheet introduces later.
        let known = AirQualityData.knownCityOrder.map { name in
            CityData(id: name, readings: byCity[name] ?? [])
        }
        let extra = order
            .filter { !AirQualityData.knownCityOrder.contains($0) }
            .map { CityData(id: $0, readings: byCity[$0] ?? []) }
        return known + extra
    }

    // MARK: - Local cache (so a successful fetch survives being offline afterward)

    private static var cacheURL: URL? {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(cacheFileName)
    }

    private static func writeCache(_ text: String) {
        guard let url = cacheURL else { return }
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func readCache() -> String? {
        guard let url = cacheURL else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private static func cacheDate() -> Date? {
        guard let url = cacheURL else { return nil }
        return (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }
}
