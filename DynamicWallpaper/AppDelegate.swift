//
//  AppDelegate.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/13.
//

import SwiftUI
import Cocoa
import AutoSQLiteSwift

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusMenuItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusMenuItem.button?.image = NSImage(named: "menuIcon")

        refreshStatusMenuItem()
        setupNotification()
        WallpaperManager.share.setup()

        showSettingWC()

        SQLiteManager.shared.printDebug = true
    }

    enum ItemType: Int {
        case showSetting
        case quit
        case switch2Next
    }

    // MARK: - StatusItem

    var statusMenuItem: NSStatusItem!
    var screenHash2videoName = [Int: String?]()

    func refreshStatusMenuItem() {
        let menu = NSMenu()
        menu.addItem(getMenuItem(title: "设置", type: .showSetting))
        menu.addItem(.separator())
        menu.addItem(getMenuItem(title: "全部切换下一张", type: .switch2Next))
        for screen in NSScreen.screens {
            let item = NSMenuItem(title: screen.localizedName, action: nil, keyEquivalent: "")
            item.tag = screen.hash
            menu.addItem(item)
        }
        menu.addItem(.separator())
        menu.addItem(getMenuItem(title: "退出", type: .quit))
        statusMenuItem.menu = menu
        refreshScreenSwitchMenu()
    }

    func refreshScreenSwitchMenu() {
        for screen in NSScreen.screens {
            guard let screenItem = statusMenuItem.menu?.item(withTitle: screen.localizedName) else { continue }
            let subMenu = NSMenu()
            let empty = "未设置壁纸"
            let videoItem = NSMenuItem(
                title: (screenHash2videoName[screen.hash] ?? empty) ?? empty,
                action: nil,
                keyEquivalent: ""
            )
            subMenu.addItem(videoItem)
            let switchItem = NSMenuItem(
                title: "切换下一张",
                action: #selector(statusSwitch2NextClick(_:)),
                keyEquivalent: ""
            )
            switchItem.tag = screen.hash
            subMenu.addItem(switchItem)
            statusMenuItem.menu?.setSubmenu(subMenu, for: screenItem)
        }
    }

    private func getMenuItem(title: String, type: ItemType, key: String? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(statusMenuItemClick(_:)), keyEquivalent: key ?? "")
        item.tag = type.rawValue
        return item
    }

    @objc private func statusExitItemClick(_ item: NSMenuItem) {
        NSApp.terminate(nil)
    }

    @objc private func statusMenuItemClick(_ item: NSMenuItem) {
        guard let type = ItemType(rawValue: item.tag) else { return }
        switch type {
        case .showSetting:
            showSettingWC()
        case .quit:
            NSApp.terminate(nil)
        case .switch2Next:
            WallpaperManager.share.switchAll2NextWallpaper()
        }
    }

    @objc private func statusSwitch2NextClick(_ item: NSMenuItem) {
        WallpaperManager.share.switch2NextWallpaper(screenHash: item.tag)
    }

    private func showSettingWC() {
//        let hostVc = NSHostingController(rootView: ContentView())
//        let window = NSWindow(contentViewController: hostVc, styleMask: [])
        let hostView = NSHostingView(rootView: ContentView())
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false,
            screen: NSScreen.screens[1]
        )
        window.contentView = hostView
        window.title = "设置"
        let controller = NSWindowController(window: window)
        controller.showWindow(nil)
    }

    private func setupNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlerScreenChange(_:)),
            name: ScreenDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlerVideoChange(_:)),
            name: VideoDidChangeNotification,
            object: nil
        )
    }

    @objc private func handlerScreenChange(_ notification: Notification) {
        refreshStatusMenuItem()
    }

    @objc private func handlerVideoChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        for (key, value) in userInfo {
            guard let screenHash = key as? Int,
                  let title = value as? String
            else { continue }
            screenHash2videoName[screenHash] = title
        }
        refreshScreenSwitchMenu()
    }
}
