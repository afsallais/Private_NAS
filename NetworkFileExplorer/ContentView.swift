//
//  ContentView.swift
//  Network File Explorer
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        DeviceListView()
    }
}

#Preview {
    ContentView()
        .environmentObject(NetworkDiscoveryService())
}
