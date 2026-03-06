//
//  NetworkDevice.swift
//  Network File Explorer
//

import Foundation
import Network

struct NetworkDevice: Identifiable {
    let id: String
    let name: String
    let host: String
    let port: Int
    let type: DeviceType
    let shareName: String?
    let endpoint: NWEndpoint?
    
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
    }
    
    var displayTitle: String {
        shareName.map { "\(name) (\($0))" } ?? name
    }
}
