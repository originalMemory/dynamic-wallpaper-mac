//
// Created by 吴厚波 on 2022/4/15.
//

extension String {
    func appendPathComponent(_ component: String) -> String {
        "\(self)/\(component)"
    }

    func removeExtension() -> String {
        var items = components(separatedBy: ".")
        items.removeLast()
        return items.joined(separator: ".")
    }
}
