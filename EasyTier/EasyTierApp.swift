import SwiftUI
import SwiftData
import EasyTierShared

@main
struct EasyTierApp: App {
    @StateObject var manager = NEManager()
    
    init() {
        let values: [String : Any] = [
            "logLevel": LogLevel.info.rawValue,
            "statusRefreshInterval": 1.0,
            "useRealDeviceNameAsDefault": true,
            "includeAllNetworks": false,
            "excludeLocalNetworks": false,
            "excludeCellularServices": true,
            "excludeAPNs": true,
            "excludeDeviceCommunication": true,
            "enforceRoutes": false,
        ]
        UserDefaults(suiteName: APP_GROUP_ID)?.register(defaults: values)
    }

    var body: some Scene {
        WindowGroup {
            ContentView<NEManager>()
        }
        .modelContainer(for: [ProfileSummary.self, NetworkProfile.self])
        .environmentObject(manager)
    }
}
