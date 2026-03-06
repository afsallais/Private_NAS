//
//  DeviceListView.swift
//  Network File Explorer
//
//  Modern iOS-style device discovery view.
//

import SwiftUI

struct DeviceListView: View {
    @EnvironmentObject var discoveryService: NetworkDiscoveryService
    @State private var showAddManual = false
    @State private var manualHost = ""
    @State private var manualShare = "shared"
    
    var body: some View {
        NavigationStack {
            Group {
                if discoveryService.isScanning && discoveryService.devices.isEmpty {
                    scanningView
                } else {
                    deviceList
                }
            }
            .navigationTitle("Network")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if discoveryService.isScanning {
                        Button("Stop") {
                            discoveryService.stopScanning()
                        }
                    } else {
                        Button {
                            discoveryService.startScanning()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showAddManual = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddManual) {
                addManualSheet
            }
            .alert("Error", isPresented: .constant(discoveryService.errorMessage != nil)) {
                Button("OK") {
                    discoveryService.errorMessage = nil
                }
            } message: {
                if let error = discoveryService.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var scanningView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Scanning for devices...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var deviceList: some View {
        List {
            if discoveryService.devices.isEmpty && !discoveryService.isScanning {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No devices found")
                            .font(.headline)
                        Text("Tap the refresh button to scan your network")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                Section {
                    ForEach(discoveryService.devices) { device in
                        NavigationLink {
                            FileExplorerView(device: device)
                        } label: {
                            DeviceRow(device: device)
                        }
                    }
                } header: {
                    if !discoveryService.devices.isEmpty {
                        Text("\(discoveryService.devices.count) device\(discoveryService.devices.count == 1 ? "" : "s") found")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var addManualSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Host or IP", text: $manualHost)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    TextField("Share name", text: $manualShare)
                        .textContentType(.none)
                        .autocapitalization(.none)
                } footer: {
                    Text("Enter your router or NAS IP (e.g. 192.168.1.1) and share name.")
                }
            }
            .navigationTitle("Add Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddManual = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        discoveryService.addManualShare(host: manualHost, shareName: manualShare)
                        showAddManual = false
                        manualHost = ""
                        manualShare = "shared"
                    }
                    .disabled(manualHost.isEmpty || manualShare.isEmpty)
                }
            }
        }
    }
}

struct DeviceRow: View {
    let device: NetworkDevice
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: device.type.icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.displayTitle)
                    .font(.body.weight(.medium))
                Text(device.host)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DeviceListView()
        .environmentObject(NetworkDiscoveryService())
}
