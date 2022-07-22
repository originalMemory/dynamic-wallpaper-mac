//
// Created by 吴厚波 on 2022/4/13.
//

import Foundation
import SQLite
import AutoSQLiteSwift
import HandyJSON

class Video: SQLiteModel {
    var pkid: Int = 0 // PRIMARY KEY ID
    var title: String = ""
    var desc: String = ""
    var tags: [String] = []
    var preview: String = ""
    var file: String = ""
    var source: String = ""
    var verify: String = ""
    var width: Int = 0
    var height: Int = 0
    var extra: [String: Any] = [:]

    func fullFilePath() -> String? {
        VideoHelper.share.getFullPath(videoId: pkid, filename: file)
    }

    func fullPreviewPath() -> String? {
        VideoHelper.share.getFullPath(videoId: pkid, filename: preview)
    }
}

class Playlist: SQLiteModel {
    var pkid: Int = 0
    var title: String = ""
    var videoIds: [Int] = []

    func videoIdInStr() -> String {
        videoIds.map { String($0) }.joined(separator: ",")
    }
}

class ScreenPlayConfig: SQLiteModel {
    var pkid: Int = 0
    var screenHash: Int = 0
    var playlistId: Int?
    var periodInMin: Int = 5
    var curIndex: Int = 0
    var loopType: PlayLoopType = .order
    var volume: Double = 0

    convenience init(screenHash: Int) {
        self.init()
        self.screenHash = screenHash
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

    func dbOrder() -> Order {
        switch self {
        case .addTimeAsc:
            return Order(key: "rowid", type: .asc)
        case .addTimeDesc:
            return Order(key: "rowid", type: .desc)
        case .titleAsc:
            return Order(key: "title", type: .asc)
        case .titleDesc:
            return Order(key: "title", type: .desc)
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
