//
//  ContentView.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/13.
//

import SwiftUI

enum MiddleShowType: CaseIterable {
    case allVideo
    case playlist
}

extension MiddleShowType {
    func text() -> String {
        switch self {
        case .allVideo:
            return "所有视频"
        case .playlist:
            return "播放列表"
        }
    }
}

struct ContentView: View {
    // MARK: - 属性及初始化

    enum Metric {
        static let rightWidth: CGFloat = 250
        static let horizontalMargin: CGFloat = 8
    }

    @State private var showModeIndex = 1

    @State private var searchTitle: String = ""
    @State private var videoVms: [VideoPreviewView.ViewModel]
    @State private var screenInfos: [ScreenInfo]

    @State private var playlists: [Playlist]
    @State private var curPlaylistIndex: Int = -1

    @State private var curScreenIndex: Int = 0
    @State private var monitorScale: CGFloat = 0
    @State private var selectedVideos: [Video] = []

    init() {
        let videos: [Video] = DBManager.share.queryFromDb(fromTable: Table.video) ?? []
        videoVms = videos.map { video in
            VideoPreviewView.ViewModel.from(video: video)
        }
        screenInfos = NSScreen.screens.map { screen in
            var info = ScreenInfo.from(screen: screen)
            info.playlistName = WallpaperManager.share.getScreenPlaylistName(screenHash: screen.hash)
            info.videoName = WallpaperManager.share.getScreenPlayingVideoName(screenHash: screen.hash)
            return info
        }

        playlists = DBManager.share.queryFromDb(fromTable: Table.playlist) ?? []

        _monitorScale = State(initialValue: getMonitorScale())
    }

    private func getMonitorScale() -> CGFloat {
        var totalWidth: CGFloat = 0
        for screen in NSScreen.screens {
            totalWidth = max(totalWidth, screen.frame.origin.x + screen.frame.size.width)
        }
        return Metric.rightWidth * 0.7 / totalWidth
    }

    private func curShowMode() -> MiddleShowType {
        MiddleShowType.allCases[showModeIndex]
    }

    // MARK: - View

    var body: some View {
        HStack(alignment: .top) {
            VStack {
                Picker("", selection: $showModeIndex) {
                    ForEach(0..<MiddleShowType.allCases.count, id: \.self) { i in
                        Text(MiddleShowType.allCases[i].text())
                    }
                }
                .labelsHidden()
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: showModeIndex) { index in
                    switch MiddleShowType.allCases[index] {
                    case .allVideo:
                        searchVideo()
                    case .playlist:
                        videoVms.removeAll()
                        refreshPlaylistVideo()
                    }
                }
                .padding(.top, 10).frame(width: 250)
                Divider().padding(.horizontal, Metric.horizontalMargin)
                HStack {
                    switch MiddleShowType.allCases[showModeIndex] {
                    case .allVideo:
                        Button("导入视频") {
                            selectImportVideoPaths()
                        }
                        TextField("输入搜索条件", text: $searchTitle).frame(width: 100).onSubmit {
                            searchVideo()
                        }
                        Button("搜索") {
                            searchVideo()
                        }
                        Spacer()
                    case .playlist:
                        playlistPicker.frame(width: 150)
                        Button("创建") {
                            TextInputWC { text in
                                createPlaylist(name: text)
                            }
                            .showWindow(nil)
                        }
                        Button("修改") {
                            TextInputWC(text: playlists[curPlaylistIndex].name) { text in
                                updatePlaylistName(id: playlists[curPlaylistIndex].id, name: text)
                            }
                            .showWindow(nil)
                        }
                        .disabled(curPlaylistIndex < 0)
                        Button("删除") {
                            delPlaylist()
                        }
                        .disabled(curPlaylistIndex < 0)
                        Spacer()
                        Button("播放设置") {
                            PlayConfigView().showInNewWindow(title: "播放设置")
                        }
                        Spacer()
                    }
                }
                .padding(.leading, Metric.horizontalMargin)
                Divider().padding(.horizontal, Metric.horizontalMargin)
                VideoPreviewGrid(vms: $videoVms) { id, enableMulti in
                    onVideoPreviewClick(id: id, enableMulti: enableMulti)
                }
            }
            Divider()
            screenAndDetailView.padding(.trailing, Metric.horizontalMargin)
        }
        .frame(width: 1100, height: 850, alignment: .center)
    }

    var playlistPicker: some View {
        Picker("", selection: $curPlaylistIndex) {
            ForEach(0..<playlists.count, id: \.self) { i in
                Text(playlists[i].name)
            }
        }
        .labelsHidden().onChange(of: curPlaylistIndex) { index in
            if curShowMode() == .playlist {
                refreshPlaylistVideo()
            }
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
            .frame(height: Metric.rightWidth * 0.7)

            let selectedVideos = videoVms.filter { model in model.isSelected }
            if curScreenIndex >= 0 {
                Text("选中的显示器").padding(.top, 10)
                VStack(alignment: .center, spacing: 10) {
                    let info = screenInfos[curScreenIndex]
                    Text(info.name)
                    Text("\(Int(info.size.width))*\(Int(info.size.height))")
                    if curShowMode() == .allVideo {
                        Button("设置选中的壁纸") {
                            guard let video = selectedVideos.first,
                                  let path = VideoHelper.share.getFullPath(videoId: video.id, filename: video.file)
                            else {
                                return
                            }
                            WallpaperManager.share.setWallpaper(
                                screenHash: info.screenHash,
                                videoName: video.title,
                                videoUrl: URL(fileURLWithPath: path)
                            )
                        }
                    }
                    if curShowMode() == .playlist {
                        Button("设置当前播放列表") {
                            if let playlistId = playlists.safeValue(index: curPlaylistIndex)?.id {
                                WallpaperManager.share.setPlaylistToMonitor(
                                    playlistId: playlistId,
                                    screenHash: info.screenHash
                                )
                            }
                        }
                    }
                    Text("当前壁纸：\n\(info.videoName ?? "")").frame(maxWidth: .infinity, alignment: .leading)
                    Text("当前播放列表: \n\(info.playlistName ?? "")").frame(maxWidth: .infinity, alignment: .leading)
                }
                .onReceive(NotificationCenter.default.publisher(for: VideoDidChangeNotification)) { output in
                    guard let userInfo = output.userInfo else { return }
                    for (key, value) in userInfo {
                        guard let screenHash = key as? Int,
                              let title = value as? String,
                              let index = screenInfos.firstIndex(where: { info in info.screenHash == screenHash })
                        else { continue }
                        screenInfos[index].videoName = title
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
            if curShowMode() == .allVideo {
                Text("播放列表")
                VStack {
                    playlistPicker
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
        }
        .frame(width: 200)
        .onReceive(NotificationCenter.default.publisher(for: ScreenDidChangeNotification)) { output in
            monitorScale = getMonitorScale()
            screenInfos = NSScreen.screens.map {
                ScreenInfo.from(screen: $0)
            }
        }
    }

    private func onVideoPreviewClick(id: Int64, enableMulti: Bool) {
        if !enableMulti {
            resetVideoSelectStatus()
        }
        guard let index = videoVms.firstIndex(where: { $0.id == id }) else { return }
        let video = videoVms[index]
        videoVms[index] = video.copy(isSelect: !video.isSelected)
    }

    private func resetVideoSelectStatus() {
        for i in 0..<videoVms.count {
            videoVms[i] = videoVms[i].copy(isSelect: false)
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
        playlists = DBManager.share.queryFromDb(fromTable: Table.playlist) ?? []
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
        playlists = DBManager.share.queryFromDb(fromTable: Table.playlist) ?? []
    }

    private func delPlaylist() {
        DBManager.share.deleteFromDb(
            fromTable: Table.playlist,
            where: Playlist.Properties.id.is(playlists[curPlaylistIndex].id)
        )
        playlists.remove(at: curPlaylistIndex)
        if curPlaylistIndex >= playlists.count {
            curPlaylistIndex -= 1
        }
    }

    private func refreshPlaylistVideo() {
        guard let videoIds = playlists.safeValue(index: curPlaylistIndex)?.videoIdList(),
              let videos: [Video] = DBManager.share.queryFromDb(
                  fromTable: Table.video,
                  where: Video.Properties.id.in(videoIds)
              )
        else {
            return
        }
        videoVms = videos.map { VideoPreviewView.ViewModel.from(video: $0) }
    }

    // MARK: - 播放列表包含的视频增删

    private func addOrDelVideoToPlaylist(isAdd: Bool) {
        let playlist = playlists[curPlaylistIndex]
        let videoIds = Set(playlist.videoIdList() + videoVms.filter { $0.isSelected }.map { $0.id }).map { String($0) }
        playlist.videoIds = videoIds.joined(separator: ",")
        DBManager.share.updateToDb(
            table: Table.playlist,
            on: [Playlist.Properties.videoIds],
            with: playlist,
            where: Playlist.Properties.id.is(playlist.id)
        )
        if curShowMode() == .playlist {
            refreshPlaylistVideo()
        } else {
            resetVideoSelectStatus()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
