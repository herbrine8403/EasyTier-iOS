import os
import NetworkExtension
import Foundation

let appName = "site.yinmo.easytier.tunnel"
let appGroupID = "group.site.yinmo.easytier"
let magicDNSIP = "100.100.100.101"
let magicDNSCIDR = RunningIPv4CIDR(from: "100.100.100.101/32")!

let logger = Logger(subsystem: appName, category: "swift")

class PacketTunnelProvider: NEPacketTunnelProvider {
    // Hold a weak reference to the current provider for C callback bridging
    private static weak var current: PacketTunnelProvider?

    private var lastOptions: [String: NSObject]?
    
    private func handleRustStop() {
        // Called from FFI callback on an arbitrary thread
        var msgPtr: UnsafePointer<CChar>? = nil
        var errPtr: UnsafePointer<CChar>? = nil
        let ret = get_latest_error_msg(&msgPtr, &errPtr)
        if ret == 0, let msg = extractRustString(msgPtr) {
            logger.error("handleRustStop(): \(msg, privacy: .public)")
            // Inform host app and cancel the tunnel on main queue
            DispatchQueue.main.async {
                self.notifyHostAppError(msg)
                self.cancelTunnelWithError(msg)
            }
        } else if let err = extractRustString(errPtr) {
            logger.error("handleRustStop() failed to get latest error: \(err, privacy: .public)")
        }
    }
    
    private func postDarwinNotification(_ name: String) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(name as CFString), nil, nil, true)
    }
    
    private func notifyHostAppError(_ message: String) {
        // Persist the latest error into shared defaults so the host app can read details
        if let defaults = UserDefaults(suiteName: appGroupID) {
            defaults.set(message, forKey: "TunnelLastError")
            defaults.synchronize()
        }
        // Wake the host app via Darwin notification
        postDarwinNotification("\(appName).error")
    }
    
    private func prepareSettings(_ options: [String : NSObject]) -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        let runningInfo = fetchRunningInfo()
        if runningInfo == nil {
            logger.warning("prepareSettings() running info is nil")
        }

        if let ipv4 = runningInfo?.myNodeInfo?.virtualIPv4,
           let mask = cidrToSubnetMask(ipv4.networkLength) {
            let ipv4Settings = NEIPv4Settings(
                addresses: [ipv4.address.description],
                subnetMasks: [mask]
            )
            let routes = buildIPv4Routes(info: runningInfo, manual: options["routes"] as? NSArray)
            if routes.isEmpty {
                logger.warning("prepareSettings() no ipv4 routes")
            } else {
                logger.info("prepareSettings() ipv4 routes: \(routes.count)")
            }
            if !routes.isEmpty {
                ipv4Settings.includedRoutes = routes
            }
            settings.ipv4Settings = ipv4Settings
        }

        if let ipv6CIDR = (options["ipv6"] as? String)?.split(separator: "/"), ipv6CIDR.count == 2 {
            let ip = ipv6CIDR[0], cidrStr = ipv6CIDR[1]
            if let cidr = Int(cidrStr) {
                settings.ipv6Settings = .init(
                    addresses: [String(ip)],
                    networkPrefixLengths: [NSNumber(value: cidr)]
                )
            }
        }

        if let dns = buildDNSServers(from: runningInfo, options: options) {
            settings.dnsSettings = NEDNSSettings(servers: dns)
        }
        
        settings.mtu = options["mtu"] as? NSNumber
        logger.info("prepareSettings(): \(settings, privacy: .public)")

        return settings
    }

    private func handleRunningInfoChanged() {
        logger.warning("handleRunningInfoChanged(): triggered")
        guard let options = lastOptions else {
            logger.warning("handleRunningInfoChanged() options is nil")
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            self.setTunnelNetworkSettings(prepareSettings(options)) { [weak self] error in
                if let error {
                    logger.error("handleRunningInfoChanged() failed to setTunnelNetworkSettings: \(error, privacy: .public)")
                    self?.notifyHostAppError(error.localizedDescription)
                    return
                }
                let tunFd = self?.packetFlow.value(forKeyPath: "socket.fileDescriptor") as? Int32 ?? tunnelFileDescriptor()
                guard let tunFd else {
                    logger.error("handleRunningInfoChanged() no available tun fd")
                    self?.notifyHostAppError("no available tun fd")
                    return
                }
                DispatchQueue.global(qos: .default).async {
                    var errPtr: UnsafePointer<CChar>? = nil
                    let ret = set_tun_fd(tunFd, &errPtr)
                    guard ret == 0 else {
                        let err = extractRustString(errPtr)
                        logger.error("handleRunningInfoChanged() failed to set tun fd to \(tunFd): \(err, privacy: .public)")
                        self?.notifyHostAppError(err ?? "Unknown")
                        return
                    }
                }
            }
        }
    }

    private func registerRunningInfoCallback() {
        let infoChangedCallback: @convention(c) () -> Void = {
            PacketTunnelProvider.current?.handleRunningInfoChanged()
        }
        var errPtr: UnsafePointer<CChar>? = nil
        let ret = register_running_info_callback(infoChangedCallback, &errPtr)
        if ret != 0 {
            let err = extractRustString(errPtr)
            logger.error("registerRunningInfoCallback() failed: \(err ?? "Unknown", privacy: .public)")
        } else {
            logger.info("registerRunningInfoCallback() registered")
        }
    }

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        logger.warning("startTunnel(): triggered")
        PacketTunnelProvider.current = self
        guard let options else {
            logger.error("startTunnel() options is nil")
            self.notifyHostAppError("options is nil")
            completionHandler("options is nil")
            return
        }
        
        guard let config = options["config"] as? String else {
            logger.error("startTunnel() config is empty")
            self.notifyHostAppError("config is empty")
            completionHandler("config is empty")
            return
        }
        self.lastOptions = options
        initRustLogger(level: options["logLevel"] as? String ?? "info")
        var errPtr: UnsafePointer<CChar>? = nil
        let ret = config.withCString { strPtr in
            return run_network_instance(strPtr, &errPtr)
        }
        guard ret == 0 else {
            let err = extractRustString(errPtr)
            logger.error("startTunnel() failed to run: \(err ?? "Unknown", privacy: .public)")
            self.notifyHostAppError(err ?? "Unknown")
            completionHandler(err)
            return
        }
        // Register FFI stop callback to capture crashes/stop events
        let rustStopCallback: @convention(c) () -> Void = {
            PacketTunnelProvider.current?.handleRustStop()
        }
        do {
            var regErrPtr: UnsafePointer<CChar>? = nil
            let regRet = register_stop_callback(rustStopCallback, &regErrPtr)
            if regRet != 0 {
                let regErr = extractRustString(regErrPtr)
                logger.error("startTunnel() failed to register stop callback: \(regErr ?? "Unknown", privacy: .public)")
            } else {
                logger.info("startTunnel() registered FFI stop callback")
            }
        }
        registerRunningInfoCallback()

        self.setTunnelNetworkSettings(prepareSettings(options)) { [weak self] error in
            if let error {
                logger.error("startTunnel() failed to setTunnelNetworkSettings: \(error, privacy: .public)")
                self?.notifyHostAppError(error.localizedDescription)
                completionHandler(error)
                return
            }
            let tunFd = self?.packetFlow.value(forKeyPath: "socket.fileDescriptor") as? Int32 ?? tunnelFileDescriptor()
            guard let tunFd else {
                logger.error("startTunnel() no available tun fd")
                self?.notifyHostAppError("no available tun fd")
                completionHandler("no available tun fd")
                return
            }
            DispatchQueue.global(qos: .default).async {
                var errPtr: UnsafePointer<CChar>? = nil
                let ret = set_tun_fd(tunFd, &errPtr)
                guard ret == 0 else {
                    let err = extractRustString(errPtr)
                    logger.error("startTunnel() failed to set tun fd to \(tunFd): \(err, privacy: .public)")
                    self?.notifyHostAppError(err ?? "Unknown")
                    completionHandler(err)
                    return
                }
            }
            completionHandler(nil)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.warning("stopTunnel(): triggered")
        let ret = stop_network_instance()
        if ret != 0 {
            logger.error("stopTunnel() failed")
        }
        PacketTunnelProvider.current = nil
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        logger.debug("handleAppMessage(): triggered")
        // Add code here to handle the message.
        guard let completionHandler else { return }
        var infoPtr: UnsafePointer<CChar>? = nil
        var errPtr: UnsafePointer<CChar>? = nil
        if get_running_info(&infoPtr, &errPtr) == 0, let info = extractRustString(infoPtr) {
            completionHandler(info.data(using: .utf8))
            return
        } else if let err = extractRustString(errPtr) {
            logger.error("handleAppMessage() failed: \(err, privacy: .public)")
        }
        completionHandler(nil)
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
    }
}

extension String: @retroactive Error {}
