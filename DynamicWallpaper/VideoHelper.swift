//
// Created by 吴厚波 on 2022/4/15.
//

import Foundation

let VideoImportIndexNotification: Notification.Name = .init(rawValue: "VideoImportIndexNotification")

/// 视频帮助类
///
/// 处理视频相关逻辑，如导入、管理等
class VideoHelper {
    static let share: VideoHelper = .init()

    private init() {}

    private lazy var queue: DispatchQueue = {
        DispatchQueue(label: "com.xuanniao.importVideo")
    }()

    func importVideo(filePaths: [String]) {
        queue.async {
            guard let cacheDir = self.getCacheDir() else {
                return
            }
            self.ensureDir(path: cacheDir)

            for i in 0..<filePaths.count {
                let path = filePaths[i]
                do {
                    var items = path.components(separatedBy: "/")
                    let filename = items.last!
                    items.removeLast()
                    let curDirPath = items.joined(separator: "/")
                    let model = Video()
                    model.title = filename.removeExtension()
                    model.file = filename

                    // Wallpaper Engine 解析
                    let projectJsonPath = curDirPath.appendPathComponent("project.json")
                    if FileManager.default.fileExists(atPath: projectJsonPath),
                       let jsonData = try? Data(contentsOf: URL(fileURLWithPath: projectJsonPath)),
                       let jsonObj = try? JSONSerialization.jsonObject(
                           with: jsonData,
                           options: .allowFragments
                       ) as? [String: Any]
                    {
                        model.contentrating = jsonObj["contentrating"] as? String
                        if let wallpaperEngineId = jsonObj["workshopid"] as? String {
                            model.wallpaperEngineId = Int64(wallpaperEngineId)
                        }
                        model.title = (jsonObj["title"] as? String) ?? ""
                        model.desc = jsonObj["description"] as? String
                        model.tags = (jsonObj["tags"] as? [String] ?? []).joined(separator: ",")
                        if let previewName = jsonObj["preview"] as? String,
                           FileManager.default.fileExists(atPath: curDirPath.appendPathComponent(previewName))
                        {
                            model.preview = previewName
                        }
                        if DBManager.share.exist(
                            fromTable: Table.video,
                            classType: Video.self,
                            where: Video.Properties.title.like(model.title)
                        ) {
                            debugPrint("文件已存在 \(filename) \(model.title)")
                            self.postProgressUpdate(index: i)
                            continue
                        }
                        DBManager.share.insertToDb(objects: [model], intoTable: Table.video)
                        let saveDir = cacheDir.appendPathComponent("\(model.lastInsertedRowID)")
                        self.ensureDir(path: saveDir)
                        try FileManager.default.copyItem(atPath: path, toPath: saveDir.appendPathComponent(filename))
                        if let previewName = model.preview {
                            try FileManager.default.copyItem(
                                atPath: curDirPath.appendPathComponent(previewName),
                                toPath: saveDir.appendPathComponent(previewName)
                            )
                        }
                    } else {
                        if DBManager.share.exist(
                            fromTable: Table.video,
                            classType: Video.self,
                            where: Video.Properties.file.is(filename)
                        ) {
                            debugPrint("文件已存在 \(filename)")
                            self.postProgressUpdate(index: i)
                            continue
                        }
                        DBManager.share.insertToDb(objects: [model], intoTable: Table.video)
                        let saveDir = cacheDir.appendPathComponent("\(model.lastInsertedRowID)")
                        self.ensureDir(path: saveDir)
                        try FileManager.default.copyItem(atPath: path, toPath: saveDir.appendPathComponent(filename))
                    }
                } catch {
                    debugPrint("导入失败 - \(error)")
                }
                self.postProgressUpdate(index: i)
            }
        }
    }

    private func postProgressUpdate(index: Int) {
        NotificationCenter.default.post(name: VideoImportIndexNotification, object: nil, userInfo: ["index": index])
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
