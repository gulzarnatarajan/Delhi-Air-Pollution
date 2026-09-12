import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AirQualityStore

    var body: some View {
        TabView {
            CityTrendView()
                .tabItem {
                    Label("City", systemImage: "location.circle")
                }

            CompareView()
                .tabItem {
                    Label("Compare", systemImage: "chart.bar")
                }
        }
        .task {
            await store.refresh()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AirQualityStore())
}
