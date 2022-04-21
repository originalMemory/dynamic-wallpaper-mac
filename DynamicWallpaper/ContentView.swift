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
                Button("所有视频") {
                    middleShowType = .allVideo
                    searchVideo()
                }
                Button("播放列表") {
                    middleShowType = .playlist
                    videoVms.removeAll()
                    if let playlistId = (playlistVms.safeValue(index: curPlaylistIndex) ?? playlistVms.first)?.key {
                        refreshPlaylistVideo(playlistId: playlistId)
                    }
                }
                Spacer()
            }
            .padding(.leading, Metric.horizontalMargin).frame(width: Metric.leftWidth)
            Divider()
            switch middleShowType {
            case .allVideo:
                allVideoView
            case .playlist:
                playlistView
            }
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
        static let playlistHeaderHeight: CGFloat = 60
    }

    @State private var middleShowType: MiddleShowType = .allVideo

    @State private var searchTitle: String = ""
    @State private var videoVms: [VideoPreviewView.ViewModel]
    @State private var screenInfos: [ScreenInfo]

    @State private var playlistVms: [DropdownOption]
    @State private var curPlaylistIndex: Int = -1

    @State private var curScreenIndex: Int = 0
    @State private var monitorScale: CGFloat = 0
    @State private var selectedVideos: [Video] = []

    init() {
        let videos: [Video] = DBManager.share.queryFromDb(fromTable: Table.video) ?? []
        _videoVms = State(initialValue: videos.map { video in
            VideoPreviewView.ViewModel.from(video: video)
        })
        _screenInfos = State(initialValue: NSScreen.screens.map {
            ScreenInfo.from(screen: $0)
        })

        let playlists: [Playlist] = DBManager.share.queryFromDb(fromTable: Table.playlist) ?? []
        _playlistVms = State(initialValue: playlists.map { playlist in
            DropdownOption(key: String(playlist.id), value: playlist.name)
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

    enum MiddleShowType {
        case allVideo
        case playlist
    }

    var videoPreviewView: some View {
        VideoPreviewGrid(vms: $videoVms) { ids in
            refreshDetailVideos(ids: ids)
        }
    }

    /// 视频预览 view
    var allVideoView: some View {
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
            .padding(.top, 10)
            Divider()
            videoPreviewView
        }
    }

    var playlistView: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                Divider()
                videoPreviewView
            }
            .padding(.top, Metric.playlistHeaderHeight)
            HStack {
                Text("当前播放列表")
                DropdownSelector(
                    placeholder: "未选择播放列表",
                    options: playlistVms,
                    selectIndex: curPlaylistIndex,
                    popAlignment: .topLeading,
                    buttonHeight: 30
                ) { option in
                    refreshPlaylistVideo(playlistId: option.key)
                }
                .frame(width: 200)
                Button("创建") {
                    TextInputWC { text in
                        createPlaylist(name: text)
                    }
                    .showWindow(nil)
                }
                Button("修改") {
                    TextInputWC(text: playlistVms[curPlaylistIndex].value) { text in
                        guard let id = Int64(playlistVms[curPlaylistIndex].key) else {
                            return
                        }
                        updatePlaylistName(id: id, name: text)
                    }
                    .showWindow(nil)
                }
                .disabled(curPlaylistIndex < 0)
                Button("删除") {
                    delPlaylist()
                }
                .disabled(curPlaylistIndex < 0)
                Spacer()
            }
            .frame(height: Metric.playlistHeaderHeight)
        }
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
                        guard let video = selectedVideos.first,
                              let path = VideoHelper.share.getFullPath(videoId: video.id, filename: video.file)
                        else {
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

            if !selectedVideos.isEmpty {
                Text("选中的壁纸")
                ScrollView {
                    if selectedVideos.count > 1 {
                        ForEach(0..<selectedVideos.count, id: \.self) { i in
                            Text(selectedVideos[i].title).padding(.bottom, 2).frame(maxWidth: .infinity)
                        }
                    } else {
                        let video = selectedVideos[0]
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
                        Text(video.desc ?? "").frame(maxWidth: .infinity, alignment: .leading)
                        Divider()
                        HStack {
                            Spacer()
                            Text("标签").bold()
                            Spacer()
                        }
                        Text(video.tags ?? "").frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(10)
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Color.white))
            }

            Spacer()
            Text("播放列表")
            VStack {
                if middleShowType == .allVideo {
                    DropdownSelector(
                        placeholder: "未选择播放列表",
                        options: playlistVms,
                        selectIndex: curPlaylistIndex,
                        popAlignment: .bottomLeading,
                        buttonHeight: 30
                    ) { option in
                        // TODO: 优化按钮状态
                        curPlaylistIndex = playlistVms.firstIndex(where: { $0 == option }) ?? -1
                    }
                }
                HStack {
                    Button("添加") {
                        addOrDelVideoToPlaylist(isAdd: true)
                    }
                    Button("删除") {
                        addOrDelVideoToPlaylist(isAdd: false)
                    }
                }
                .disabled(curPlaylistIndex < 0)
            }
            .frame(maxWidth: .infinity)
            .padding().overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Color.white))
        }
        .frame(width: 200)
        .onReceive(NotificationCenter.default.publisher(for: ScreenDidChangeNotification)) { output in
            monitorScale = getMonitorScale()
            screenInfos = NSScreen.screens.map {
                ScreenInfo.from(screen: $0)
            }
        }
    }

    private func refreshDetailVideos(ids: [Int64]) {
        selectedVideos = DBManager.share.queryFromDb(
            fromTable: Table.video,
            where: Video.Properties.id.in(ids)
        ) ?? []
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
        selectedVideos = []
        let videos: [Video] = DBManager.share.queryFromDb(
            fromTable: Table.video,
            where: Video.Properties.title.like("%\(searchTitle)%")
        ) ?? []
        videoVms = videos.map {
            VideoPreviewView.ViewModel.from(video: $0)
        }
    }

    // MARK: - 播放列表修改及展示

    private func createPlaylist(name: String) {
        let playlist = Playlist()
        playlist.name = name
        DBManager.share.insertToDb(objects: [playlist], intoTable: Table.playlist)
        guard let playlists: [Playlist] = DBManager.share.queryFromDb(fromTable: Table.playlist) else {
            return
        }
        playlistVms = playlists.map { playlist in
            DropdownOption(key: "\(playlist.id)", value: playlist.name)
        }
        selectedVideos.removeAll()
    }

    private func updatePlaylistName(id: Int64, name: String) {
        let playlist = Playlist()
        playlist.name = name
        DBManager.share.updateToDb(
            table: Table.playlist,
            on: [Playlist.Properties.name],
            with: playlist,
            where: Playlist.Properties.id.is(id)
        )
        let key = String(id)
        guard let index = playlistVms.firstIndex(where: { option in option.key == key }) else {
            return
        }
        playlistVms[index] = DropdownOption(key: key, value: name)
    }

    private func delPlaylist() {
        guard curPlaylistIndex >= 0, let id = Int64(playlistVms[curPlaylistIndex].key) else {
            return
        }
        DBManager.share.deleteFromDb(fromTable: Table.playlist, where: Playlist.Properties.id.is(id))
        playlistVms.remove(at: curPlaylistIndex)
        if curPlaylistIndex >= playlistVms.count {
            curPlaylistIndex -= 1
        }
        selectedVideos.removeAll()
    }

    private func refreshPlaylistVideo(playlistId: String) {
        curPlaylistIndex = playlistVms.firstIndex {
            $0.key == playlistId
        } ?? -1
        guard let id = Int64(playlistId),
              let playlists: [Playlist] = DBManager.share.queryFromDb(
                  fromTable: Table.playlist,
                  where: Playlist.Properties.id.is(id),
                  limit: 1
              ),
              let videoIds = playlists.first?.videoIds,
              let videos: [Video] = DBManager.share.queryFromDb(
                  fromTable: Table.video,
                  where: Video.Properties.id.in(videoIds.components(separatedBy: ","))
              )
        else {
            return
        }
        videoVms = videos.map { VideoPreviewView.ViewModel.from(video: $0) }
    }

    // MARK: - 播放列表包含的视频增删

    private func addOrDelVideoToPlaylist(isAdd: Bool) {
        guard let id = Int64(playlistVms.safeValue(index: curPlaylistIndex)?.key ?? ""),
              let playlists: [Playlist] = DBManager.share.queryFromDb(
                  fromTable: Table.playlist,
                  where: Playlist.Properties.id.is(id),
                  limit: 1
              ),
              let playlist = playlists.first
        else {
            return
        }
        var videoIds = Set(playlist.videoIds.components(separatedBy: ","))
        videoIds.remove("")
        let selectedVideoIds = selectedVideos.map { String($0.id) }
        for id in selectedVideoIds {
            if isAdd {
                videoIds.insert(id)
            } else {
                videoIds.remove(id)
            }
        }
        playlist.videoIds = Array(videoIds).joined(separator: ",")
        DBManager.share.updateToDb(
            table: Table.playlist,
            on: [Playlist.Properties.videoIds],
            with: playlist,
            where: Playlist.Properties.id.is(id)
        )
        refreshPlaylistVideo(playlistId: String(playlist.id))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
