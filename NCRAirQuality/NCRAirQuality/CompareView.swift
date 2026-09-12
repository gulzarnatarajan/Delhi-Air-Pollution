import SwiftUI
import Charts

private struct CityRanking: Identifiable {
    let id: String
    let value: Double
}

private struct MonthKey: Identifiable, Hashable {
    let year: Int
    let month: Int
    var id: String { "\(year)-\(month)" }
}

struct CompareView: View {
    @State private var selectedMonthKey: String
    @State private var pollutant: Pollutant = .pm25

    private static let allMonths: [MonthKey] = {
        var seen = Set<String>()
        var months: [MonthKey] = []
        for city in AirQualityData.cities {
            for r in city.readings {
                let key = MonthKey(year: r.year, month: r.month)
                if !seen.contains(key.id) {
                    seen.insert(key.id)
                    months.append(key)
                }
            }
        }
        return months.sorted { $0.year != $1.year ? $0.year > $1.year : $0.month > $1.month }
    }()

    init() {
        _selectedMonthKey = State(initialValue: Self.allMonths.first?.id ?? "")
    }

    private var selectedYearMonth: (year: Int, month: Int)? {
        let parts = selectedMonthKey.split(separator: "-")
        guard parts.count == 2, let y = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return (y, m)
    }

    private var monthLabel: String {
        guard let ym = selectedYearMonth,
              let date = Calendar.airQuality.date(from: DateComponents(year: ym.year, month: ym.month, day: 1))
        else { return "" }
        let f = DateFormatter()
        f.calendar = .airQuality
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private var rankings: [CityRanking] {
        guard let ym = selectedYearMonth else { return [] }
        return AirQualityData.cities.compactMap { city in
            guard let reading = city.reading(year: ym.year, month: ym.month),
                  let v = value(reading, for: pollutant) else { return nil }
            return CityRanking(id: city.id, value: v)
        }
        .sorted { $0.value > $1.value }
    }

    private var unmonitoredCount: Int {
        AirQualityData.cities.count - rankings.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthPicker

                    pollutantPicker

                    if rankings.isEmpty {
                        Text("No data for \(monthLabel).")
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    } else {
                        rankingChart

                        if unmonitoredCount > 0 {
                            Text("\(unmonitoredCount) of \(AirQualityData.cities.count) cities had no station reporting this month.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Compare Cities")
        }
    }

    private var monthPicker: some View {
        Menu {
            ForEach(Self.allMonths) { ym in
                Button {
                    selectedMonthKey = ym.id
                } label: {
                    Text(labelFor(year: ym.year, month: ym.month))
                }
            }
        } label: {
            HStack {
                Text(monthLabel)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    private func labelFor(year: Int, month: Int) -> String {
        guard let date = Calendar.airQuality.date(from: DateComponents(year: year, month: month, day: 1)) else { return "" }
        let f = DateFormatter()
        f.calendar = .airQuality
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private var pollutantPicker: some View {
        Picker("Pollutant", selection: $pollutant) {
            ForEach(Pollutant.allCases) { p in
                Text(p.shortLabel).tag(p)
            }
        }
        .pickerStyle(.segmented)
    }

    private var rankingChart: some View {
        Chart(rankings) { item in
            BarMark(
                x: .value(pollutant.shortLabel, item.value),
                y: .value("City", item.id)
            )
            .foregroundStyle(AirQualityCategory.level(for: item.value, pollutant: pollutant).color)
            .annotation(position: .trailing) {
                Text(item.value.formatted(.number.precision(.fractionLength(0...1))))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom)
        }
        .frame(height: CGFloat(rankings.count) * 32 + 20)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    CompareView()
}
