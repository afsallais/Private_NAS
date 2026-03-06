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
    
    private var connectionLabel: String {
        if let share = device.shareName {
            return "\(device.host) / \(share)"
        }
        return shareName.isEmpty ? device.host : "\(device.host) / \(shareName)"
    }
    
    private var smbURL: URL? {
        let share = shareName.isEmpty ? "shared" : shareName
        let host = device.host.hasSuffix(".local") ? device.host : "\(device.host)"
        return URL(string: "smb://\(host)/\(share)")
    }
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 56))
                        .foregroundStyle(.accent)
                    
                    Text(connectionLabel)
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                    
                    Button {
                        openInFiles()
                    } label: {
                        Label("Open in Files", systemImage: "arrow.up.forward")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    if device.shareName == nil {
                        TextField("Share name (e.g. Video)", text: $shareName)
                            .textContentType(.none)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    Button {
                        copyURL()
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy address")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
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
