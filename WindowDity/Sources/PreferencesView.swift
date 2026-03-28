import SwiftUI
import ServiceManagement

struct PreferencesView: View {
    @AppStorage("zone_leftHalf") private var leftHalf = true
    @AppStorage("zone_rightHalf") private var rightHalf = true
    @AppStorage("zone_topHalf") private var topHalf = true
    @AppStorage("zone_bottomHalf") private var bottomHalf = true
    @AppStorage("zone_topLeftQuarter") private var topLeftQuarter = true
    @AppStorage("zone_topRightQuarter") private var topRightQuarter = true
    @AppStorage("zone_bottomLeftQuarter") private var bottomLeftQuarter = true
    @AppStorage("zone_bottomRightQuarter") private var bottomRightQuarter = true
    @AppStorage("zone_fullScreen") private var fullScreen = true
    @AppStorage("overlayOpacity") private var overlayOpacity = 0.15

    var body: some View {
        Form {
            Section("Zones") {
                Toggle("Left Half", isOn: $leftHalf)
                Toggle("Right Half", isOn: $rightHalf)
                Toggle("Top Half", isOn: $topHalf)
                Toggle("Bottom Half", isOn: $bottomHalf)
                Toggle("Top-Left Quarter", isOn: $topLeftQuarter)
                Toggle("Top-Right Quarter", isOn: $topRightQuarter)
                Toggle("Bottom-Left Quarter", isOn: $bottomLeftQuarter)
                Toggle("Bottom-Right Quarter", isOn: $bottomRightQuarter)
                Toggle("Full Screen", isOn: $fullScreen)
            }

            Section("Appearance") {
                HStack {
                    Text("Overlay Opacity")
                    Slider(value: $overlayOpacity, in: 0.05...0.5, step: 0.05)
                    Text("\(Int(overlayOpacity * 100))%")
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }
            }

            Section("General") {
                LaunchAtLoginToggle()
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 420)
    }
}

private struct LaunchAtLoginToggle: View {
    @State private var launchAtLogin = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    setLaunchAtLogin(newValue)
                }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            errorMessage = nil
        } catch {
            errorMessage = "Could not update login item: \(error.localizedDescription)"
            launchAtLogin = !enabled
        }
    }
}
