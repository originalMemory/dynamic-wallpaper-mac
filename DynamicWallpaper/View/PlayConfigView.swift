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

    init() {
        if let config = WallpaperManager.share.config {
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
            }.frame(width: 200)
            HStack {
                Text("切换周期")
                TextField("输入周期长度", text: $period).frame(width: 100)
                Text("分钟")
            }.padding(.vertical, 7)
            HStack {
                Spacer()
                Button("保存") {
                    let config = PlayConfig(
                        periodInMin: Int(period) ?? 5,
                        loopType: PlayLoopType.allCases[selectLoopType]
                    )
                    WallpaperManager.share.updateConfig(config: config)
                    NSApplication.shared.keyWindow?.close()
                }
                Button("取消") {
                    NSApplication.shared.keyWindow?.close()
                }
                Spacer()
            }
        }.padding().frame(width: 300)
    }
}

struct PlayConfigView_Previews: PreviewProvider {
    static var previews: some View {
        PlayConfigView()
    }
}
