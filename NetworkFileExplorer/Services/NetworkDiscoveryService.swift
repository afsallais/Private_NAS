//
//  NetworkDiscoveryService.swift
//  Network File Explorer
//
//  Discovers SMB and other network shares via Bonjour/mDNS.
//

import Foundation
import Network

@MainActor
final class NetworkDiscoveryService: ObservableObject {
    @Published var devices: [NetworkDevice] = []
    @Published var isScanning = false
    @Published var errorMessage: String?
    
    private var browser: NWBrowser?
    private var discoveredEndpoints: Set<String> = []
    
    private let smbType = "_smb._tcp"
    private let afpType = "_afpovertcp._tcp"
    private let httpType = "_http._tcp"
    
    func startScanning() {
        guard !isScanning else { return }
        isScanning = true
        errorMessage = nil
        discoveredEndpoints.removeAll()
        devices.removeAll()
        
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        // Browse for SMB shares (most common for network storage)
        let smbDescriptor = NWBrowser.Descriptor.bonjour(type: smbType, domain: "local.")
        browser = NWBrowser(for: smbDescriptor, using: parameters)
        
        browser?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .failed(let error):
                    self?.errorMessage = "Discovery failed: \(error.localizedDescription)"
                    self?.isScanning = false
                case .ready:
                    break
                default:
                    break
                }
            }
        }
        
        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            Task { @MainActor in
                self?.processResults(results)
            }
        }
        
        browser?.start(queue: .main)
    }
    
    func stopScanning() {
        browser?.cancel()
        browser = nil
        isScanning = false
    }
    
    private func processResults(_ results: Set<NWBrowser.Result>) {
        for result in results {
            switch result.endpoint {
            case .service(name: let name, type: let type, domain: let domain, interface: _):
                let key = "\(name).\(type).\(domain)"
                guard !discoveredEndpoints.contains(key) else { continue }
                discoveredEndpoints.insert(key)
                
                resolveEndpoint(result.endpoint, serviceName: name, serviceType: type)
            default:
                break
            }
        }
    }
        
    private func resolveEndpoint(_ endpoint: NWEndpoint, serviceName: String, serviceType: String) {
        let connection = NWConnection(to: endpoint, using: .tcp)
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                if let inner = connection.currentPath?.remoteEndpoint,
                   case .hostPort(let host, let port) = inner {
                    Task { @MainActor in
                        let device = NetworkDevice(
                            id: "\(serviceName)-\(host)-\(port.rawValue)",
                            name: serviceName,
                            host: "\(host)",
                            port: Int(port.rawValue),
                            type: serviceType.contains("smb") ? .smb : .http,
                            shareName: nil
                        )
                        if !(self?.devices.contains { $0.id == device.id } ?? false) {
                            self?.devices.append(device)
                            self?.devices.sort { $0.name < $1.name }
                        }
                    }
                }
                connection.cancel()
            case .failed, .cancelled:
                connection.cancel()
            default:
                break
            }
        }
        connection.start(queue: .main)
    }
    
    func addManualShare(host: String, shareName: String) {
        let device = NetworkDevice(
            id: "manual-\(host)-\(shareName)",
            name: host,
            host: host,
            port: 445,
            type: .smb,
            shareName: shareName
        )
        if !devices.contains(where: { $0.id == device.id }) {
            devices.append(device)
            devices.sort { $0.name < $1.name }
        }
    }
}
