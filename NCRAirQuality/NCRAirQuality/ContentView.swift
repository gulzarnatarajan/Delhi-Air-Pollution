import SwiftUI

struct ContentView: View {
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
    }
}

#Preview {
    ContentView()
}
