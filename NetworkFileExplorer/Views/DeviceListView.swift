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
    @State private var showError = false
    @State private var manualAddress = ""
    
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
                    HStack(spacing: 16) {
                        Button {
                            showAddManual = true
                        } label: {
                            Image(systemName: "plus.circle")
                        }
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
                }
            }
            .sheet(isPresented: $showAddManual) {
                addManualSheet
            }
            .onChange(of: discoveryService.errorMessage) { _, newValue in
                showError = newValue != nil
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    discoveryService.errorMessage = nil
                }
            } message: {
                Text(discoveryService.errorMessage ?? "")
            }
            .task {
                try? await Task.sleep(for: .seconds(0.5))
                if discoveryService.devices.isEmpty && !discoveryService.isScanning {
                    discoveryService.startScanning()
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
                    VStack(spacing: 20) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No devices found")
                            .font(.headline)
                        Text("Add your router or NAS manually if it doesn't appear")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            showAddManual = true
                        } label: {
                            Label("Add Share Manually", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
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
                            DeviceDetailView(device: device)
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
        .refreshable {
            discoveryService.startScanning()
            try? await Task.sleep(for: .seconds(3))
        }
    }
    
    private var addManualSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Connect to")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    TextField("192.168.68.54 or 192.168.68.54/Video", text: $manualAddress)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.numbersAndPunctuation)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text("Enter IP address, or IP/share (e.g. 192.168.68.54/Video)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if !manualAddress.isEmpty && !manualAddress.contains("/") && !manualAddress.contains("\\") {
                        Text("Common share names")
                            .font(.subheadline.weight(.medium))
                            .padding(.top, 8)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(["Video", "Users", "Public", "shared", "Documents", "C$"], id: \.self) { share in
                                Button {
                                    discoveryService.addManualShare(host: manualAddress.trimmingCharacters(in: .whitespaces), shareName: share)
                                    showAddManual = false
                                    manualAddress = ""
                                } label: {
                                    Text(share)
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.accentColor.opacity(0.15))
                                        .foregroundStyle(.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(24)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        addFromAddress()
                    } label: {
                        Text("Add & Connect")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(manualAddress.isEmpty)
                    
                    Button("Cancel") {
                        showAddManual = false
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(24)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Add Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddManual = false
                    }
                }
            }
        }
    }
    
    private func addFromAddress() {
        let input = manualAddress.trimmingCharacters(in: .whitespaces)
        let host: String
        let share: String
        
        if input.contains("/") {
            let parts = input.split(separator: "/", maxSplits: 1).map(String.init)
            host = parts[0]
            share = parts.count > 1 ? parts[1] : "shared"
        } else if input.contains("\\") {
            let parts = input.split(separator: "\\", maxSplits: 1).map(String.init)
            host = parts[0]
            share = parts.count > 1 ? parts[1] : "shared"
        } else {
            host = input
            share = "shared"
        }
        
        guard !host.isEmpty else { return }
        
        discoveryService.addManualShare(host: host, shareName: share)
        showAddManual = false
        manualAddress = ""
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
