import SwiftUI

/// A small caption showing where the on-screen data came from and how fresh it is.
/// Drop this under the pickers on any screen that reads from `AirQualityStore`.
struct DataStatusView: View {
    @EnvironmentObject private var store: AirQualityStore

    var body: some View {
        HStack(spacing: 6) {
            if store.isLoading {
                ProgressView()
                    .controlSize(.mini)
            }
            Text(statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var statusText: String {
        if let loadError = store.loadError {
            return loadError
        }
        if let lastUpdated = store.lastUpdated {
            return "Updated \(lastUpdated.formatted(.relative(presentation: .named)))"
        }
        return "Showing sample data"
    }
}

#Preview {
    DataStatusView()
        .environmentObject(AirQualityStore())
}
