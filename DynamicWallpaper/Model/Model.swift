//
// Created by 吴厚波 on 2022/4/13.
//

import Foundation
import SQLite

struct Video {
    let videoId: Int64
    let title: String
    let desc: String?
    let tags: String?
    let preview: String?
    let file: String
    let md5: String
    /// 对应 Wallpaper Engine 软件里的 id
    var wallpaperEngineId: String?
    var contentrating: String?

    func fullFilePath() -> String? {
        VideoHelper.share.getFullPath(videoId: videoId, filename: file)
    }
}

struct Playlist {
    let playlistId: Int64
    var title: String
    var videoIds: String

    func videoIdList() -> [Int64] {
        videoIds.components(separatedBy: ",").compactMap { Int64($0) }
    }
}

struct ScreenInfo {
    let screenHash: Int
    let name: String
    let size: CGSize
    let origin: CGPoint
    var playlistName: String? = nil
    var videoName: String? = nil

    static func from(screen: NSScreen) -> ScreenInfo {
        ScreenInfo(
            screenHash: screen.hash,
            name: screen.localizedName,
            size: screen.frame.size,
            origin: screen.frame.origin
        )
    }
}

class Monitor {
    let screen: NSScreen
    var playlistId: Int64?
    var videoName: String?
    var index: Int = -1
    var window: WallpaperWindow?

    init(screen: NSScreen) {
        self.screen = screen
    }
}

enum PlayLoopType: String, Codable, CaseIterable {
    case order
    case random
}

struct PlayConfig: Codable {
    /// 间隔时间，分钟为单位
    let periodInMin: Int
    let loopType: PlayLoopType
}

extension Row {
    func toPlaylist() -> Playlist {
        Playlist(playlistId: self[Column.id], title: self[Column.title], videoIds: self[Column.videoIds])
    }

    func toVideo() -> Video {
        Video(
            videoId: self[Column.id],
            title: self[Column.title],
            desc: self[Column.desc],
            tags: self[Column.tags],
            preview: self[Column.preview],
            file: self[Column.file],
            md5: self[Column.md5],
            wallpaperEngineId: self[Column.wallpaperEngineId],
            contentrating: self[Column.contentrating]
        )
    }
}
