import Foundation
import Combine

struct NetworkItem: Identifiable, Hashable {
    var id: UUID = UUID()
    let name: String
}

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var networks: [NetworkItem] = [
        .init(name: "Test"),
        .init(name: "Test X"),
    ]
    @Published var selectedNetworkId: UUID?
    @Published var isConnected: Bool = false
    @Published var isPending: Bool = false

    var selectedNetwork: NetworkItem? {
        networks.first { $0.id == selectedNetworkId }
    }

    func newNetwork(name: String) {
        var name = name
        if (name.isEmpty) {
            name = "New Network"
        }
        let newNetwork = NetworkItem(name: name)
        networks.append(newNetwork)
        selectedNetworkId = newNetwork.id
    }

    func deleteNetwork() {
        guard let selected = selectedNetworkId else { return }
        networks.removeAll { $0.id == selected }
        selectedNetworkId = networks.first?.id
    }
}
