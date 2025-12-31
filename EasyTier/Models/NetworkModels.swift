import Foundation

enum NetworkingMethod: Int, Codable, CaseIterable, Identifiable {
    var id: Self { self }
    case publicServer = 0
    case manual = 1
    case standalone = 2
}

struct PortForwardConfig: Codable, Hashable, Identifiable {
    var id = UUID()
    var bind_ip: String = ""
    var bind_port: Int = 0
    var dst_ip: String = ""
    var dst_port: Int = 0
    var proto: String = "tcp"
    
    private enum CodingKeys: String, CodingKey {
        case bind_ip, bind_port, dst_ip, dst_port, proto
    }
}

struct NetworkConfig: Codable, Identifiable {
    var id: String { instance_id }
    var instance_id: String

    var dhcp: Bool
    var virtual_ipv4: String
    var network_length: Int
    var hostname: String?
    var network_name: String
    var network_secret: String

    var networking_method: NetworkingMethod

    var public_server_url: String
    var peer_urls: [String]

    var proxy_cidrs: [String]

    var enable_vpn_portal: Bool
    var vpn_portal_listen_port: Int
    var vpn_portal_client_network_addr: String
    var vpn_portal_client_network_len: Int

    var advanced_settings: Bool

    var listener_urls: [String]
    var latency_first: Bool

    var dev_name: String

    var use_smoltcp: Bool
    var disable_ipv6: Bool
    var enable_kcp_proxy: Bool
    var disable_kcp_input: Bool
    var enable_quic_proxy: Bool
    var disable_quic_input: Bool
    var disable_p2p: Bool
    var p2p_only: Bool
    var bind_device: Bool
    var no_tun: Bool
    var enable_exit_node: Bool
    var relay_all_peer_rpc: Bool
    var multi_thread: Bool
    var proxy_forward_by_system: Bool
    var disable_encryption: Bool
    var disable_udp_hole_punching: Bool
    var disable_sym_hole_punching: Bool

    var enable_relay_network_whitelist: Bool
    var relay_network_whitelist: [String]

    var enable_manual_routes: Bool
    var routes: [String]
    
    var port_forwards: [PortForwardConfig] = []

    var exit_nodes: [String]

    var enable_socks5: Bool
    var socks5_port: Int

    var mtu: Int?
    var mapped_listeners: [String]

    var enable_magic_dns: Bool
    var enable_private_mode: Bool

    static func defaultConfig() -> NetworkConfig {
        return NetworkConfig(
            instance_id: UUID().uuidString,
            dhcp: true,
            virtual_ipv4: "10.144.144.0",
            network_length: 24,
            hostname: nil,
            network_name: "default",
            network_secret: "",
            networking_method: .publicServer,
            public_server_url: "https://api.example.com",
            peer_urls: [],
            proxy_cidrs: [],
            enable_vpn_portal: false,
            vpn_portal_listen_port: 22022,
            vpn_portal_client_network_addr: "10.144.144.0",
            vpn_portal_client_network_len: 24,
            advanced_settings: false,
            listener_urls: ["tcp://0.0.0.0:11010", "udp://0.0.0.0:11010", "wg://0.0.0.0:11011"],
            latency_first: false,
            dev_name: "utun10",
            use_smoltcp: false,
            disable_ipv6: false,
            enable_kcp_proxy: false,
            disable_kcp_input: false,
            enable_quic_proxy: false,
            disable_quic_input: false,
            disable_p2p: false,
            p2p_only: false,
            bind_device: false,
            no_tun: false,
            enable_exit_node: false,
            relay_all_peer_rpc: false,
            multi_thread: false,
            proxy_forward_by_system: false,
            disable_encryption: false,
            disable_udp_hole_punching: false,
            disable_sym_hole_punching: false,
            enable_relay_network_whitelist: false,
            relay_network_whitelist: [],
            enable_manual_routes: false,
            routes: [],
            port_forwards: [],
            exit_nodes: [],
            enable_socks5: false,
            socks5_port: 1080,
            mtu: nil,
            mapped_listeners: [],
            enable_magic_dns: false,
            enable_private_mode: false
        )
    }
}

struct NetworkInstance: Codable, Identifiable {
    var id: String { instance_id }
    var instance_id: String
    var running: Bool
    var error_msg: String
    var detail: NetworkInstanceRunningInfo?
}

struct NetworkInstanceRunningInfo: Codable {
    var dev_name: String
    var my_node_info: NodeInfo
    var events: [String] // JSON strings
    var routes: [Route]
    var peers: [PeerInfo]
    var peer_route_pairs: [PeerRoutePair]
    var running: Bool
    var error_msg: String?
}

struct Ipv4Addr: Codable, Hashable {
    var addr: UInt32
}

struct Ipv4Inet: Codable, Hashable {
    var address: Ipv4Addr
    var network_length: Int
}

struct Ipv6Addr: Codable, Hashable {
    var part1: UInt32
    var part2: UInt32
    var part3: UInt32
    var part4: UInt32
}

struct Url: Codable, Hashable {
    var url: String
}

struct NodeInfo: Codable {
    struct Ips: Codable {
        var public_ipv4: Ipv4Addr?
        var interface_ipv4s: [Ipv4Addr]
        var public_ipv6: Ipv6Addr?
        var interface_ipv6s: [Ipv6Addr]
    }
    var virtual_ipv4: Ipv4Inet
    var hostname: String
    var version: String
    var ips: Ips?
    var stun_info: StunInfo
    var listeners: [Url]
    var vpn_portal_cfg: String?
}

struct StunInfo: Codable, Hashable {
    var udp_nat_type: Int
    var tcp_nat_type: Int
    var last_update_time: TimeInterval
}

struct Route: Codable, Hashable, Identifiable {
    var id: Int { peer_id }
    var peer_id: Int
    var ipv4_addr: String?
    var next_hop_peer_id: Int
    var cost: Int
    var proxy_cidrs: [String]
    var hostname: String
    var stun_info: StunInfo?
    var inst_id: String
    var version: String
}

struct PeerInfo: Codable, Hashable, Identifiable {
    var id: Int { peer_id }
    var peer_id: Int
    var conns: [PeerConnInfo]
}

struct PeerConnInfo: Codable, Hashable {
    var conn_id: String
    var my_peer_id: Int
    var is_client: Bool
    var peer_id: Int
    var features: [String]
    var tunnel: TunnelInfo?
    var stats: PeerConnStats?
    var loss_rate: Double
}

struct PeerRoutePair: Codable, Hashable, Identifiable {
    var id: Int { route.id }
    var route: Route
    var peer: PeerInfo?
}

struct TunnelInfo: Codable, Hashable {
    var tunnel_type: String
    var local_addr: Url
    var remote_addr: Url
}

struct PeerConnStats: Codable, Hashable {
    var rx_bytes: Int
    var tx_bytes: Int
    var rx_packets: Int
    var tx_packets: Int
    var latency_us: Int
}
#if DEBUG
extension Ipv4Addr {
    static func fromString(_ s: String) -> Ipv4Addr? {
        let components = s.split(separator: ".").compactMap { UInt32($0) }
        guard components.count == 4 else { return nil }
        let addr = (components[0] << 24) | (components[1] << 16) | (components[2] << 8) | components[3]
        return Ipv4Addr(addr: addr)
    }
}

extension NetworkInstance {
    static func mockInstance(id: String = "uuid-1") -> NetworkInstance {
        let myNodeInfo = NodeInfo(
            virtual_ipv4: Ipv4Inet(address: Ipv4Addr.fromString("10.144.144.10")!, network_length: 24),
            hostname: "my-macbook-pro",
            version: "0.10.1",
            ips: .init(
                public_ipv4: Ipv4Addr.fromString("8.8.8.8"),
                interface_ipv4s: [Ipv4Addr.fromString("192.168.1.100")!],
                public_ipv6: nil as Ipv6Addr?,
                interface_ipv6s: []
            ),
            stun_info: StunInfo(udp_nat_type: 3, tcp_nat_type: 0, last_update_time: Date().timeIntervalSince1970 - 10),
            listeners: [Url(url: "tcp://0.0.0.0:11010"), Url(url: "udp://0.0.0.0:11010")],
            vpn_portal_cfg: "[Interface]\nPrivateKey = [REDACTED]\nAddress = 10.144.144.1/24\nListenPort = 22022\n\n[Peer]\nPublicKey = [REDACTED]\nAllowedIPs = 10.144.144.2/32"
        )
        
        let peerRoute1 = Route(peer_id: 123, ipv4_addr: "10.144.144.11", next_hop_peer_id: 123, cost: 1, proxy_cidrs: [], hostname: "peer-1-ubuntu", stun_info: StunInfo(udp_nat_type: 1, tcp_nat_type: 0, last_update_time: Date().timeIntervalSince1970 - 20), inst_id: id, version: "0.10.0")
        let peerRoute2 = Route(peer_id: 456, ipv4_addr: "10.144.144.12", next_hop_peer_id: 789, cost: 2, proxy_cidrs: [], hostname: "peer-2-relayed-windows", stun_info: StunInfo(udp_nat_type: 6, tcp_nat_type: 0, last_update_time: Date().timeIntervalSince1970 - 30), inst_id: id, version: "0.9.8")

        let peer1 = PeerInfo(peer_id: 123, conns: [PeerConnInfo(conn_id: "conn-1", my_peer_id: 0, is_client: true, peer_id: 123, features: [], tunnel: TunnelInfo(tunnel_type: "tcp", local_addr: Url(url:"192.168.1.100:55555"), remote_addr: Url(url:"1.2.3.4:11010")), stats: PeerConnStats(rx_bytes: 102400, tx_bytes: 204800, rx_packets: 100, tx_packets: 200, latency_us: 50000), loss_rate: 0.01)])
        
        let detail = NetworkInstanceRunningInfo(
            dev_name: "utun10",
            my_node_info: myNodeInfo,
            events: ["{\"time\":\"2025-12-30T12:00:00Z\",\"event\":{\"TunDeviceReady\":\"utun10\"}}", "{\"time\":\"2025-12-30T12:00:05Z\",\"event\":{\"PeerAdded\":123}}"],
            routes: [peerRoute1, peerRoute2],
            peers: [peer1],
            peer_route_pairs: [
                PeerRoutePair(route: peerRoute1, peer: peer1),
                PeerRoutePair(route: peerRoute2, peer: nil)
            ],
            running: true,
            error_msg: nil
        )
        
        return NetworkInstance(instance_id: id, running: true, error_msg: "", detail: detail)
    }
}
#endif

