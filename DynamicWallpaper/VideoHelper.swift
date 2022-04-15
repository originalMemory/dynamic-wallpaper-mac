//
// Created by 吴厚波 on 2022/4/15.
//

import Foundation

/// 视频帮助类
///
/// 处理视频相关逻辑，如导入、管理等
class VideoHelper {
    static let share: VideoHelper = .init()

    private init() {}

    func importVideo(filePaths: [String]) {
        guard let cacheDir = getCacheDir() else {
            return
        }
        ensureDir(path: cacheDir)

        for path in filePaths {
            do {
                var items = path.components(separatedBy: "/")
                let filename = items.last!
                items.removeLast()
                let curDirPath = items.joined(separator: "/")
                if DBManager.share.exist(
                    fromTable: Table.video,
                    classType: Video.self,
                    where: Video.Properties.file.is(filename)
                ) {
                    debugPrint("文件已存在 \(filename)")
                    continue
                }
                let model = Video()
                model.title = filename.removeExtension()
                model.file = filename
                DBManager.share.insertToDb(objects: [model], intoTable: Table.video)
                let saveDir = cacheDir.appendPathComponent("\(model.lastInsertedRowID)")
                ensureDir(path: saveDir)
                try FileManager.default.copyItem(atPath: path, toPath: saveDir.appendPathComponent(filename))

                // Wallpaper Engine 解析
                let projectJsonPath = curDirPath.appendPathComponent("project.json")
                if FileManager.default.fileExists(atPath: projectJsonPath),
                   let jsonData = try? Data(contentsOf: URL(fileURLWithPath: projectJsonPath)),
                   let jsonObj = try? JSONSerialization.jsonObject(
                       with: jsonData,
                       options: .allowFragments
                   ) as? [String: Any]
                {
                    model.title = (jsonObj["title"] as? String) ?? ""
                    model.desc = jsonObj["description"] as? String
                    model.tags = (jsonObj["tags"] as? [String] ?? []).joined(separator: ",")
                    if let previewName = jsonObj["preview"] as? String,
                       FileManager.default.fileExists(atPath: curDirPath.appendPathComponent(previewName))
                    {
                        try FileManager.default.copyItem(
                            atPath: curDirPath.appendPathComponent(previewName),
                            toPath: saveDir.appendPathComponent(previewName)
                        )
                        model.preview = previewName
                    }
                    DBManager.share.updateToDb(
                        table: Table.video,
                        on: [
                            Video.Properties.title,
                            Video.Properties.desc,
                            Video.Properties.tags,
                            Video.Properties.preview
                        ],
                        with: model,
                        where: Video.Properties.id.is(model.lastInsertedRowID)
                    )
                }
            } catch {
                debugPrint("导入失败 - \(error)")
            }
        }
    }

    /// 根据视频 id 和文件名获取文件完整路径
    func getFullPath(videoId: Int64, filename: String?) -> String? {
        getCacheDir()?.appendPathComponent("\(videoId)".appendPathComponent(filename ?? ""))
    }

    private func getCacheDir() -> String? {
        guard let cacheDirPath = NSSearchPathForDirectoriesInDomains(
            FileManager.SearchPathDirectory.documentDirectory,
            FileManager.SearchPathDomainMask.userDomainMask,
            true
        ).last else {
            return nil
        }
        return cacheDirPath.appendPathComponent("video")
    }

    private func ensureDir(path: String) {
        if FileManager.default.fileExists(atPath: path) {
            return
        }
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        } catch {
            debugPrint("创建文件夹失败 - \(error)")
        }
    }
}
