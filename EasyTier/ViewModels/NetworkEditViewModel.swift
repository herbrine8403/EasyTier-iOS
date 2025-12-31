import Foundation
import Combine

@MainActor
class NetworkEditViewModel: ObservableObject {
    @Published var config: NetworkConfig
    
    init(config: NetworkConfig? = nil) {
        self.config = config ?? NetworkConfig.defaultConfig()
    }
}
