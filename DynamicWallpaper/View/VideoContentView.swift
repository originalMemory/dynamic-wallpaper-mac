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
        // 默认静音
        queuePlayer.isMuted = true
        queuePlayer.addObserver(self, forKeyPath: "status", options: .new, context: nil)

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
        wantsLayer = true
        playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer.frame = bounds
        playerLayer.contentsGravity = .resize
        playerLayer.videoGravity = .resizeAspectFill
        layer?.addSublayer(playerLayer)
    }

    deinit {
        queuePlayer.removeObserver(self, forKeyPath: "status")
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }

    // MARK: - 播放控制

    let queuePlayer = AVQueuePlayer()

    private var looper: AVPlayerLooper?
    private var url: URL?

    @objc func screensDidSleepNotification() {
        queuePlayer.pause()
    }

    @objc func screensDidWakeNotification() {
        queuePlayer.play()
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if queuePlayer.status == .readyToPlay {
            queuePlayer.play()
        }
    }

    func loadUrl(_ url: URL) {
        if self.url != url {
            let item = AVPlayerItem(url: url)
            guard item.asset.isPlayable else {
                return
            }

            self.url = url

            looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            if queuePlayer.status == .readyToPlay {
                queuePlayer.play()
            }
        }
    }
}
