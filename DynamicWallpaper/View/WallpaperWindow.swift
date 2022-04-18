//
// Created by 吴厚波 on 2022/4/18.
//

import Cocoa

class WallpaperWindow: NSWindow {
    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }

    convenience init(contentRect: NSRect, screen: NSScreen) {
        self.init(
            contentRect: contentRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        self.setup()
    }

    private func setup() {
        level = .init(Int(CGWindowLevelForKey(CGWindowLevelKey.desktopWindow)))
        hasShadow = false
//        isReleasedWhenClosed = false
        isMovableByWindowBackground = false
        ignoresMouseEvents = true
        collectionBehavior = [
            .canJoinAllSpaces, // 出瑞在所有桌面
            .stationary // 缩放不影响壁纸
        ]
        contentView = VideoContentView()
    }

    deinit {
        print("deinit", self)
    }

    func reload(url: URL) {
        if let view = contentView as? VideoContentView {
            view.loadUrl(url)
        }
    }

    override func update() {
        super.update()
        contentView?.frame = .init(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
    }
}
