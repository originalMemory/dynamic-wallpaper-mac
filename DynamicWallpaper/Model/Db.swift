//
// Created by 吴厚波 on 2022/4/13.
//

import Foundation
import WCDBSwift

struct HMDataBasePath {
    let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last! + "/DB.db"
}

enum Table: String, CaseIterable {
    case video = "videoTable"
    case playlist = "playlistTable"
}

class DBManager: NSObject {
    static let share = DBManager()

    let dataBasePath = URL(fileURLWithPath: HMDataBasePath().dbPath)
    var dataBase: Database?

    override private init() {
        super.init()
        dataBase = createDb()
    }

    func setupTables() {
        createTable(table: Table.video, of: Video.self)
        createTable(table: Table.playlist, of: Playlist.self)
    }

    /// 创建db
    private func createDb() -> Database {
        debugPrint("数据库路径==\(dataBasePath.absoluteString)")
        return Database(withFileURL: dataBasePath)
    }

    /// 创建表
    func createTable<T: TableDecodable>(table: Table, of type: T.Type) -> Void {
        do {
            try dataBase?.create(table: table.rawValue, of: type)
        } catch {
            debugPrint("create table error \(error.localizedDescription)")
        }
    }

    /// 插入
    func insertToDb<T: TableEncodable>(objects: [T], intoTable table: Table) -> Void {
        do {
            try dataBase?.insert(objects: objects, intoTable: table.rawValue)
        } catch {
            debugPrint(" insert obj error \(error.localizedDescription)")
        }
    }

    /// 修改
    func updateToDb<T: TableEncodable>(
        table: Table,
        on properties: [PropertyConvertible],
        with object: T,
        where condition: Condition? = nil
    ) -> Void {
        do {
            try dataBase?.update(table: table.rawValue, on: properties, with: object, where: condition)
        } catch {
            debugPrint(" update obj error \(error.localizedDescription)")
        }
    }

    /// 删除
    func deleteFromDb(fromTable: Table, where condition: Condition? = nil) {
        do {
            try dataBase?.delete(fromTable: fromTable.rawValue, where: condition)
        } catch {
            debugPrint("delete error \(error.localizedDescription)")
        }
    }

    /// 查询
    func queryFromDb<T: TableDecodable>(
        fromTable: Table,
        where condition: Condition? = nil,
        orderBy orderList: [OrderBy]? = nil,
        limit: Limit? = nil,
        offset: Offset? = nil
    ) -> [T]? {
        do {
            let allObjects: [T] = try (dataBase?.getObjects(
                fromTable: fromTable.rawValue,
                where: condition,
                orderBy: orderList,
                limit: limit,
                offset: offset
            ))!
            return allObjects
        } catch {
            debugPrint("no data find \(error.localizedDescription)")
        }
        return nil
    }

    /// 是否存在符合条件的元素
    func exist<T: TableCodable>(fromTable: Table, classType: T.Type, where condition: Condition) -> Bool {
        do {
            let obj: T? = try dataBase?.getObject(fromTable: fromTable.rawValue, where: condition)
            return obj != nil
        } catch {
            debugPrint("no data find \(error.localizedDescription)")
            return false
        }
    }

    /// 删除数据表
    func dropTable(table: Table) {
        do {
            try dataBase?.drop(table: table.rawValue)
        } catch {
            debugPrint("drop table error \(error)")
        }
    }

    ///  删除所有与该数据库相关的文件
    func removeDbFile() {
        do {
            try dataBase?.close(onClosed: {
                try dataBase?.removeFiles()
            })
        } catch {
            debugPrint("not close db \(error)")
        }
    }
}
