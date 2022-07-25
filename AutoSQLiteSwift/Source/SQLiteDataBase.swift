//
//  SQLiteDataBase.swift
//  AutoSQLite.swift
//
//  Created by QJ Technology on 2017/5/11.
//  Copyright © 2017年 TonyReet. All rights reserved.
//

import Foundation
import SQLite
import HandyJSON

public func sqlitePrint(
    debug: Any...,
    function: String = #function,
    file: String = #file,
    line: Int = #line
) {
    if !SQLiteManager.shared.printDebug { return }

    var filename = file
    if let match = filename.range(of: "[^/]*$", options: .regularExpression) {
        filename = String(filename[match])
    }
    Swift.print("Debug Log:\(filename),line:\(line),function:\(function)\n\(debug) \n")
}

public func sqlitePrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    if !SQLiteManager.shared.printDebug { return }

    Swift.print(items, separator: separator, terminator: terminator)
}

public func sqlitePrint<Target>(
    _ items: Any...,
    separator: String = " ",
    terminator: String = "\n",
    to output: inout Target
) where Target: TextOutputStream {
    if !SQLiteManager.shared.printDebug { return }

    Swift.print(items, separator: separator, terminator: terminator)
}

open class SQLiteDataBase: NSObject {
    // 创建单例
    public static let shared = SQLiteDataBase()

    fileprivate let default_DataBase_Name = "database"

    fileprivate var database: Connection?

    fileprivate var databasePath: String?

    fileprivate var databaseName: String?

    fileprivate var dataBaseTables: [String: Table] = [:]

    // MARK: - 类方法

    // 初始化db
    public class func createDB(_ dataBaseName: String) -> SQLiteDataBase {
        let sqliteDataBase = SQLiteDataBase.shared

        let defaultPath = sqliteDataBase.defaultPath()

        if sqliteDataBase.checkNameIsVerify(dataBaseName) {
            let databaseName = SQLiteDataBaseTool.removeBlankSpace(dataBaseName)

            sqliteDataBase.databaseName = databaseName
            sqliteDataBase.database = try? Connection("\(defaultPath)/\(databaseName).sqlite3")
            sqliteDataBase.databasePath = "\(defaultPath)/\(databaseName).sqlite3"
        } else {
            let default_DataBase_Name = sqliteDataBase.default_DataBase_Name
            sqliteDataBase.databaseName = default_DataBase_Name
            sqliteDataBase.database = try? Connection("\(defaultPath)/\(default_DataBase_Name).sqlite3")
            sqliteDataBase.databasePath = "\(defaultPath)/\(default_DataBase_Name).sqlite3"
        }

        sqlitePrint("数据库文件地址:\(String(describing: sqliteDataBase.databasePath))")

        return sqliteDataBase
    }

    // MARK: - 创建表

    public class func createTable(_ tableName: String, object: SQLiteModel) {
        createTable_statement(tableName, object: object)
    }

    // MARK: - 插入数据

    public class func insert(object: SQLiteModel, intoTable tableName: String) {
        insert_statement(object, intoTable: tableName)
    }

    public class func insertList(objectList: [SQLiteModel], intoTable tableName: String) {
        insertList_statement(objectList, intoTable: tableName)
    }

    // MARK: - 更新数据

    public class func update(_ object: SQLiteModel, fromTable tableName: String) {
        update_statement(object, fromTable: tableName)
    }

    public class func updateList(objectList: [SQLiteModel], fromTable tableName: String) {
        updateList_statement(objectList, fromTable: tableName)
    }

    // MARK: - 查询数据

    public class func selectAll(fromTable tableName: String) -> [[String: AnyObject]] {
        selectAll_statement(fromTable: tableName)
    }

    public class func select(_ object: SQLiteModel, fromTable tableName: String) -> [[String: AnyObject]]? {
        select_statement(object, fromTable: tableName)
    }

    // MARK: - 删除数据

    public class func delete(_ object: SQLiteModel, fromTable tableName: String) {
        delete_statement(object, fromTable: tableName)
    }

    public class func deleteWhere(_ sqlWhere: String, fromTable tableName: String) {
        deleteWhere_statement(sqlWhere, fromTable: tableName)
    }

    public class func drop(dropTable tableName: String) {
        drop_statement(dropTable: tableName)
    }

    // MARK: - 示例方法

    /// 创建表
    ///
    /// - Parameters:
    ///   - tableName: 创建的表名
    ///   - sqlMirrorModel:转换完的model
    public func createTable(_ tableName: String, sqlMirrorModel: SQLMirrorModel) {
        createTable_statement(tableName, sqlMirrorModel: sqlMirrorModel)
    }

    /// 根据object插入
    ///
    /// - Parameters:
    ///   - object: object
    ///   - tableName: 需要插入的tableName
    public func insert(_ object: SQLiteModel, intoTable tableName: String) {
        save_statement(object, intoTable: tableName)
    }

    /// 根据object修改数据库
    ///
    /// - Parameters:
    ///   - object: 需要修改的object
    ///   - tableName: tableName
    public func update(_ object: SQLiteModel, fromTable tableName: String) {
        save_statement(object, intoTable: tableName)
    }

    /// 查询数据
    ///
    /// - Parameters:
    ///   - tableName: 表名
    ///   - sqlWhere: sql查询语句
    /// - Returns: 返回结果
    public func select(fromTable tableName: String, sqlWhere: String? = nil) -> [[String: AnyObject]] {
        select_statementWithSQL(fromTable: tableName, sqlWhere: sqlWhere)
    }

    public func selectModel<T: HandyJSON>(fromTable tableName: String, sqlWhere: String? = nil) -> [T] {
        let dis = select(fromTable: tableName, sqlWhere: sqlWhere)
        var res: [T] = []
        for di in dis {
            var finalDi: [String: Any] = di
            for (key, value) in di {
                guard let stringValue = value as? String,
                      stringValue.contains("\"") || stringValue.contains("["),
                      let json = stringValue.toJson()
                else { continue }
                finalDi[key] = json
            }
            guard let t = T.deserialize(from: finalDi) else { continue }
            res.append(t)
        }
        return res
    }

    public func select(_ object: SQLiteModel, fromTable tableName: String) -> [[String: AnyObject]]? {
        select_statement(object, fromTable: tableName)
    }

    /// 删除table里面的字段
    ///
    /// - Parameters:
    ///   - tableName: table
    ///   - sqlWhere: 执行的where语句
    public func delete(fromTable tableName: String, sqlWhere: String) {
        delete_statement(fromTable: tableName, sqlWhere: sqlWhere)
    }

    public func delete(_ object: SQLiteModel, fromTable tableName: String) {
        delete_statement(object, fromTable: tableName)
    }

    /// 删除整张表
    ///
    /// - Parameter tableName: 删除的表名
    public func drop(dropTable tableName: String) {
        drop_statement(dropTable: tableName)
    }

    // MARK: - 获取默认的路径地址

    public func defaultPath() -> String {
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        else {
            return NSHomeDirectory()
        }

        return documentsPath
    }

    // MARK: - Tool Func

    // 检查tableName是否有效
    public func checkNameIsVerify(_ name: String) -> Bool {
        if name.count == 0 {
            sqlitePrint("name: \(name) format error")
            return false
        }

        return true
    }
}

// MARK: - 所有sql执行相关的方法

public extension SQLiteDataBase {
    // MARK: - 类方法

    class func createTable_statement(_ tableName: String, object: SQLiteModel) {
        let sqliteDataBase = SQLiteDataBase.shared

        guard let sqlMirrorModel = SQLMirrorModel.operateByMirror(object: object) else {
            return
        }

        sqliteDataBase.createTable_statement(tableName, sqlMirrorModel: sqlMirrorModel)
    }

    class func insert_statement(_ object: SQLiteModel, intoTable tableName: String) {
        let sqliteDataBase = SQLiteDataBase.shared

        sqliteDataBase.save_statement(object, intoTable: tableName)
    }

    class func insertList_statement(_ objectList: [SQLiteModel], intoTable tableName: String) {
        let sqliteDataBase = SQLiteDataBase.shared

        for object in objectList {
            sqliteDataBase.save_statement(object, intoTable: tableName)
        }
    }

    class func update_statement(_ object: SQLiteModel, fromTable tableName: String) {
        let sqliteDataBase = SQLiteDataBase.shared

        sqliteDataBase.save_statement(object, intoTable: tableName)
    }

    class func updateList_statement(_ objectList: [SQLiteModel], fromTable tableName: String) {
        let sqliteDataBase = SQLiteDataBase.shared

        for object in objectList {
            sqliteDataBase.save_statement(object, intoTable: tableName)
        }
    }

    class func selectAll_statement(fromTable tableName: String) -> [[String: AnyObject]] {
        let sqliteDataBase = SQLiteDataBase.shared

        return sqliteDataBase.select_statementWithSQL(fromTable: tableName, sqlWhere: nil)
    }

    class func select_statement(_ object: SQLiteModel, fromTable tableName: String) -> [[String: AnyObject]]? {
        let sqliteDataBase = SQLiteDataBase.shared

        return sqliteDataBase.select_statement(object, fromTable: tableName)
    }

    class func delete_statement(_ object: SQLiteModel, fromTable tableName: String) {
        let sqliteDataBase = SQLiteDataBase.shared

        guard let sqlMirrorModel = SQLMirrorModel.operateByMirror(object: object) else {
            return
        }

        for sqlProperty in sqlMirrorModel.sqlProperties {
            let key = sqlProperty.key

            guard key == sqlMirrorModel.sqlPrimaryKey else {
                continue
            }

            sqliteDataBase.delete_statement(
                fromTable: tableName,
                sqlWhere: "\(key) = '\(String(describing: sqlProperty.value))'"
            )
        }
    }

    class func deleteWhere_statement(_ sqlWhere: String, fromTable tableName: String) {
        let sqliteDataBase = SQLiteDataBase.shared

        sqliteDataBase.delete_statement(fromTable: tableName, sqlWhere: sqlWhere)
    }

    class func drop_statement(dropTable tableName: String) {
        let sqliteDataBase = SQLiteDataBase.shared
        sqliteDataBase.drop_statement(dropTable: tableName)
    }

    // MARK: - 实例方法

    func createTable_statement(_ tableName: String, sqlMirrorModel: SQLMirrorModel) {
        if !checkNameIsVerify(tableName) {
            sqlitePrint("failed to create table: \(tableName)")
            return
        }

        let tableFinalName = SQLiteDataBaseTool.removeBlankSpace(tableName)

        if tableExists(tableName: tableFinalName) == true {
            return
        }

        // 创建表
        var sqlStr = "CREATE TABLE IF NOT EXISTS " + tableFinalName

        // 主键
        let primaryKey = sqlMirrorModel.sqlPrimaryKey

        // 拼接动态字段
        var keyStr = ""
        for sqlProperty in sqlMirrorModel.sqlProperties {
            let key = sqlProperty.key
            if key == primaryKey {
                continue
            }
            let type = sqlProperty.type

            keyStr += "\(key) \(SQLiteDataBaseTool.sqlType(type)),"
        }

        // 添加主键
        sqlStr += "(" + primaryKey + " INTEGER UNIQUE PRIMARY KEY NOT NULL,"

        sqlStr += SQLiteDataBaseTool.removeLastStr(keyStr)

        sqlStr += ")"

        sqlitePrint("create sqlStr:\(sqlStr)")
        execute(sqlStr)
    }

    func isExistObject(_ object: SQLiteModel, tableName: String) -> (Bool, String?) {
        guard database != nil, object.primaryValue() > 0 else {
            return (false, nil)
        }

        /* 只查询是否存在，为了统一，查询是否存在，使用select_statement
         let sqlStr = "SELECT COUNT(*) FROM \(tableName) where \(whereStr)"
         let isExists = try database?.scalar(sqlStr) as! Int64 > 0
         */

        var whereStr = getPrimaryWhere(object, tableName: tableName)

        // 可以使用下面的函数，不使用效率高
        guard let results = select_statement(object, fromTable: tableName) else {
            return (false, nil)
        }

        // 如果查找到多个结果，说明查找的数据不唯一，认定为没有同种结果
        if results.count > 1 {
            return (false, nil)
        }

        return (true, whereStr)
    }

    func getPrimaryWhere(_ object: SQLiteModel, tableName: String) -> String? {
        guard let sqlMirrorModel = SQLMirrorModel.operateByMirror(object: object) else {
            return nil
        }
        let primaryKey = sqlMirrorModel.sqlPrimaryKey
        guard let primaryValue = sqlMirrorModel.sqlProperties.first { model in model.key == primaryKey }?.value
        else { return nil }
        return "\(primaryKey) = \(primaryValue)"
    }

    func save_statement(_ object: SQLiteModel, intoTable tableName: String) {
        guard let sqlMirrorModel = SQLMirrorModel.operateByMirror(object: object) else {
            return
        }

        createTable_statement(tableName, sqlMirrorModel: sqlMirrorModel)

        var keyStr = ""
        var valueStr = ""

        let (isExist, whereStr) = isExistObject(object, tableName: tableName)
        for sqlProperty in sqlMirrorModel.sqlProperties {
            let key = sqlProperty.key
            guard let value = sqlProperty.value else {
                continue
            }

            let isNil = valueIsNil(sqlProperty.value)

            if isNil == true {
                continue
            }

            let s1 = "\(value)"
            let strValue = "\(value)".replacingOccurrences(of: "'", with: "''")

            if isExist == true { // 存在
                /// 如果字段不存在，则创建
                addColumnIfNoExist_statement(
                    key,
                    tableName: tableName,
                    type: SQLiteDataBaseTool.sqlType(sqlProperty.type)
                )

                valueStr = whereStr ?? ""

                // tmpStr
                let tmpStr = "\(key) = '\(strValue)' ,"

                keyStr += tmpStr
            } else { // 不存在
                keyStr += (key + " ,")
                valueStr += "'\(strValue)' ,"
            }
        }

        keyStr = SQLiteDataBaseTool.removeLastStr(keyStr)

        var sqlStr = ""
        if isExist == true { // 存在
            sqlStr = "UPDATE \(tableName) SET \(keyStr) WHERE \(valueStr)"
        } else { // 不存在
            valueStr = SQLiteDataBaseTool.removeLastStr(valueStr)
            sqlStr = "INSERT INTO \(tableName) (\(keyStr)) VALUES (\(valueStr))"
        }

        execute(sqlStr)
    }

    func select_statementWithSQL(fromTable tableName: String, sqlWhere: String? = nil) -> [[String: AnyObject]] {
        if tableExists(tableName: tableName) == false {
            return [[String: AnyObject]]()
        }

        var sqlStr = ""

        if let sqlWhere = sqlWhere {
            sqlStr = "SELECT * FROM \(tableName) WHERE \(sqlWhere)"
        } else {
            sqlStr = "SELECT * FROM \(tableName)"
        }

        let results = prepare(sqlStr)

        return results
    }

    func select_statement(_ object: SQLiteModel, fromTable tableName: String) -> [[String: AnyObject]]? {
        guard let whereStr = getPrimaryWhere(object, tableName: tableName) else {
            return nil
        }

        var sqlStr = ""
        if whereStr != nil {
            sqlStr = "SELECT * FROM \(tableName) WHERE \(whereStr)"
        } else {
            sqlStr = "SELECT * FROM \(tableName)"
        }

        let results = prepare(sqlStr)

        sqlitePrint("sqlStr:\(sqlStr)")

        return results.count > 0 ? results : nil
    }

    func delete_statement(fromTable tableName: String, sqlWhere: String) {
        if tableExists(tableName: tableName) == false {
            return
        }

        let sqlStr = "DELETE FROM \(tableName) WHERE \(sqlWhere)"
        execute(sqlStr)
    }

    func delete_statement(_ object: SQLiteModel, fromTable tableName: String) {
        let whereStr = getPrimaryWhere(object, tableName: tableName)

        if let whereStr = whereStr {
            delete_statement(fromTable: tableName, sqlWhere: whereStr)
        } else {
            sqlitePrint("没有找到对应的主键")
        }
    }

    func drop_statement(dropTable tableName: String) {
        if tableExists(tableName: tableName) == false {
            return
        }

        let sqlStr = "DROP TABLE \(tableName)"
        execute(sqlStr)
    }

    func addColumnIfNoExist_statement(_ columnName: String, tableName: String, type: String) {
        let sqlStr = "select sql from sqlite_master where type='table' and name='\(tableName)';"
        guard tableExists(tableName: tableName),
              let tableSql = prepare(sqlStr).first?["sql"] as? String,
              let start = tableSql.firstIndex(of: "("),
              let end = tableSql.lastIndex(of: ")")
        else {
            return
        }
        // pkid INTEGER UNIQUE PRIMARY KEY NOT NULL,title TEXT,desc TEXT,tags TEXT
        let columnStr = tableSql.substring(with: (tableSql.index(start, offsetBy: 1))..<end)
        // TODO： 修改列类型
        if columnStr.contains(columnName) {
            return
        }
        let alterSqlStr = "ALTER TABLE " + tableName + " ADD \(columnName) \(type)"
        execute(alterSqlStr)
    }

    // https://github.com/stephencelis/SQLite.swift/issues/6
    func tableExists(tableName: String) -> Bool {
        guard database != nil else {
            return false
        }

        do {
            let isExists = try database?.scalar(
                "SELECT EXISTS (SELECT * FROM sqlite_master WHERE type = 'table' AND name = ?)", tableName
            ) as! Int64 > 0
            if !isExists {
                sqlitePrint("数据库表: 不存在")
            }
            return isExists
        } catch {
            sqlitePrint(error)
            return false
        }
    }

    /// 执行sql语句
    ///
    /// - Parameters:
    ///   - sqlStr: sql语句
    ///   - finish: 结束的闭包
    ///   - fail: 失败的闭包
    func execute(_ sqlStr: String, finish: () -> Void = {}, fail: () -> Void = {}) {
        do {
            sqlitePrint("sql语句:\(sqlStr)")
            try database?.execute(sqlStr)
            finish()
        } catch {
            sqlitePrint(error)
            fail()
        }
    }

    /// 查询数据
    ///
    /// - Parameter sqlStr: 查询的语句
    /// - Returns: 返回查询的数据，因为可能是多个，并且每个都以字典类型返回
    /// - 所以是数据类型是[[String:AnyObject]],[String:AnyObject]是字典类型
    func prepare(_ sqlStr: String) -> [[String: AnyObject]] {
        var elements: [[String: AnyObject]] = []

        do {
            let results = try database?.prepare(sqlStr)

            if let results = results {
                let columnSize = results.columnNames.count

                for row in results {
                    var record: [String: AnyObject] = [:]

                    for i in 0..<columnSize {
                        let value = row[i]
                        let key = results.columnNames[i] as String

                        if let value = value {
                            record.updateValue(value as AnyObject, forKey: key)
                        }
                    }

                    elements.append(record)
                }
            }
        } catch {
            sqlitePrint(error)
        }

        return elements
    }

    internal func valueIsNil(_ value: AnyObject?) -> Bool {
        // 值为空不需要处理
        guard let value = value else {
            return true
        }

        if value is NSNull {
            return true
        }

        if value.isKind(of: NSNumber.self), (value as! NSNumber).intValue == 0 {
            return true
        }

        return false
    }
}
