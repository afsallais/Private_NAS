//
//  SMBService.swift
//  Network File Explorer
//
//  Browses files on SMB shares using AMSMB2.
//

import Foundation
import Network
import AMSMB2

@MainActor
final class SMBService: ObservableObject {
    @Published var currentPath: String = "/"
    @Published var items: [FileItem] = []
    @Published var availableShares: [(name: String, comment: String)] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var needsShareSelection = false
    
    private var client: SMB2Manager?
    private let device: NetworkDevice
    
    init(device: NetworkDevice) {
        self.device = device
    }
    
    private func resolveHost() async -> String? {
        if let endpoint = device.endpoint {
            return await withCheckedContinuation { continuation in
                let connection = NWConnection(to: endpoint, using: .tcp)
                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        if let path = connection.currentPath,
                           let remote = path.remoteEndpoint,
                           case .hostPort(let host, _) = remote {
                            let hostStr = "\(host)"
                            connection.cancel()
                            continuation.resume(returning: hostStr)
                        } else {
                            connection.cancel()
                            continuation.resume(returning: nil)
                        }
                    case .failed, .cancelled:
                        continuation.resume(returning: nil)
                    default:
                        break
                    }
                }
                connection.start(queue: .global(qos: .userInitiated))
            }
        }
        return device.host
    }
    
    func connect(username: String = "", password: String = "") async {
        isLoading = true
        errorMessage = nil
        needsShareSelection = false
        
        defer { isLoading = false }
        
        guard let resolvedHost = await resolveHost() else {
            errorMessage = "Could not resolve host"
            return
        }
        
        let hostString = resolvedHost
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? resolvedHost
        
        guard let url = URL(string: "smb://\(hostString)"),
              let manager = SMB2Manager(
                  url: url,
                  credential: URLCredential(
                      user: username.isEmpty ? "guest" : username,
                      password: password,
                      persistence: .none
                  )
              )
        else {
            errorMessage = "Could not connect to \(resolvedHost)"
            return
        }
        
        client = manager
        
        if let shareName = device.shareName {
            do {
                try await manager.connectShare(name: shareName)
                await listContents(at: "/")
            } catch {
                errorMessage = "Connection failed: \(error.localizedDescription)"
            }
        } else {
            do {
                let shares = try await manager.listShares(enumerateHidden: false)
                availableShares = shares.filter { !$0.name.hasSuffix("$") }
                if availableShares.count == 1 {
                    try await manager.connectShare(name: availableShares[0].name)
                    await listContents(at: "/")
                } else if availableShares.isEmpty {
                    errorMessage = "No shares found on this server"
                } else {
                    needsShareSelection = true
                }
            } catch {
                errorMessage = "Failed to list shares: \(error.localizedDescription)"
            }
        }
    }
    
    func connectToShare(_ shareName: String) async {
        guard let manager = client else { return }
        isLoading = true
        errorMessage = nil
        needsShareSelection = false
        
        defer { isLoading = false }
        
        do {
            try await manager.connectShare(name: shareName)
            await listContents(at: "/")
        } catch {
            errorMessage = "Connection failed: \(error.localizedDescription)"
        }
    }
    
    func listContents(at path: String) async {
        guard let client = client else { return }
        
        isLoading = true
        errorMessage = nil
        currentPath = path
        
        defer { isLoading = false }
        
        do {
            let contents = try await client.contentsOfDirectory(atPath: path)
            items = contents.compactMap { entry -> FileItem? in
                guard let name = entry[.nameKey] as? String else { return nil }
                guard name != ".", name != ".." else { return nil }
                
                let fullPath = (path as NSString).appendingPathComponent(name)
                let isDir = (entry[.fileResourceTypeKey] as? URLFileResourceType) == .directory
                let size = entry[.fileSizeKey] as? Int64
                let modified = (entry[.contentModificationDateKey] ?? entry[.creationDateKey]) as? Date
                
                return FileItem(
                    id: fullPath,
                    name: name,
                    path: fullPath,
                    isDirectory: isDir,
                    size: isDir ? nil : size,
                    modifiedDate: modified
                )
            }
            .sorted { item1, item2 in
                if item1.isDirectory != item2.isDirectory {
                    return item1.isDirectory
                }
                return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
            }
        } catch {
            errorMessage = "Failed to list: \(error.localizedDescription)"
            items = []
        }
    }
    
    func navigate(to item: FileItem) async {
        if item.isDirectory {
            await listContents(at: item.path)
        }
    }
    
    func navigateUp() async {
        let components = currentPath.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        guard !components.isEmpty else {
            await listContents(at: "/")
            return
        }
        let parentPath = "/" + components.dropLast().joined(separator: "/")
        await listContents(at: parentPath)
    }
    
    var canNavigateUp: Bool {
        currentPath != "/"
    }
}
