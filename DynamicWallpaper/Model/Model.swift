//
// Created by 吴厚波 on 2022/4/13.
//

import Foundation
import WCDBSwift

class Video: TableCodable {
    var id: Int64 = 0
    var title: String = ""
    var desc: String?
    var tags: String?
    var preview: String?
    var file: String = ""
    /// 对应 Wallpaper Engine 软件里的 id
    var wallpaperEngineId: Int64?

    enum CodingKeys: String, CodingTableKey {
        typealias Root = Video
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        case id
        case title
        case desc = "description"
        case tags
        case preview
        case file

        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            [id: ColumnConstraintBinding(isPrimary: true)]
        }
    }

    var isAutoIncrement: Bool = true // 用于定义是否使用自增的方式插入
    var lastInsertedRowID: Int64 = 0 // 用于获取自增插入后的主键值
}

class Playlist: TableCodable {
    var id: Int64 = 0
    var name: String = ""
    var videoIds: String = ""

    enum CodingKeys: String, CodingTableKey {
        typealias Root = Playlist
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        case id
        case name
        case videoIds

        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            [id: ColumnConstraintBinding(isPrimary: true)]
        }
    }

    var isAutoIncrement: Bool = true // 用于定义是否使用自增的方式插入
    var lastInsertedRowID: Int64 = 0 // 用于获取自增插入后的主键值
}

struct ScreenInfo {
    let screenHash: Int
    let name: String
    let size: CGSize
    let origin: CGPoint

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
    var videoUrl: String?
    var window: WallpaperWindow?

    init(screen: NSScreen) {
        self.screen = screen
    }
}
