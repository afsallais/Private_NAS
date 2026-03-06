//
//  NetworkFileExplorerApp.swift
//  Network File Explorer
//
//  A modern iOS app to discover and browse network shares.
//

import SwiftUI

@main
struct NetworkFileExplorerApp: App {
    @StateObject private var discoveryService = NetworkDiscoveryService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(discoveryService)
        }
    }
}
