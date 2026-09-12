# NCR Air Quality

A simple iOS app that tracks monthly average PM2.5 and PM10 levels across
16 cities in the National Capital Region (NCR), from January 2024 through
August 2026.

## What it does

The app has two screens, reachable from a bottom tab bar — deliberately just
two, so there's never more than one decision to make on screen:

**City** — pick a city and a pollutant (PM2.5 or PM10). You get:
- The latest month's reading as a single big number, with a plain-language
  category (Good, Satisfactory, Moderate, Poor, Very Poor, Severe) shown as
  a colored pill.
- A line chart of every month on record for that city, so the trend is
  visible at a glance. Each point is colored by its own category.

**Compare** — pick a month and a pollutant, and see all 16 cities ranked
from worst to best as a bar chart, so you can spot which cities are doing
better or worse in a given month.

Cities without a reporting station for a given period (Neemrana has none in
this dataset; a few others have gaps) show a clear "not monitored" message
instead of a blank or misleading chart.

## Data

Source: `PM_2.5_10_Data_Analysis_v2_1.xlsx`, monthly average PM2.5 / PM10
(µg/m³) for Delhi, Noida, Greater Noida, Ghaziabad, Gurugram, Faridabad,
Sonipat, Bhiwadi, Neemrana, Manesar, Karnal, Rohtak, Panipat, Meerut, Alwar,
and Bharatpur — January 2024 through August 2026.

The data is baked into the app as Swift code
(`NCRAirQuality/AirQualityData.swift`), so the app works fully offline with
no backend or network calls. To refresh it with a newer spreadsheet, re-run
the same extraction shape: one `CityData` per city, one `MonthlyReading`
per available month, `nil` for months with no recorded value.

Category bands (Good/Satisfactory/Moderate/Poor/Very Poor/Severe) follow
India's CPCB AQI breakpoints for PM2.5 and PM10. Those breakpoints are
officially defined for 24-hour readings; here they're applied to monthly
averages purely as an indicative, easy-to-read color scale — not an
official AQI figure.

## Requirements

- Xcode 15 or later
- iOS 17.0+ deployment target (uses Swift Charts)

## Running it

1. Open `NCRAirQuality.xcodeproj` in Xcode.
2. Select the `NCRAirQuality` scheme and any iPhone simulator.
3. Press Run (⌘R).

No signing setup, dependencies, or configuration needed — it's a single
target with no third-party packages.

## Project structure

```
NCRAirQuality/
├── NCRAirQuality.xcodeproj
└── NCRAirQuality/
    ├── NCRAirQualityApp.swift        # App entry point
    ├── ContentView.swift             # Tab bar (City / Compare)
    ├── CityTrendView.swift           # Per-city trend screen
    ├── CompareView.swift             # Cross-city ranking screen
    ├── AirQualityCategory.swift      # CPCB-based category bands + colors
    ├── AirQualityData.swift          # Generated dataset (16 cities)
    ├── MonthlyReading+Display.swift  # Date/label helpers
    ├── Assets.xcassets
    └── Info.plist
```
