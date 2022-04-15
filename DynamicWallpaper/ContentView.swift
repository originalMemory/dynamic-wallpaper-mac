//
//  ContentView.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/13.
//

import SwiftUI

struct ContentView: View {
    @State private var searchTitle: String = ""
    var body: some View {
        HStack(alignment: .top) {
            // 左侧功能栏
            Divider()
            VStack(alignment: .leading) {
                Spacer()
                Button("所有视频") {}
                Button("播放列表") {}
                Spacer()
            }
            .padding(.horizontal, 5).frame(width: 150)
            Divider().background(Color.white)
            // 图片列表
            videoView
            Divider()
            // 显示器及设置属性
            VStack {
                Text("显示器")
            }
            .frame(width: 150)
            Divider()
        }
        .frame(width: 1100, height: 800, alignment: .center)
    }

//    private var videos: [Video] = []
    @State private var vms: [VideoPreviewView.ViewModel]
    @State private var lastSelectedIndex: Int = -1

    init() {
        let videos: [Video] = DBManager.share.queryFromDb(fromTable: Table.video) ?? []
        self.vms = videos.map { video in
            VideoPreviewView.ViewModel.from(video: video)
        }
    }

    var videoView: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Button("导入视频") {
                    selectImportVideoPaths()
                }
                TextField("输入搜索条件", text: $searchTitle).frame(width: 100)
                Button("搜索") {
                    // TODO: 搜索
                }
            }
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)) {
                    ForEach(0..<vms.count, id: \.self) { i in
                        VideoPreviewView(vm: $vms[i]).frame(height: 200).onTapGesture {
                            vms[i] = vms[i].copy(isSelected: true)
                            if lastSelectedIndex >= 0 {
                                vms[lastSelectedIndex] = vms[lastSelectedIndex].copy(isSelected: false)
                            }
                            lastSelectedIndex = i
                        }
                    }
                }
            }
        }
        .padding(.vertical, 10).frame(maxWidth: .infinity)
    }

    private func selectImportVideoPaths() {
        let dialog = NSOpenPanel()
        dialog.title = "选择视频文件或目录"
        dialog.showsResizeIndicator = true
        dialog.allowsMultipleSelection = true
        dialog.canChooseDirectories = true
        dialog.allowedContentTypes = [.mpeg4Movie, .directory]

        if dialog.runModal() != NSApplication.ModalResponse.OK {
            return
        }

        var filePaths: [String] = []
        for url in dialog.urls {
            var directoryExists = ObjCBool(false)
            FileManager.default.fileExists(atPath: url.path, isDirectory: &directoryExists)
            if !directoryExists.boolValue {
                if isVideo(url: url) {
                    filePaths.append(url.path)
                }
                continue
            }
            let enumeratorAtPath = FileManager.default.enumerator(atPath: url.path)
            for obj in enumeratorAtPath?.allObjects ?? [] {
                guard let path = obj as? String else {
                    continue
                }
                if isVideo(url: URL(fileURLWithPath: path)) {
                    filePaths.append(url.path.appendPathComponent(path))
                }
            }
            VideoHelper.share.importVideo(filePaths: filePaths)
        }
    }

    private func isVideo(url: URL) -> Bool {
        let videoExtensions = ["mkv", "mp4", "flv", "avi"]
        return videoExtensions.contains(url.pathExtension.lowercased())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
