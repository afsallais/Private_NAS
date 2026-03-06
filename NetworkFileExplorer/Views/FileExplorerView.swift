//
//  FileExplorerView.swift
//  Network File Explorer
//
//  Modern iOS-style file browser for SMB shares.
//

import SwiftUI

struct FileExplorerView: View {
    let device: NetworkDevice
    @StateObject private var smbService: SMBService
    @State private var showCredentials = false
    @State private var showError = false
    @State private var username = ""
    @State private var password = ""
    
    init(device: NetworkDevice) {
        self.device = device
        _smbService = StateObject(wrappedValue: SMBService(device: device))
    }
    
    var body: some View {
        Group {
            if smbService.needsShareSelection {
                shareSelectionView
            } else if smbService.items.isEmpty && !smbService.isLoading && smbService.errorMessage == nil {
                connectPromptView
            } else {
                fileListView
            }
        }
        .navigationTitle(device.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if smbService.canNavigateUp {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task { await smbService.navigateUp() }
                    } label: {
                        Image(systemName: "chevron.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showCredentials) {
            credentialsSheet
        }
        .onChange(of: smbService.errorMessage) { _, newValue in
            showError = newValue != nil
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                smbService.errorMessage = nil
            }
        } message: {
            Text(smbService.errorMessage ?? "")
        }
    }
    
    private var connectPromptView: some View {
        VStack(spacing: 24) {
            Image(systemName: "externaldrive.connected.to.line.below")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Connect to \(device.displayTitle)")
                .font(.title2.weight(.semibold))
            
            Text("Tap to connect. Some shares may require a username and password.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button {
                    Task {
                        await smbService.connect()
                    }
                } label: {
                    Label("Guest Connect", systemImage: "person")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    showCredentials = true
                } label: {
                    Label("Sign In", systemImage: "lock")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var shareSelectionView: some View {
        List {
            Section {
                ForEach(smbService.availableShares, id: \.name) { share in
                    Button {
                        Task {
                            await smbService.connectToShare(share.name)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(share.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                if !share.comment.isEmpty {
                                    Text(share.comment)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            } header: {
                Text("Select a share")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var fileListView: some View {
        Group {
            if smbService.isLoading && smbService.items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if smbService.currentPath != "/" {
                        Section {
                            Text(smbService.currentPath)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.head)
                        }
                    }
                    
                    Section {
                        ForEach(smbService.items) { item in
                            Button {
                                Task {
                                    await smbService.navigate(to: item)
                                }
                            } label: {
                                FileRow(item: item)
                            }
                            .disabled(!item.isDirectory)
                        }
                    } header: {
                        Text("\(smbService.items.count) item\(smbService.items.count == 1 ? "" : "s")")
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    private var credentialsSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                } footer: {
                    Text("Leave blank for guest access. Required for password-protected shares.")
                }
            }
            .navigationTitle("Connect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCredentials = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") {
                        showCredentials = false
                        Task {
                            await smbService.connect(username: username, password: password)
                        }
                    }
                }
            }
        }
    }
}

struct FileRow: View {
    let item: FileItem
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundStyle(item.isDirectory ? .blue : .secondary)
                .frame(width: 36, height: 36)
                .background(
                    (item.isDirectory ? Color.blue : Color.gray).opacity(0.15)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        FileExplorerView(device: NetworkDevice(
            id: "test",
            name: "Test NAS",
            host: "192.168.1.100",
            port: 445,
            type: .smb,
            shareName: "shared",
            endpoint: nil
        ))
    }
}
