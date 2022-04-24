//
// Created by 吴厚波 on 2022/4/13.
//

import Foundation
import WCDBSwift

class Video: TableCodable {
    var videoId: Int64 = 0
    var title: String = ""
    var desc: String?
    var tags: String?
    var preview: String?
    var file: String = ""
    /// 对应 Wallpaper Engine 软件里的 id
    var wallpaperEngineId: Int64?
    var contentrating: String?

    enum CodingKeys: String, CodingTableKey {
        typealias Root = Video
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        case videoId = "id"
        case title
        case desc = "description"
        case tags
        case preview
        case file
        case wallpaperEngineId
        case contentrating

        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            [videoId: ColumnConstraintBinding(isPrimary: true)]
        }
    }

    var isAutoIncrement: Bool = true // 用于定义是否使用自增的方式插入
    var lastInsertedRowID: Int64 = 0 // 用于获取自增插入后的主键值

    func fullFilePath() -> String? {
        VideoHelper.share.getFullPath(videoId: videoId, filename: file)
    }
}

class Playlist: TableCodable {
    var playlistId: Int64 = 0
    var name: String = ""
    var videoIds: String = ""

    enum CodingKeys: String, CodingTableKey {
        typealias Root = Playlist
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        case playlistId = "id"
        case name
        case videoIds

        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            [playlistId: ColumnConstraintBinding(isPrimary: true)]
        }
    }

    var isAutoIncrement: Bool = true // 用于定义是否使用自增的方式插入
    var lastInsertedRowID: Int64 = 0 // 用于获取自增插入后的主键值

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
