//
//  PlayConfigView.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/22.
//

import SwiftUI

struct PlayConfigView: View {
    @State private var selectLoopType: Int = 0
    @State private var period: String = ""
    private let screenHash: Int
    @State private var volume: CGFloat = 0
    private let leftWidth: CGFloat = 60

    init(screenHash: Int) {
        self.screenHash = screenHash
        if let config = WallpaperManager.share.getConfig(screenHash: screenHash) {
            _selectLoopType = State(initialValue: PlayLoopType.allCases.firstIndex(of: config.loopType) ?? 0)
            _period = State(initialValue: String(config.periodInMin))
            _volume = State(initialValue: CGFloat(config.volume * 100))
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("循环类型").frame(width: leftWidth)
                Picker(selection: $selectLoopType, label: Text("")) {
                    ForEach(0..<PlayLoopType.allCases.count, id: \.self) { i in
                        Text(PlayLoopType.allCases[i].rawValue)
                    }
                }.labelsHidden()
                    .frame(width: 200)
            }
            HStack {
                Text("切换周期").frame(width: leftWidth)
                TextField("输入周期长度", text: $period).frame(width: 100)
                Text("分钟")
            }
            .padding(.vertical, 7)
            HStack {
                Text("音量").frame(width: leftWidth, alignment: .trailing)
                Slider(value: $volume, in: 0...100, step: 1)
                Text(String(format: "%02d%%", Int(volume)))
            }
            HStack {
                Spacer()
                Button("保存") {
                    let periodInMin = Int(period) ?? 1
                    let type = PlayLoopType.allCases[selectLoopType]
                    let config: ScreenPlayConfig
                    let saveVolume = volume / 100
                    if let existConfig = WallpaperManager.share.getConfig(screenHash: screenHash) {
                        existConfig.periodInMin = periodInMin
                        existConfig.loopType = type
                        existConfig.volume = saveVolume
                        config = existConfig
                    } else {
                        config = ScreenPlayConfig()
                        config.screenHash = screenHash
                        config.periodInMin = periodInMin
                        config.loopType = type
                        config.volume = saveVolume
                    }
                    WallpaperManager.share.addOrUpdateConfig(config: config)
                    NSApplication.shared.keyWindow?.close()
                }
                Button("取消") {
                    NSApplication.shared.keyWindow?.close()
                }
                Spacer()
            }
        }
        .padding().frame(width: 300)
    }
}

struct PlayConfigView_Previews: PreviewProvider {
    static var previews: some View {
        PlayConfigView(screenHash: 0)
    }
}
