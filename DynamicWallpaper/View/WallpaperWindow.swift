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
        level = .init(Int(CGWindowLevelForKey(CGWindowLevelKey.desktopWindow)) - 1)
        hasShadow = false
        isReleasedWhenClosed = false
        ignoresMouseEvents = true
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
        self.contentView?.frame = .init(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
    }
}
