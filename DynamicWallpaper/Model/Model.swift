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

class Monitor {
    let screen: NSScreen

    init(screen: NSScreen) {
        self.screen = screen
    }

    var size: CGSize {
        screen.frame.size
    }

    var origin: CGPoint {
        screen.frame.origin
    }
}
