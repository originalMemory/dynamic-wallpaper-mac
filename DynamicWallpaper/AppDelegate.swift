//
//  AppDelegate.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/13.
//

import SwiftUI
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DBManager.share.setupTables()
        WallpaperManager.share.setup()
        createStatusMenuItem()
    }

    enum ItemType: Int {
        case showSetting
        case quit
    }

    // MARK: - StatusItem

    var statusMenuItem: NSStatusItem!

    func createStatusMenuItem() {
        statusMenuItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusMenuItem.button?.title = "动态壁纸"

        let menu = NSMenu()
        menu.addItem(getMenuItem(title: "设置", type: .showSetting))
        menu.addItem(.separator())
        menu.addItem(getMenuItem(title: "退出", type: .quit))
        statusMenuItem.menu = menu
    }

    private func getMenuItem(title: String, type: ItemType, key: String? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(statusMenuItemClick(_:)), keyEquivalent: key ?? "")
        item.tag = type.rawValue
        return item
    }

    @objc func statusExitItemClick(_ item: NSMenuItem) {
        NSApp.terminate(nil)
    }

    @objc func statusMenuItemClick(_ item: NSMenuItem) {
        guard let type = ItemType(rawValue: item.tag) else { return }
        switch type {
        case .showSetting:
            let hostVc = NSHostingController(rootView: ContentView())
            let window = NSWindow(contentViewController: hostVc)
            window.title = "设置"
            let controller = NSWindowController(window: window)
            controller.showWindow(nil)
        case .quit:
            NSApp.terminate(nil)
        }
    }
}
