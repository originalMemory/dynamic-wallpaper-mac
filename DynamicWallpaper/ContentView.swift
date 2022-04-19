//
//  ContentView.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/13.
//

import SwiftUI

struct ContentView: View {
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
            .padding(.leading, Metric.horizontalMargin).frame(width: Metric.leftWidth)
            Divider()
            videoView
            Divider()
            screenAndDetailView.padding(.trailing, Metric.horizontalMargin)
        }
        .frame(width: 1100, height: 850, alignment: .center)
    }

    // MARK: - 属性及初始化

    enum Metric {
        static let rightWidth: CGFloat = 200
        static let leftWidth: CGFloat = 150
        static let horizontalMargin: CGFloat = 8
    }

    @State private var searchTitle: String = ""

    @State private var vms: [VideoPreviewView.ViewModel]
    @State private var screenInfos: [ScreenInfo]
    @State private var monitorScale: CGFloat = 0
    @State private var curVideoIndex: Int = 0

    @State private var curScreenIndex: Int = 0
    private let screenChangePub = NotificationCenter.default.publisher(for: ScreenDidChangeNotification)

    init() {
        let videos: [Video] = DBManager.share.queryFromDb(fromTable: Table.video) ?? []
        _vms = State(initialValue: videos.map { video in
            VideoPreviewView.ViewModel.from(video: video)
        })
        _screenInfos = State(initialValue: NSScreen.screens.map {
            ScreenInfo.from(screen: $0)
        })
        _monitorScale = State(initialValue: getMonitorScale())
    }

    private func getMonitorScale() -> CGFloat {
        var totalWidth: CGFloat = 0
        for screen in NSScreen.screens {
            totalWidth = max(totalWidth, screen.frame.origin.x + screen.frame.size.width)
        }
        return Metric.rightWidth * 0.9 / totalWidth
    }

    // MARK: - View

    /// 视频预览 view
    var videoView: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Button("导入视频") {
                    selectImportVideoPaths()
                }
                TextField("输入搜索条件", text: $searchTitle).frame(width: 100).onSubmit {
                    searchVideo()
                }
                Button("搜索") {
                    searchVideo()
                }
            }
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)) {
                    ForEach(0..<vms.count, id: \.self) { i in
                        VideoPreviewView(vm: $vms[i]).frame(height: 200).onTapGesture {
                            vms[i].isSelected = true
                            if curVideoIndex >= 0 {
                                vms[curVideoIndex].isSelected = false
                            }
                            curVideoIndex = i
                        }
                    }
                }
            }
        }
        .padding(.vertical, 10).frame(maxWidth: .infinity)
    }

    /// 屏幕信息和详情 view
    var screenAndDetailView: some View {
        VStack {
            Divider()
            Text("屏幕信息")
            ZStack(alignment: .leading) {
                Color.gray
                ZStack(alignment: .bottomLeading) {
                    ForEach(0..<screenInfos.count, id: \.self) { i in
                        let info: ScreenInfo = screenInfos[i]
                        ZStack(alignment: .topLeading) {
                            Color.green
                            Text(info.name).font(.system(size: 12)).padding(5)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .stroke(curScreenIndex == i ? Color.blue : Color.white)
                        )
                        .padding(.all, 2)
                        .frame(
                            width: info.size.width * monitorScale,
                            height: info.size.height * monitorScale
                        )
                        .offset(x: info.origin.x * monitorScale, y: -info.origin.y * monitorScale)
                        .onTapGesture {
                            curScreenIndex = i
                        }
                    }
                }
                .offset(x: 10, y: 0)
            }
            .frame(height: Metric.rightWidth * 0.9)

            if curScreenIndex >= 0 {
                Text("选中的显示器").padding(.top, 10)
                VStack(alignment: .center, spacing: 10) {
                    let info = screenInfos[curScreenIndex]
                    Text(info.name)
                    Text("\(Int(info.size.width))*\(Int(info.size.height))")
                    Button("设置为该显示器的壁纸") {
                        guard let path = vms[curVideoIndex].filePath else {
                            return
                        }
                        WallpaperManager.share.setWallpaper(
                            screenHash: info.screenHash,
                            videoUrl: URL(fileURLWithPath: path)
                        )
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Color.white))
            }

            if curVideoIndex >= 0 {
                Text("选中的壁纸")
                let video = vms[curVideoIndex]
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Spacer()
                        Text(video.title)
                        Spacer()
                    }
                    Divider()
                    HStack {
                        Spacer()
                        Text("描述").bold()
                        Spacer()
                    }
                    Text(video.desc ?? "")
                    Divider()
                    HStack {
                        Spacer()
                        Text("标签").bold()
                        Spacer()
                    }
                    Text(video.tags ?? "")
                }
                .padding(10)
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Color.white))
            }
        }
        .frame(width: 200)
        .onReceive(screenChangePub) { output in
            monitorScale = getMonitorScale()
            screenInfos = NSScreen.screens.map {
                ScreenInfo.from(screen: $0)
            }
        }
    }

    // MARK: - 点击事件

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

    private func searchVideo() {
        curVideoIndex = -1
        let videos: [Video] = DBManager.share.queryFromDb(
            fromTable: Table.video,
            where: Video.Properties.title.like("%\(searchTitle)%")
        ) ?? []
        vms = videos.map {
            VideoPreviewView.ViewModel.from(video: $0)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
