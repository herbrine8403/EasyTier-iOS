import EasyTierShared
import SwiftUI

@main
struct EasyTierApp: App {
    #if targetEnvironment(simulator)
        @StateObject var manager = MockNEManager()
    #else
        @StateObject var manager = NetworkExtensionManager()
    #endif

    init() {
        let values: [String: Any] = [
            "logLevel": LogLevel.info.rawValue,
            "statusRefreshInterval": 1.0,
            "useRealDeviceNameAsDefault": true,
            "plainTextIPInput": false,
            "profilesUseICloud": false,
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
            ContentView(manager: manager)
        }
    }
}
