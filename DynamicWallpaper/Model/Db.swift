//
// Created by 吴厚波 on 2022/4/13.
//

import Foundation
import SQLite

enum TableType: String, CaseIterable {
    case video
    case playlist
    case screenPlayConfig
}

enum Column {
    static let id = Expression<Int64>("id")
    static let createTime = Expression<Date>("createTime")
    static let updateTime = Expression<Date>("updateTime")

    static let title = Expression<String>("title")
    static let desc = Expression<String?>("description")
    static let tags = Expression<String?>("tags")
    static let preview = Expression<String?>("preview")
    static let file = Expression<String>("file")
    static let md5 = Expression<String>("md5")
    static let wallpaperEngineId = Expression<String?>("wallpaperEngineId")
    static let contentrating = Expression<String?>("contentrating")

    static let videoIds = Expression<String>("videoIds")

    static let screenHash = Expression<Int>("screenHash")
    static let playlistId = Expression<Int64?>("playlistId")
    static let periodInMin = Expression<Int>("periodInMin")
    static let curIndex = Expression<Int>("curIndex")
    static let loopType = Expression<String>("loopType")
}

// MARK: - Common

class DBManager: NSObject {
    static let share = DBManager()
    private var db: Connection?
    private var tableMap: [TableType: Table] = [:]
    private let kVersion = "dbVersion"
    private var version = 2

    override private init() {
        super.init()
        checkForUpdateColumn()
    }

    func getDB() -> Connection? {
        do {
            if db == nil {
                let path = NSSearchPathForDirectoriesInDomains(
                    .documentDirectory, .userDomainMask, true
                ).first!
                db = try Connection("\(path)/db.sqlite3")
                db?.busyTimeout = 5.0
            }
            return db
        } catch {
            debugPrint("创建数据库出错：\(error)")
            return nil
        }
    }

    private func checkForUpdateColumn() {
        let lastVersion = UserDefaults.standard.integer(forKey: kVersion)
        if lastVersion == 0 {
            UserDefaults.standard.set(version, forKey: kVersion)
            return
        }
        do {
            if lastVersion < 2 {
                guard let db = getDB(),
                      let table = getTable(type: .screenPlayConfig)
                else { return }
                let res = try db.run(table.addColumn(Column.curIndex, defaultValue: -1))
                debugPrint("更新表结构：\(res)")
            }
            UserDefaults.standard.set(version, forKey: kVersion)
        } catch {
            debugPrint("更新表结构出错：\(error)")
        }
    }

    func getTable(type: TableType) -> Table? {
        if let table = tableMap[type] {
            return table
        }
        do {
            let table = Table(type.rawValue)
            switch type {
            case .video:
                try getDB()?.run(
                    table.create(ifNotExists: true) { builder in
                        builder.column(Column.id, primaryKey: true)
                        builder.column(Column.title)
                        builder.column(Column.desc)
                        builder.column(Column.tags)
                        builder.column(Column.preview)
                        builder.column(Column.file)
                        builder.column(Column.md5)
                        builder.column(Column.wallpaperEngineId)
                        builder.column(Column.contentrating)
                        builder.column(Column.createTime, defaultValue: Date.now)
                        builder.column(Column.updateTime, defaultValue: Date.now)
                    }
                )
            case .playlist:
                try getDB()?.run(
                    table.create(ifNotExists: true) { builder in
                        builder.column(Column.id, primaryKey: true)
                        builder.column(Column.title)
                        builder.column(Column.videoIds)
                        builder.column(Column.createTime, defaultValue: Date.now)
                        builder.column(Column.updateTime, defaultValue: Date.now)
                    }
                )
            case .screenPlayConfig:
                try getDB()?.run(
                    table.create(ifNotExists: true) { builder in
                        builder.column(Column.id, primaryKey: true)
                        builder.column(Column.screenHash)
                        builder.column(Column.playlistId)
                        builder.column(Column.periodInMin)
                        builder.column(Column.curIndex)
                        builder.column(Column.loopType)
                        builder.column(Column.createTime, defaultValue: Date.now)
                        builder.column(Column.updateTime, defaultValue: Date.now)
                    }
                )
            }
            tableMap[type] = table
            return table
        } catch {
            debugPrint("获取表出错：\(error)")
            return nil
        }
    }

    private func runInsert(_ insert: Insert) -> Int64? {
        do {
            return try getDB()?.run(insert)
        } catch {
            debugPrint("插入出错：\(error)")
            return nil
        }
    }

    // 根据条件删除
    func delete(type: TableType, id: Int64) {
        guard let query = getTable(type: type)?.filter(rowid == id) else { return }
        do {
            let count = try getDB()?.run(query.delete())
            debugPrint("删除的条数为：\(count ?? 0)")
        } catch {
            debugPrint("删除出错：\(error)")
        }
    }

    func search(
        type: TableType,
        select: [Expressible]? = nil,
        filter: Expression<Bool>? = nil,
        order: [Expressible] = [rowid.asc],
        limit: Int? = nil,
        offset: Int? = nil
    ) -> [Row] {
        guard var query = getTable(type: type)?.order(order) else { return [] }
        if let s = select {
            query = query.select(s)
        }
        if let f = filter {
            query = query.filter(f)
        }
        if let l = limit {
            if let o = offset {
                query = query.limit(l, offset: o)
            } else {
                query = query.limit(l)
            }
        }
        do {
            if let result = try getDB()?.prepare(query) {
                return Array(result)
            } else {
                return []
            }
        } catch {
            debugPrint("查找出错：\(error)")
            return []
        }
    }

    func exist(type: TableType, filter: Expression<Bool>) -> Bool {
        guard let db = getDB(), let query = getTable(type: type)?.filter(filter).select(rowid) else { return false }
        do {
            let res = try db.prepare(query)
            return Array(res).count >= 1
        } catch {
            debugPrint("查找出错：\(error)")
            return false
        }
    }
}

// MARK: - Video

extension DBManager {
    func insertVideo(item: Video) -> Int64? {
        guard let table = getTable(type: .video) else { return nil }
        let insert = table.insert(
            Column.title <- item.title,
            Column.desc <- item.desc,
            Column.tags <- item.tags,
            Column.preview <- item.preview,
            Column.file <- item.file,
            Column.md5 <- item.md5,
            Column.wallpaperEngineId <- item.wallpaperEngineId,
            Column.contentrating <- item.contentrating
        )
        return runInsert(insert)
    }

    // 改
    func updateVideo(id: Int64, item: Video) {
        guard let db = getDB(), let table = getTable(type: .video) else { return }
        do {
            let update = table.filter(rowid == id)
            let count = try db.run(update.update(
                Column.title <- item.title,
                Column.desc <- item.desc,
                Column.tags <- item.tags,
                Column.preview <- item.preview,
                Column.file <- item.file,
                Column.md5 <- item.md5,
                Column.wallpaperEngineId <- item.wallpaperEngineId,
                Column.contentrating <- item.contentrating,
                Column.updateTime <- Date.now
            ))
            debugPrint("更新的条数为：\(count)")
        } catch {
            debugPrint("更新出错：\(error)")
        }
    }

    func getVideo(id: Int64) -> Video? {
        guard let row = search(type: .video, filter: Column.id == id, limit: 1).first else { return nil }
        return row.toVideo()
    }
}

// MARK: - Playlist

extension DBManager {
    func insertPlaylist(item: Playlist) -> Int64? {
        guard let table = getTable(type: .playlist) else { return nil }
        let insert = table.insert(
            Column.title <- item.title,
            Column.videoIds <- item.videoIds
        )
        return runInsert(insert)
    }

    func updatePlaylist(id: Int64, item: Playlist) {
        guard let db = getDB(), let table = getTable(type: .playlist) else { return }
        do {
            let update = table.filter(Column.id == id)
            let count = try db.run(update.update(
                Column.title <- item.title,
                Column.videoIds <- item.videoIds,
                Column.updateTime <- Date.now
            ))
            debugPrint("更新的条数为：\(count)")
        } catch {
            debugPrint("更新出错：\(error)")
        }
    }

    func getPlaylist(id: Int64) -> Playlist? {
        guard let row = search(type: .playlist, filter: Column.id == id, limit: 1).first else { return nil }
        return row.toPlaylist()
    }
}

// MARK: - ScreenPlayConfig

extension DBManager {
    func insertScreenPlayConfig(item: ScreenPlayConfig) {
        guard let table = getTable(type: .screenPlayConfig) else { return }
        let insert = table.insert(
            Column.screenHash <- item.screenHash,
            Column.playlistId <- item.playlistId,
            Column.periodInMin <- item.periodInMin,
            Column.loopType <- item.loopType.rawValue
        )
        _ = runInsert(insert)
    }

    func updateScreenPlayConfig(id: Int64, item: ScreenPlayConfig) {
        guard let db = getDB(), let table = getTable(type: .screenPlayConfig) else { return }
        do {
            let update = table.filter(Column.id == id)
            let count = try db.run(update.update(
                Column.screenHash <- item.screenHash,
                Column.playlistId <- item.playlistId,
                Column.periodInMin <- item.periodInMin,
                Column.loopType <- item.loopType.rawValue,
                Column.updateTime <- Date.now
            ))
            debugPrint("更新的条数为：\(count)")
        } catch {
            debugPrint("更新出错：\(error)")
        }
    }

    func getScreenPlayConfig(screenHash: Int) -> ScreenPlayConfig? {
        guard let row = search(
            type: .screenPlayConfig,
            filter: Column.screenHash == screenHash,
            limit: 1
        ).first else { return nil }
        return row.toScreenPlayConfig()
    }
}
