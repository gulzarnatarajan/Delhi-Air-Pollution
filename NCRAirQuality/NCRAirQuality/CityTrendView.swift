import SwiftUI
import Charts

struct CityTrendView: View {
    @State private var selectedCityID: String = "Delhi"
    @State private var pollutant: Pollutant = .pm25

    private var city: CityData {
        AirQualityData.cities.first { $0.id == selectedCityID } ?? AirQualityData.cities[0]
    }

    private var readings: [MonthlyReading] {
        city.sortedReadings.filter { value($0, for: pollutant) != nil }
    }

    private var latest: MonthlyReading? { readings.last }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    cityPicker

                    pollutantPicker

                    if let latest, let latestValue = value(latest, for: pollutant) {
                        latestCard(pmValue: latestValue, monthLabel: latest.fullLabel)
                        trendChart
                        legend
                    } else {
                        notMonitoredCard
                    }
                }
                .padding()
            }
            .navigationTitle("NCR Air Quality")
        }
    }

    // MARK: - City picker

    private var cityPicker: some View {
        Menu {
            ForEach(AirQualityData.cities) { c in
                Button {
                    selectedCityID = c.id
                } label: {
                    if c.id == selectedCityID {
                        Label(c.id, systemImage: "checkmark")
                    } else {
                        Text(c.id)
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedCityID)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Pollutant picker

    private var pollutantPicker: some View {
        Picker("Pollutant", selection: $pollutant) {
            ForEach(Pollutant.allCases) { p in
                Text(p.shortLabel).tag(p)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Latest reading card

    private func latestCard(pmValue: Double, monthLabel: String) -> some View {
        let level = AirQualityCategory.level(for: pmValue, pollutant: pollutant)
        return VStack(spacing: 10) {
            Text(monthLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(pmValue.formatted(.number.precision(.fractionLength(0...1))))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                Text(pollutant.unit)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Text(level.name)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(level.color, in: Capsule())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var notMonitoredCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "sensor.tag.radiowaves.forward.slash")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Not monitored")
                .font(.headline)
            Text("\(selectedCityID) has no reporting station for \(pollutant.shortLabel) yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Trend chart

    private var trendChart: some View {
        Chart(readings) { reading in
            let v = value(reading, for: pollutant) ?? 0
            LineMark(
                x: .value("Month", reading.monthDate, unit: .month),
                y: .value(pollutant.shortLabel, v)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.secondary)

            PointMark(
                x: .value("Month", reading.monthDate, unit: .month),
                y: .value(pollutant.shortLabel, v)
            )
            .foregroundStyle(AirQualityCategory.level(for: v, pollutant: pollutant).color)
            .symbolSize(28)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month, count: 3)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 220)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Legend

    private var legend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(AirQualityCategory.legend(for: pollutant), id: \.name) { level in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(level.color)
                            .frame(width: 8, height: 8)
                        Text(level.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    CityTrendView()
}
