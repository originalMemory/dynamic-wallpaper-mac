//
// Created by 吴厚波 on 2022/7/21.
//

import Foundation

// MARK: 字典转字符串

extension Dictionary {
    func toJsonString() -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: []),
              let str = String(data: data, encoding: .utf8)
        else { return "{}" }
        return str
    }
}

extension Array {
    func toJsonString() -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: []),
              let str = String(data: data, encoding: .utf8)
        else { return "[]" }
        return str
    }
}

extension String {
    func toJson() -> Any? {
        guard let data = data(using: String.Encoding.utf8, allowLossyConversion: false),
              let json = try? JSONSerialization.jsonObject(
                  with: data,
                  options: .fragmentsAllowed
              )
        else { return nil }
        return json
    }
}
