//
// Created by 吴厚波 on 2022/4/13.
//

import Foundation
import SQLite
import AutoSQLiteSwift

enum TableType: String, CaseIterable {
    case video
    case playlist
    case screenPlayConfig
}

enum OrderType: String {
    case asc
    case desc
}

struct Order {
    let key: String
    let type: OrderType
}

// MARK: - Common

class DBManager {
    static let share = DBManager()
    private lazy var db: SQLiteDataBase = {
        SQLiteDataBase.createDB("wallpaper")
    }()

    func insert(type: TableType, obj: SQLiteModel) {
        db.insert(obj, intoTable: type.rawValue)
    }

    func delete(type: TableType, id: Int) {
        db.delete(fromTable: type.rawValue, sqlWhere: "rowid=\(id)")
    }

    func searchVideos(sqlWhere: String? = nil, orders: [Order] = []) -> [Video] {
        searchAll(type: .video, sqlWhere: sqlWhere, orders: orders)
    }

    func getVideo(id: Int) -> Video? {
        searchVideos(sqlWhere: "rowId=\(id)").first
    }

    func getPlaylist(id: Int) -> Playlist? {
        searchPlaylists(sqlWhere: "rowid=\(id)").first
    }

    func searchPlaylists(sqlWhere: String? = nil) -> [Playlist] {
        searchAll(type: .playlist, sqlWhere: sqlWhere)
    }

    func searchScreenPlayConfigs(sqlWhere: String? = nil) -> [ScreenPlayConfig] {
        searchAll(type: .screenPlayConfig, sqlWhere: sqlWhere)
    }

    func searchAll<T: SQLiteModel>(
        type: TableType,
        sqlWhere: String? = nil,
        limit: Int? = nil,
        orders: [Order] = []
    ) -> [T] {
        var finalWhere = sqlWhere ?? "1=1"
        if limit != nil {
            finalWhere += " LIMIT \(limit ?? 1)"
        }
        if orders.count > 0 {
            finalWhere += " ORDER BY"
        }
        for (i, order) in orders.enumerated() {
            finalWhere += " \(order.key) \(order.type.rawValue)" + (i < orders.count - 1 ? "," : "")
        }
        return db.selectModel(fromTable: type.rawValue, sqlWhere: finalWhere)
    }

    func update(type: TableType, obj: SQLiteModel) {
        db.update(obj, fromTable: type.rawValue)
    }

    func exist(type: TableType, sqlWhere: String) -> Bool {
        db.select(fromTable: type.rawValue, sqlWhere: sqlWhere).count > 0
    }
}
