//
//  NetworkDevice.swift
//  Network File Explorer
//

import Foundation

struct NetworkDevice: Identifiable, Hashable {
    let id: String
    let name: String
    let host: String
    let port: Int
    let type: DeviceType
    let shareName: String?
    
    enum DeviceType: String, CaseIterable {
        case smb = "SMB"
        case http = "HTTP"
        case afp = "AFP"
        
        var icon: String {
            switch self {
            case .smb: return "externaldrive.fill"
            case .http: return "globe"
            case .afp: return "folder.fill"
            }
        }
        
        var displayName: String { rawValue }
    }
    
    var displayTitle: String {
        shareName.map { "\(name) (\($0))" } ?? name
    }
    
    var connectionURL: String {
        switch type {
        case .smb:
            let share = shareName ?? "shared"
            return "smb://\(host)/\(share)"
        case .http:
            return "http://\(host):\(port)"
        case .afp:
            return "afp://\(host)"
        }
    }
}
