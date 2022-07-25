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
        // 初始化壁纸信息
        var screenInfos: [ScreenInfo] = []
        for screen in NSScreen.screens {
            screenInfos.append(ScreenInfo.from(screen: screen))
            let monitor = Monitor(screen: screen)
            monitors.append(monitor)
        }
        loadConfig()
        NotificationCenter.default.post(name: ScreenDidChangeNotification, object: screenInfos)

        // 监听screens 变化
        preScreensHashValue = NSScreen.screens.hashValue
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

    func setWallpaper(screenHash: Int, videoName: String, videoUrl: URL, cleanPlaylist: Bool) {
        guard let monitor = getMonitor(screenHash: screenHash) else {
            return
        }
        refreshWindow(monitor: monitor, videoName: videoName, videoUrl: videoUrl)
        if cleanPlaylist, let config = getConfig(screenHash: screenHash) {
            config.playlistId = nil
            addOrUpdateConfig(config: config)
        }
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
            window.backgroundColor = .clear
            window.orderFront(nil)
            monitor.window = window
        }
        monitor.window?.reload(url: videoUrl)
        monitor.window?.setVolume(screenConfigs.first { $0.screenHash == monitor.screen.hash }?.volume ?? 0.0)
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

    var screenConfigs = [ScreenPlayConfig]()
    var screenHash2Timer = [Int: Timer]()

    private func loadConfig() {
        let hashStr = NSScreen.screens.map { String($0.hash) }.joined(separator: ",")
        DBManager.share.delete(type: .screenPlayConfig, id: 3)
        screenConfigs = DBManager.share.searchScreenPlayConfigs(sqlWhere: "screenHash IN (\(hashStr))")
        stopPlay()
        for config in screenConfigs {
            let timer = Timer.scheduledTimer(
                withTimeInterval: TimeInterval(config.periodInMin * 60),
                repeats: true
            ) { timer in
                self.switch2NextWallpaper(screenHash: config.screenHash)
            }
            timer.fire()
            screenHash2Timer[config.screenHash] = timer
        }
    }

    func addOrUpdateConfig(config: ScreenPlayConfig) {
        if config.pkid > 0 {
            DBManager.share.update(type: .screenPlayConfig, obj: config)
        } else {
            DBManager.share.insert(type: .screenPlayConfig, obj: config)
            if let newConfig: ScreenPlayConfig = DBManager.share.searchAll(
                type: .screenPlayConfig,
                sqlWhere: "screenHash=\(config.screenHash)"
            ).first {
                screenConfigs.append(newConfig)
            }
        }
        let key = config.screenHash
        screenHash2Timer[key]?.invalidate()
        screenHash2Timer[key] = nil
        if config.playlistId != nil {
            screenHash2Timer[key] = Timer.scheduledTimer(
                withTimeInterval: TimeInterval(config.periodInMin * 60),
                repeats: true
            ) { timer in
                self.switch2NextWallpaper(screenHash: key)
            }
            screenHash2Timer[key]?.fire()
        }
    }

    func getConfig(screenHash: Int) -> ScreenPlayConfig? {
        screenConfigs.first { config in config.screenHash == screenHash }
    }

    func switchAll2NextWallpaper() {
        for screen in NSScreen.screens {
            switch2NextWallpaper(screenHash: screen.hash)
        }
    }

    func switch2NextWallpaper(screenHash: Int) {
        guard let config = screenConfigs.first(where: { $0.screenHash == screenHash }),
              let monitor = getMonitor(screenHash: screenHash),
              let playlistId = config.playlistId,
              let videos = getVideos(playlistId: playlistId)
        else { return }
        let nextIndex = getNextIndex(type: config.loopType, count: videos.count, curIndex: config.curIndex)
        config.curIndex = nextIndex
        DBManager.share.update(type: .screenPlayConfig, obj: config)
        let video = videos[nextIndex]
        if let path = video.fullFilePath() {
            refreshWindow(monitor: monitor, videoName: video.title, videoUrl: URL(fileURLWithPath: path))
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
        screenHash2Timer.forEach { key, value in value.invalidate() }
        screenHash2Timer.removeAll()
    }

    func setPlaylistToMonitor(playlistId: Int, screenHash: Int) {
        let config = getConfig(screenHash: screenHash) ?? ScreenPlayConfig(screenHash: screenHash)
        if config.playlistId == playlistId {
            return
        }
        config.playlistId = playlistId
        config.curIndex = -1
        addOrUpdateConfig(config: config)
    }

    func removePlaylistToMonitor(screenHash: Int) {
        guard let config = getConfig(screenHash: screenHash) else { return }
        config.playlistId = nil
        config.curIndex = -1
        addOrUpdateConfig(config: config)
        screenHash2Timer[screenHash]?.invalidate()
        screenHash2Timer[screenHash] = nil
        removeWallpaper(screenHash: screenHash)
    }

    private func getVideos(playlistId: Int) -> [Video]? {
        guard let playlist = DBManager.share.getPlaylist(id: playlistId) else { return nil }
        return DBManager.share.searchVideos(sqlWhere: "rowid IN (\(playlist.videoIdInStr()))")
    }

    /// 这两个方法是用于设置页面初始化信息
    func getScreenPlaylistName(screenHash: Int) -> String? {
        guard let playlistId = getConfig(screenHash: screenHash)?.playlistId,
              let playlist = DBManager.share.getPlaylist(id: playlistId)
        else { return nil }
        return playlist.title
    }

    func getScreenPlayingVideoName(screenHash: Int) -> String? {
        getMonitor(screenHash: screenHash)?.videoName
    }
}
