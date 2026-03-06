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
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "gif", "heic", "webp", "bmp", "tiff":
            return "photo.fill"
        case "mp4", "mov", "avi", "mkv", "wmv", "flv":
            return "film.fill"
        case "mp3", "m4a", "wav", "aac", "flac":
            return "music.note"
        case "pdf":
            return "doc.fill"
        case "txt", "md", "rtf", "log":
            return "doc.text.fill"
        case "zip", "rar", "7z", "tar", "gz":
            return "doc.zipper"
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
    
    var formattedDate: String {
        guard let date = modifiedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var subtitle: String {
        [formattedSize, formattedDate].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
