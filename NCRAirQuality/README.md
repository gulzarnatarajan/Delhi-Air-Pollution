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

The app can show data two ways:

1. **Bundled sample data** (`AirQualityData.swift`) — originally extracted
   from `PM_2.5_10_Data_Analysis_v2_1.xlsx`: monthly average PM2.5 / PM10
   (µg/m³) for Delhi, Noida, Greater Noida, Ghaziabad, Gurugram, Faridabad,
   Sonipat, Bhiwadi, Neemrana, Manesar, Karnal, Rohtak, Panipat, Meerut,
   Alwar, and Bharatpur — January 2024 through August 2026. This is always
   there as a fallback, so the app never shows a blank screen.
2. **Live data from a published Google Sheet CSV link** — see below. Once
   configured, this takes over automatically; the bundled data is only used
   until the first successful fetch, and again if a later fetch fails (e.g.
   no signal).

### Connecting a live, continuously-updated data source

`AirQualityStore.swift` handles fetching, parsing, and offline caching.
To point it at your own data:

1. **Set up a Google Sheet** with one row per city per month, columns in
   any order but named exactly (case-insensitive): `City, Year, Month,
   PM25, PM10`. Leave `PM25`/`PM10` blank for a month with no reading.

   | City | Year | Month | PM25 | PM10 |
   |---|---|---|---|---|
   | Delhi | 2024 | 1 | 206 | 330 |
   | Delhi | 2024 | 2 | 135 | 246 |
   | Noida | 2024 | 1 | 162 | 270 |

2. **Publish it**: File → Share → Publish to web → select the sheet →
   format "Comma-separated values (.csv)" → Publish. Copy the link you get.
3. **Paste that link** into `AirQualityStore.swift`, replacing the
   placeholder:
   ```swift
   static let remoteCSVURLString = "PASTE_YOUR_PUBLISHED_GOOGLE_SHEET_CSV_LINK_HERE"
   ```
4. Rebuild and run. The app fetches this link on launch and whenever the
   user pulls to refresh, then caches the result so it still works offline
   afterward. A small caption under the pickers on each screen shows when
   the data was last updated, or explains why it's showing sample data.

Any city name not already in the app's known 16-city list is appended
automatically — no code change needed to add a 17th city later, as long as
its rows use the same column format.

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
    ├── AirQualityData.swift          # Bundled sample dataset (16 cities)
    ├── AirQualityStore.swift         # Fetches/caches live data; fallback to sample data
    ├── DataStatusView.swift          # "Updated Xm ago" / error caption
    ├── MonthlyReading+Display.swift  # Date/label helpers
    ├── Assets.xcassets
    └── Info.plist
```
