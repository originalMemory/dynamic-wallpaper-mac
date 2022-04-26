//
// Created by 吴厚波 on 2022/4/15.
//

import Foundation
import SQLite
import CommonCrypto

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
                    let md5 = self.md5File(url: URL(fileURLWithPath: path)) ?? ""
                    if DBManager.share.exist(
                        type: .video,
                        filter: Column.md5 == md5
                    ) {
                        debugPrint("文件已存在 \(path)")
                        self.postProgressUpdate(index: i)
                        continue
                    }

                    var items = path.components(separatedBy: "/")
                    let filename = items.last!
                    items.removeLast()
                    let curDirPath = items.joined(separator: "/")
                    let title = filename.removeExtension()

                    // Wallpaper Engine 解析
                    let projectJsonPath = curDirPath.appendPathComponent("project.json")
                    if FileManager.default.fileExists(atPath: projectJsonPath),
                       let jsonData = try? Data(contentsOf: URL(fileURLWithPath: projectJsonPath)),
                       let jsonObj = try? JSONSerialization.jsonObject(
                           with: jsonData,
                           options: .allowFragments
                       ) as? [String: Any]
                    {
                        let title: String = (jsonObj["title"] as? String) ?? ""
                        let desc: String? = jsonObj["description"] as? String
                        let model = Video(
                            videoId: 0,
                            title: title,
                            desc: desc,
                            tags: (jsonObj["tags"] as? [String] ?? []).joined(separator: ","),
                            preview: jsonObj["preview"] as? String,
                            file: filename,
                            md5: md5,
                            wallpaperEngineId: jsonObj["workshopid"] as? String,
                            contentrating: jsonObj["workshopid"] as? String
                        )
                        guard let rowId = DBManager.share.insertVideo(item: model) else { continue }
                        let saveDir = cacheDir.appendPathComponent(String(rowId))
                        self.ensureDir(path: saveDir)
                        try FileManager.default.copyItem(atPath: path, toPath: saveDir.appendPathComponent(filename))
                        if let previewName = model.preview,
                           FileManager.default.fileExists(atPath: curDirPath.appendPathComponent(previewName))
                        {
                            try FileManager.default.copyItem(
                                atPath: curDirPath.appendPathComponent(previewName),
                                toPath: saveDir.appendPathComponent(previewName)
                            )
                        }
                    } else {
                        let model = Video(
                            videoId: 0,
                            title: title,
                            desc: "",
                            tags: "",
                            preview: "",
                            file: filename,
                            md5: md5,
                            wallpaperEngineId: nil,
                            contentrating: nil
                        )
                        guard let rowId = DBManager.share.insertVideo(item: model) else { continue }
                        let saveDir = cacheDir.appendPathComponent(String(rowId))
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

    private func md5File(url: URL) -> String? {
        let bufferSize = 1024 * 1024

        do {
            // 打开文件
            let file = try FileHandle(forReadingFrom: url)
            defer {
                file.closeFile()
            }

            // 初始化内容
            var context = CC_MD5_CTX()
            CC_MD5_Init(&context)

            // 读取文件信息
            while case let data = file.readData(ofLength: bufferSize), data.count > 0 {
                data.withUnsafeBytes {
                    _ = CC_MD5_Update(&context, $0, CC_LONG(data.count))
                }
            }

            // 计算Md5摘要
            var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes {
                _ = CC_MD5_Final($0, &context)
            }

            return digest.map { String(format: "%02hhx", $0) }.joined()

        } catch {
            print("Cannot open file:", error.localizedDescription)
            return nil
        }
    }
}
