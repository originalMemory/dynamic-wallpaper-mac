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

    init(screenHash: Int) {
        self.screenHash = screenHash
        if let config = WallpaperManager.share.getConfig(screenHash: screenHash) {
            _selectLoopType = State(initialValue: PlayLoopType.allCases.firstIndex(of: config.loopType) ?? 0)
            _period = State(initialValue: String(config.periodInMin))
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Picker(selection: $selectLoopType, label: Text("循环类型")) {
                ForEach(0..<PlayLoopType.allCases.count, id: \.self) { i in
                    Text(PlayLoopType.allCases[i].rawValue)
                }
            }
            .frame(width: 200)
            HStack {
                Text("切换周期")
                TextField("输入周期长度", text: $period).frame(width: 100)
                Text("分钟")
            }
            .padding(.vertical, 7)
            HStack {
                Spacer()
                Button("保存") {
                    let periodInMin = Int(period) ?? 1
                    let type = PlayLoopType.allCases[selectLoopType]
                    let config: ScreenPlayConfig
                    if let existConfig = WallpaperManager.share.getConfig(screenHash: screenHash) {
                        existConfig.periodInMin = periodInMin
                        existConfig.loopType = type
                        config = existConfig
                    } else {
                        config = ScreenPlayConfig(
                            screenHash: screenHash,
                            periodInMin: periodInMin,
                            loopType: type
                        )
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
