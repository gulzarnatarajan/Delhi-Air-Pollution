import SwiftUI

@main
struct NCRAirQualityApp: App {
    @StateObject private var store = AirQualityStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
