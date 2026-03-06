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
    
    func startScanning() {
        guard !isScanning else { return }
        
        stopScanning()
        
        isScanning = true
        errorMessage = nil
        discoveredEndpoints.removeAll()
        devices.removeAll()
        
        let descriptor = NWBrowser.Descriptor.bonjour(type: "_smb._tcp", domain: nil)
        let params = NWParameters()
        params.includePeerToPeer = true
        
        let newBrowser = NWBrowser(for: descriptor, using: params)
        browser = newBrowser
        
        newBrowser.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch state {
                case .failed(let error):
                    self.errorMessage = "Discovery failed: \(error.localizedDescription)"
                    self.isScanning = false
                case .cancelled:
                    self.isScanning = false
                case .ready:
                    break
                default:
                    break
                }
            }
        }
        
        newBrowser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor [weak self] in
                self?.processResults(results)
            }
        }
        
        newBrowser.start(queue: .global(qos: .userInitiated))
    }
    
    func stopScanning() {
        browser?.cancel()
        browser = nil
        isScanning = false
    }
    
    private func processResults(_ results: Set<NWBrowser.Result>) {
        for result in results {
            if case .service(name: let name, type: let type, domain: let domain, interface: _) = result.endpoint {
                let key = "\(name).\(type).\(domain)"
                guard !discoveredEndpoints.contains(key) else { continue }
                discoveredEndpoints.insert(key)
                
                let device = NetworkDevice(
                    id: key,
                    name: name,
                    host: name,
                    port: 445,
                    type: type.contains("smb") ? .smb : .http,
                    shareName: nil,
                    endpoint: result.endpoint
                )
                if !devices.contains(where: { $0.id == device.id }) {
                    devices.append(device)
                    devices.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                }
            }
        }
    }
    
    func addManualShare(host: String, shareName: String) {
        let device = NetworkDevice(
            id: "manual-\(host)-\(shareName)",
            name: host,
            host: host,
            port: 445,
            type: .smb,
            shareName: shareName,
            endpoint: nil
        )
        if !devices.contains(where: { $0.id == device.id }) {
            devices.append(device)
            devices.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}
