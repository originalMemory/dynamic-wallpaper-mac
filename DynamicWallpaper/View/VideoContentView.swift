//
// Created by 吴厚波 on 2022/4/18.
//

import Foundation
import Cocoa
import AVFoundation

class VideoContentView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.black.set()
        dirtyRect.fill()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.commInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commInit()
    }

    var playerLayer: AVPlayerLayer!

    func commInit() {
        wantsLayer = true

        playerLayer = AVPlayerLayer(player: VideoSharePlayer.shared.queuePlayer)
        playerLayer.frame = bounds
        playerLayer.contentsGravity = .resize
        playerLayer.videoGravity = .resizeAspectFill
        layer?.addSublayer(playerLayer)
    }

    func loadUrl(_ url: URL) {
        VideoSharePlayer.shared.loadUrl(url)
    }

    override func layout() {
        super.layout()
        playerLayer.frame = self.bounds
    }
}

// MARK: - VideoSharePlayer

private class VideoSharePlayer: NSObject {
    static let shared = VideoSharePlayer()

    let queuePlayer = AVQueuePlayer()

    private var looper: AVPlayerLooper?
    private var url: URL?

    override private init() {
        super.init()

        self.queuePlayer.isMuted = true
        self.queuePlayer.addObserver(self, forKeyPath: "status", options: .new, context: nil)

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(screensDidSleepNotification),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(screensDidWakeNotification),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }

    @objc func screensDidSleepNotification() {
        self.queuePlayer.pause()
    }

    @objc func screensDidWakeNotification() {
        self.queuePlayer.play()
    }

    @objc func wallpaperDidChangeNotification() {
        self.queuePlayer.pause()
        self.url = nil
        self.looper = nil
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if self.queuePlayer.status == .readyToPlay {
            self.queuePlayer.play()
        }
    }

    func loadUrl(_ url: URL) {
        if self.url != url {
            let item = AVPlayerItem(url: url)
            guard item.asset.isPlayable else {
                return
            }

            self.url = url

            self.looper = AVPlayerLooper(player: self.queuePlayer, templateItem: item)

            if self.queuePlayer.status == .readyToPlay {
                self.queuePlayer.play()
            }
        }
    }
}
