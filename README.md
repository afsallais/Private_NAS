# Network File Explorer

A modern iOS app that discovers devices and file shares on your local network and lets you browse files like a file explorer. Works with NAS devices, routers with USB storage, and other SMB shares.

## Features

- **Automatic discovery** – Finds SMB shares on your network via Bonjour/mDNS
- **Manual add** – Add shares by IP/hostname (e.g. router at 192.168.1.1)
- **File browsing** – Navigate folders and view files on network shares
- **Share selection** – Pick from multiple shares when a server has several
- **Credentials** – Optional username/password for protected shares

## Requirements

- iOS 17.0+
- Xcode 15+
- Same Wi‑Fi network as your NAS/router

## Setup

1. Open `NetworkFileExplorer/NetworkFileExplorer.xcodeproj` in Xcode.
2. Select your development team in Signing & Capabilities.
3. Build and run on a device or simulator.

The app uses Swift Package Manager for AMSMB2; Xcode will fetch it on first build.

## Permissions

On first run, iOS will ask for **Local Network** access so the app can discover devices. This is required for Bonjour discovery.

## Usage

1. **Scan** – Tap the refresh button to discover SMB shares on your network.
2. **Connect** – Tap a device to connect. Use guest access or enter credentials if needed.
3. **Browse** – Navigate folders and view files.
4. **Manual add** – Use the + button to add a share by IP (e.g. `192.168.1.1` for a router with USB storage).

## Troubleshooting: App Crashes on Launch

If the app crashes when you open it (especially from TestFlight):

1. **Add Local Network capability**  
   In Xcode: select the project → **Signing & Capabilities** → **+ Capability** → add **Local Network**.

2. **Get the crash log**  
   - **Xcode**: Window → Organizer → Crashes  
   - **Device**: Settings → Privacy & Security → Analytics & Improvements → Analytics Data → find your app’s crash  
   - **App Store Connect**: Your App → TestFlight → Feedback → Crashes  

3. **Test from Xcode**  
   Build and run directly from Xcode on a device. If it works there but crashes from TestFlight, the issue may be release build or signing related.

4. **Clean build**  
   Product → Clean Build Folder (⇧⌘K), then delete Derived Data and rebuild.

## Router USB Storage

Many routers share USB drives over SMB. If your router supports this:

1. Connect a USB drive to the router.
2. Enable file sharing in the router’s admin page.
3. Add the share manually with the router’s IP (often 192.168.1.1 or 192.168.0.1).
4. Use the share name shown in the router settings (e.g. `storage`, `usb`, or `share`).
