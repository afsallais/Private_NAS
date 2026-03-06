//
//  FileItem.swift
//  Network File Explorer
//

import Foundation

struct FileItem: Identifiable {
    let id: String
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64?
    let modifiedDate: Date?
    
    var icon: String {
        if isDirectory { return "folder.fill" }
        switch name.lowercased().suffix(4) {
        case ".jpg", ".png", ".gif", ".heic", "webp":
            return "photo.fill"
        case ".mp4", ".mov", ".avi", "mkv":
            return "film.fill"
        case ".mp3", ".m4a", ".wav":
            return "music.note"
        case ".pdf":
            return "doc.fill"
        case ".txt", ".md":
            return "doc.text.fill"
        default:
            return "doc.fill"
        }
    }
    
    var formattedSize: String {
        guard let size = size, !isDirectory else { return "" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
