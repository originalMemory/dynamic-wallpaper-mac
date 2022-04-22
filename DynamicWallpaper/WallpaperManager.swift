//
// Created by 吴厚波 on 2022/4/18.
//

import Foundation
import SwiftUI

let ScreenDidChangeNotification: Notification.Name = .init(rawValue: "ScreenDidChangeNotification")

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

        loadConfig()
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

    func setWallpaper(screenHash: Int, videoUrl: URL) {
        guard let monitor = getMonitor(screenHash: screenHash) else {
            return
        }
        refreshWindow(monitor: monitor, videoUrl: videoUrl)
    }

    private func refreshWindow(monitor: Monitor, videoUrl: URL) {
        print("显示器：\(monitor.screen.localizedName), 壁纸：\(videoUrl.absoluteString)")
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

    private func getMonitor(screenHash: Int) -> Monitor? {
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
                let count = monitor.videoUrls.count
                if count <= 1 {
                    continue
                }
                let nextIndex: Int
                switch config.loopType {
                case .order:
                    if monitor.urlIndex < count - 1 {
                        nextIndex = monitor.urlIndex + 1
                    } else {
                        nextIndex = 0
                    }
                case .random:
                    nextIndex = Int.random(in: 0..<count)
                }
                monitor.urlIndex = nextIndex
                self.refreshWindow(monitor: monitor, videoUrl: monitor.videoUrls[nextIndex])
            }
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
              let playlists: [Playlist] = DBManager.share.queryFromDb(
                  fromTable: Table.playlist,
                  where: Video.Properties.id.is(playlistId)
              ),
              let videoIds = playlists.first?.videoIdList(),
              let videos: [Video] = DBManager.share.queryFromDb(
                  fromTable: Table.video,
                  where: Video.Properties.id.in(videoIds)
              )
        else {
            return
        }
        UserDefaults.standard.set(String(playlistId), forKey: getScreenPlaylistKey(screenHash: screenHash))
        monitor.videoUrls = videos.compactMap { $0.fullFilePath() }.map { URL(fileURLWithPath: $0) }
        monitor.urlIndex = 0
        if let url = monitor.videoUrls.first {
            refreshWindow(monitor: monitor, videoUrl: url)
        }
    }
}
