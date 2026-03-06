//
//  DeviceDetailView.swift
//  Network File Explorer
//
//  Opens SMB shares in the system Files app.
//

import SwiftUI
import UIKit

struct DeviceDetailView: View {
    let device: NetworkDevice
    @State private var shareName = ""
    @State private var showOpenError = false
    @State private var showCopied = false
    
    private var smbURL: URL? {
        let share = shareName.isEmpty ? "shared" : shareName
        let host = device.host.hasSuffix(".local") ? device.host : "\(device.host)"
        return URL(string: "smb://\(host)/\(share)")
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "externaldrive.connected.to.line.below")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("Open in Files")
                        .font(.title2.weight(.semibold))
                    
                    Text("iOS Files app has built-in SMB support. Tap below to open this share in Files.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if device.shareName == nil {
                        TextField("Share name", text: $shareName)
                            .textContentType(.none)
                            .autocapitalization(.none)
                            .padding(.vertical, 8)
                    }
                    
                    Button {
                        openInFiles()
                    } label: {
                        Label("Open in Files", systemImage: "folder.badge.plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        copyURL()
                    } label: {
                        Label("Copy URL", systemImage: "doc.on.doc")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(device.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cannot Open", isPresented: $showOpenError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Copy the URL and paste it in Files app: Browse → ⋯ → Connect to Server")
        }
        .overlay {
            if showCopied {
                Text("Copied!")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCopied)
    }
    
    private func copyURL() {
        let share = device.shareName ?? (shareName.isEmpty ? "shared" : shareName)
        let host = device.host
        let urlString = "smb://\(host)/\(share)"
        UIPasteboard.general.string = urlString
        showCopied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            showCopied = false
        }
    }
    
    private func openInFiles() {
        let share = device.shareName ?? (shareName.isEmpty ? "shared" : shareName)
        let host = device.host
        let shareEncoded = share.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? share
        let hostEncoded = host.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? host
        guard let url = URL(string: "smb://\(hostEncoded)/\(shareEncoded)") else {
            showOpenError = true
            return
        }
        
        UIApplication.shared.open(url) { success in
            if !success {
                Task { @MainActor in
                    showOpenError = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DeviceDetailView(device: NetworkDevice(
            id: "test",
            name: "My NAS",
            host: "192.168.1.100",
            port: 445,
            type: .smb,
            shareName: "shared",
            endpoint: nil
        ))
    }
}
