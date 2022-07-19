//
// Created by 吴厚波 on 2022/4/13.
//

import Foundation
import SQLite

struct Video {
    let id: Int
    var title: String
    var desc: String?
    var tags: String?
    let preview: String?
    let file: String
    let md5: String
    /// 对应 Wallpaper Engine 软件里的 id
    var wallpaperEngineId: String?
    var contentrating: String?

    func fullFilePath() -> String? {
        VideoHelper.share.getFullPath(videoId: id, filename: file)
    }
}

struct Playlist: Hashable {
    let id: Int
    var title: String
    var videoIds: String

    func videoIdList() -> [Int] {
        videoIds.components(separatedBy: ",").compactMap { Int($0) }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class ScreenPlayConfig {
    let id: Int
    let screenHash: Int
    var playlistId: Int?
    var periodInMin: Int
    var curIndex: Int
    var loopType: PlayLoopType
    var volume: Double

    init(
        id: Int = 0,
        screenHash: Int,
        playlistId: Int? = nil,
        periodInMin: Int,
        curIndex: Int = -1,
        loopType: PlayLoopType = PlayLoopType.order,
        volume: Double = 0
    ) {
        self.id = id
        self.screenHash = screenHash
        self.playlistId = playlistId
        self.periodInMin = periodInMin
        self.curIndex = curIndex
        self.loopType = loopType
        self.volume = volume
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
    var videoName: String?
    var window: WallpaperWindow?

    init(screen: NSScreen) {
        self.screen = screen
    }
}

enum VideoSortType: String, Codable, CaseIterable {
    case addTimeAsc
    case addTimeDesc
    case titleAsc
    case titleDesc

    func text() -> String {
        switch self {
        case .addTimeAsc:
            return "添加时间顺序"
        case .addTimeDesc:
            return "添加时间逆序"
        case .titleAsc:
            return "名称顺序"
        case .titleDesc:
            return "名称逆序"
        }
    }

    func dbOrder() -> Expressible {
        switch self {
        case .addTimeAsc:
            return rowid.asc
        case .addTimeDesc:
            return rowid.desc
        case .titleAsc:
            return Column.title.asc
        case .titleDesc:
            return Column.title.desc
        }
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
        Playlist(id: self[Column.id], title: self[Column.title], videoIds: self[Column.videoIds])
    }

    func toVideo() -> Video {
        Video(
            id: self[Column.id],
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

    func toScreenPlayConfig() -> ScreenPlayConfig {
        ScreenPlayConfig(
            id: self[Column.id],
            screenHash: self[Column.screenHash],
            playlistId: self[Column.playlistId],
            periodInMin: self[Column.periodInMin],
            curIndex: self[Column.curIndex],
            loopType: PlayLoopType(rawValue: self[Column.loopType]) ?? PlayLoopType.order,
            volume: self[Column.volume]
        )
    }
}
