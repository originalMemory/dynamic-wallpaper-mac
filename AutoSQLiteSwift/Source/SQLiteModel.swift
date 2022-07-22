//
//  SQLiteModel.swift
//  AutoSQLite.swift
//
//  Created by QJ Technology on 2017/5/12.
//  Copyright © 2017年 TonyReet. All rights reserved.
//

import Foundation
import HandyJSON

// modify_future
/// 先使用这个基类进行操作，后续这个基类需要改为protocol

/// 基类
open class SQLiteModel: NSObject, HandyJSON {
    override public required init() {
        super.init()
    }

    /// 主键字段
    open func primaryKey() -> String? {
        "pkid"
    }

    func primaryValue() -> Int {
        let mirror = SQLMirrorModel.operateByMirror(object: self)
        return mirror?.sqlProperties.first { $0.key == primaryKey() }?.value as? Int ?? 0
    }

    /// 忽略的字段，不保存
    open func ignoreKeys() -> [String]? {
        nil
    }
}
