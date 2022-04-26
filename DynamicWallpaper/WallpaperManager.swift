//
// Created by 吴厚波 on 2022/4/18.
//

import Foundation
import SwiftUI

let ScreenDidChangeNotification: Notification.Name = .init(rawValue: "ScreenDidChangeNotification")
let VideoDidChangeNotification: Notification.Name = .init(rawValue: "VideoDidChangeNotification")

class WallpaperManager {
    static let share = WallpaperManager()

    var preScreensHashValue: Int = 0
    private var monitors: [Monitor] = []

    private init() {}

    func setup() {
        loadConfig()
        // 初始化壁纸信息
        var screenInfos: [ScreenInfo] = []
        for screen in NSScreen.screens {
            screenInfos.append(ScreenInfo.from(screen: screen))
            let monitor = Monitor(screen: screen)
            monitors.append(monitor)
            let playlistId = UserDefaults.standard.string(forKey: getScreenPlaylistKey(screenHash: screen.hash))
            setPlaylistToMonitor(playlistId: Int64(playlistId ?? "") ?? 0, screenHash: screen.hash)
        }
        NotificationCenter.default.post(name: ScreenDidChangeNotification, object: screenInfos)

        // 监听screens 变化
        self.preScreensHashValue = NSScreen.screens.hashValue
        let observer = CFRunLoopObserverCreateWithHandler(
            kCFAllocatorDefault,
            CFRunLoopActivity.afterWaiting.rawValue,
            true,
            0
        ) { _, _ in
            let hashValue = NSScreen.screens.hashValue
            if self.preScreensHashValue != hashValue {
                self.preScreensHashValue = hashValue
                self.refreshWallpaper()
            }
        }
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
    }

    private func refreshWallpaper() {
        let screenHashValues = NSScreen.screens.map {
            $0.hash
        }
        monitors.removeAll { monitor in
            let notExist = !screenHashValues.contains(monitor.screen.hash)
            if notExist {
                monitor.window?.orderOut(nil)
            }
            return notExist
        }
        NotificationCenter.default.post(name: ScreenDidChangeNotification, object: nil)
    }

    func setWallpaper(screenHash: Int, videoName: String, videoUrl: URL) {
        guard let monitor = getMonitor(screenHash: screenHash) else {
            return
        }
        refreshWindow(monitor: monitor, videoName: videoName, videoUrl: videoUrl)
    }

    private func refreshWindow(monitor: Monitor, videoName: String, videoUrl: URL) {
        print("显示器：\(monitor.screen.localizedName), 壁纸：\(videoName)")
        NotificationCenter.default.post(
            name: VideoDidChangeNotification,
            object: nil,
            userInfo: [monitor.screen.hash: videoName]
        )
        monitor.videoName = videoName
        if monitor.window == nil {
            let screen = monitor.screen
            let window = WallpaperWindow(
                contentRect: .init(x: 0, y: 0, width: screen.frame.width, height: screen.frame.height),
                screen: screen
            )
            window.reload(url: videoUrl)
            window.backgroundColor = .clear
            window.orderFront(nil)
            monitor.window = window
        } else {
            monitor.window?.reload(url: videoUrl)
        }
    }

    private func removeWallpaper(screenHash: Int) {
        guard let monitor = getMonitor(screenHash: screenHash) else {
            return
        }
        monitor.window?.orderOut(nil)
        monitor.window = nil
    }

    func getMonitor(screenHash: Int) -> Monitor? {
        monitors.first(where: { $0.screen.hash == screenHash })
    }

    // MARK: - 列表播放控制

    private var timer: Timer?
    var config: PlayConfig?
    private let kConfig = "playConfig"
    private let kScreenPlaylist = "screenPlaylist_"

    private func loadConfig() {
        guard let jsonStr = UserDefaults.standard.string(forKey: kConfig),
              let data = jsonStr.data(using: .utf8),
              let config = try? JSONDecoder().decode(PlayConfig.self, from: data) else { return }
        startPlay(config: config)
    }

    func updateConfig(config: PlayConfig) {
        guard let jsonData = try? JSONEncoder().encode(config) else { return }
        let jsonStr = String(decoding: jsonData, as: UTF8.self)
        UserDefaults.standard.set(jsonStr, forKey: kConfig)
        startPlay(config: config)
    }

    private func startPlay(config: PlayConfig) {
        print("开始播放 \(config)")
        self.config = config
        stopPlay()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(config.periodInMin * 60), repeats: true) { timer in
            for monitor in self.monitors {
                guard let playlistId = monitor.playlistId,
                      let videos = self.getVideos(playlistId: playlistId) else { continue }
                let nextIndex = self.getNextIndex(type: config.loopType, count: videos.count, curIndex: monitor.index)
                monitor.index = nextIndex
                let video = videos[nextIndex]
                if let path = video.fullFilePath() {
                    self.refreshWindow(monitor: monitor, videoName: video.title, videoUrl: URL(fileURLWithPath: path))
                }
            }
        }
    }

    private func getNextIndex(type: PlayLoopType, count: Int, curIndex: Int = -1) -> Int {
        switch type {
        case .order:
            return curIndex < count - 1 ? curIndex + 1 : 0
        case .random:
            return Int.random(in: 0..<count)
        }
    }

    func stopPlay() {
        timer?.invalidate()
        timer = nil
    }

    private func getScreenPlaylistKey(screenHash: Int) -> String {
        "\(kScreenPlaylist)\(screenHash)"
    }

    func setPlaylistToMonitor(playlistId: Int64, screenHash: Int) {
        guard let monitor = getMonitor(screenHash: screenHash),
              let videos: [Video] = getVideos(playlistId: playlistId)
        else {
            return
        }
        UserDefaults.standard.set(String(playlistId), forKey: getScreenPlaylistKey(screenHash: screenHash))
        monitor.playlistId = playlistId
        let index = getNextIndex(type: config?.loopType ?? .order, count: videos.count)
        if let video = videos.safeValue(index: index), let path = video.fullFilePath() {
            monitor.index = index
            refreshWindow(monitor: monitor, videoName: video.title, videoUrl: URL(fileURLWithPath: path))
        }
    }

    private func getVideos(playlistId: Int64) -> [Video]? {
        guard let playlist = DBManager.share.getPlaylist(id: playlistId) else { return nil }
        return DBManager.share.search(
            type: .video,
            filter: playlist.videoIdList().contains(Column.id)
        ).map { $0.toVideo() }
    }

    /// 这两个方法是用于设置页面初始化信息
    func getScreenPlaylistName(screenHash: Int) -> String? {
        guard let playlistId = UserDefaults.standard.string(forKey: getScreenPlaylistKey(screenHash: screenHash)),
              let playlist = DBManager.share.getPlaylist(id: Int64(playlistId) ?? -1) else { return nil }
        return playlist.title
    }

    func getScreenPlayingVideoName(screenHash: Int) -> String? {
        getMonitor(screenHash: screenHash)?.videoName
    }
}
