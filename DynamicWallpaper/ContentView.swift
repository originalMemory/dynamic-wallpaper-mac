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
                Divider()
                Text("屏幕信息")
                ZStack(alignment: .leading) {
                    Color.gray
                    ZStack(alignment: .bottomLeading) {
                        ForEach(0..<monitors.count, id: \.self) { i in
                            let monitor = monitors[i]
                            ZStack(alignment: .topLeading) {
                                Color.green
                                Text(monitor.screen.localizedName).font(.system(size: 12)).padding(5)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .stroke(curMonitorIndex == i ? Color.blue : Color.white)
                            )
                            .padding(.all, 2)
                            .frame(
                                width: monitor.size.width * monitorScale,
                                height: monitor.size.height * monitorScale
                            )
                            .offset(x: monitor.origin.x * monitorScale, y: -monitor.origin.y * monitorScale)
                            .onTapGesture {
                                curMonitorIndex = i
                            }
                        }
                    }.offset(x: 10, y: 0)
                }
                .frame(height: 180)

                if curMonitorIndex >= 0 {
                    Text("选中的显示器").padding(.top, 10)
                    VStack(alignment: .center, spacing: 10) {
                        let monitor = monitors[curMonitorIndex]
                        Text(monitor.screen.localizedName)
                        Text("\(Int(monitor.size.width))*\(Int(monitor.size.height))")
                        Button(monitorIsPlaying ? "取消播放" : "开始播放") {
                            monitorIsPlaying = !monitorIsPlaying
                        }
                    }.padding(10)
                        .frame(maxWidth: .infinity)
                        .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Color.white))
                }

                if curVideoIndex >= 0 {
                    Text("选中的壁纸")
                    let video = videos[curVideoIndex]
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Spacer()
                            Text(video.title)
                            Spacer()
                        }
                        Divider()
                        Text("描述：\n\(video.desc ?? "")")
                        Divider()
                        Text("标签：\n\(video.tags ?? "")")
                        Divider()
                    }.padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Color.white))
                }
            }
            .frame(width: 200)
            Divider()
        }
        .frame(width: 1100, height: 850, alignment: .center)
    }

    private var videos: [Video] = []
    @State private var vms: [VideoPreviewView.ViewModel]
    @State private var monitors: [Monitor]
    private var monitorScale: CGFloat = 0
    @State private var curVideoIndex: Int = 0

    @State private var curMonitorIndex: Int = 0
    @State private var monitorIsPlaying: Bool = false

    init() {
        let videos: [Video] = DBManager.share.queryFromDb(fromTable: Table.video) ?? []
        self.videos = videos
        vms = videos.map { video in
            VideoPreviewView.ViewModel.from(video: video)
        }
        monitors = NSScreen.screens.map {
            Monitor(screen: $0)
        }
        var totalWidth: CGFloat = 0
        for screen in NSScreen.screens {
            totalWidth = max(totalWidth, screen.frame.origin.x + screen.frame.size.width)
            print(screen.frame)
        }
        monitorScale = 180 / totalWidth
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
                            if curVideoIndex >= 0 {
                                vms[curVideoIndex] = vms[curVideoIndex].copy(isSelected: false)
                            }
                            curVideoIndex = i
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
