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

    enum VideoDetailHoverStatus {
        case none
        case title
        case desc
        case tags
    }

    @State private var showModeIndex = 0

    @State private var searchTitle: String = ""
    @State private var videoVms: [VideoPreviewView.ViewModel]
    @State private var screenInfos: [ScreenInfo]

    @State private var playlists: [Playlist]
    @State private var curPlaylistIndex: Int

    @State private var curScreenIndex: Int = 0
    @State private var monitorScale: CGFloat = 0
    @State private var videoDetailHoverType: VideoDetailHoverStatus = .none

    init() {
        videoVms = DBManager.share.search(type: .video).map {
            var vm = VideoPreviewView.ViewModel.from(video: $0.toVideo())
            if vm.id == 1 {
                vm.isSelected = true
            }
            return vm
        }
        screenInfos = NSScreen.screens.map { screen in
            var info = ScreenInfo.from(screen: screen)
            info.playlistName = WallpaperManager.share.getScreenPlaylistName(screenHash: screen.hash)
            info.videoName = WallpaperManager.share.getScreenPlayingVideoName(screenHash: screen.hash)
            return info
        }

        let playlists = DBManager.share.search(type: .playlist).map { $0.toPlaylist() }
        self.playlists = playlists
        curPlaylistIndex = playlists.count > 0 ? 0 : -1

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
                toolsView
                Divider().padding(.horizontal, Metric.horizontalMargin)
                VideoPreviewGrid(vms: $videoVms) { id, enableMulti, enablePreview in
                    onVideoPreviewClick(id: id, enableMulti: enableMulti, enablePreview: enablePreview)
                } selectAll: {
                    let allSelected = videoVms.allSatisfy { model in model.isSelected }
                    resetVideoSelectStatus(value: !allSelected)
                }
                .onReceive(NotificationCenter.default.publisher(for: VideoImportIndexNotification)) { output in
                    if curShowMode() == .allVideo {
                        DispatchQueue.main.async {
                            searchVideo()
                        }
                    }
                }
            }
            Divider()
            screenAndDetailView.padding(.trailing, Metric.horizontalMargin)
        }
        .frame(width: 1100, height: 850, alignment: .center)
    }

    /// 视频和播放列表操作功能区
    var toolsView: some View {
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
                    TextInputWC(text: playlists[curPlaylistIndex].title) { text in
                        updatePlaylistName(id: playlists[curPlaylistIndex].playlistId, name: text)
                    }
                    .showWindow(nil)
                }
                .disabled(curPlaylistIndex < 0)
                Button("删除") {
                    delPlaylist()
                }
                .disabled(curPlaylistIndex < 0)
            }
        }
        .padding(.leading, Metric.horizontalMargin)
        .frame(height: 40)
    }

    var playlistPicker: some View {
        Picker("", selection: $curPlaylistIndex) {
            ForEach(0..<playlists.count, id: \.self) { i in
                Text(playlists[i].title)
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
            screenOverview
            if curScreenIndex >= 0 {
                Text("选中的显示器").padding(.top, 10)
                screenDetailView
            }
            videoDetailView
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
            if curScreenIndex >= NSScreen.screens.count {
                curScreenIndex = NSScreen.screens.count - 1
            }
            screenInfos = NSScreen.screens.map {
                ScreenInfo.from(screen: $0)
            }
        }
    }

    /// 屏幕布局
    var screenOverview: some View {
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
    }

    /// 屏幕具体状态
    var screenDetailView: some View {
        VStack(alignment: .center, spacing: 10) {
            var info = screenInfos[curScreenIndex]
            Text(info.name)
            Text("\(Int(info.size.width))*\(Int(info.size.height))")
            Button("播放设置") {
                if let screenHash = screenInfos.safeValue(index: curScreenIndex)?.screenHash {
                    PlayConfigView(screenHash: screenHash).showInNewWindow(title: "播放设置")
                }
            }
            if curShowMode() == .allVideo {
                Button("设置选中的壁纸") {
                    guard let video = videoVms.first(where: { $0.isSelected }) else {
                        return
                    }
                    setWallpaper(path: video.file, title: video.title, cleanPlaylist: true)
                }
            }
            if curShowMode() == .playlist {
                Button("设置当前播放列表") {
                    if let playlist = playlists.safeValue(index: curPlaylistIndex) {
                        info.playlistName = playlist.title
                        screenInfos[curScreenIndex] = info
                        WallpaperManager.share.setPlaylistToMonitor(
                            playlistId: playlist.playlistId,
                            screenHash: info.screenHash
                        )
                    }
                }
            }
            Text("当前壁纸：\n\(info.videoName ?? "")").frame(maxWidth: .infinity, alignment: .leading)
            Text("当前播放列表: \n\(info.playlistName ?? "")").frame(maxWidth: .infinity, alignment: .leading)
            if info.playlistName != nil {
                Button("切换下一个") {
                    WallpaperManager.share.switch2NextWallpaper(screenHash: info.screenHash)
                }
            }
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

    /// 视频具体状态
    var videoDetailView: some View {
        VStack {
            let selectedVideos = videoVms.filter { model in model.isSelected }
            if !selectedVideos.isEmpty {
                Text("选中的壁纸")
                VStack {
                    ScrollView {
                        if selectedVideos.count > 1 {
                            ForEach(0..<selectedVideos.count, id: \.self) { i in
                                Text(selectedVideos[i].title).padding(.bottom, 2).frame(maxWidth: .infinity)
                            }
                        } else {
                            let video = selectedVideos[0]
                            getVideoDetailEditableText(vm: video, alignment: .center, showHoverStatus: .title)
                            Divider()
                            Text("描述").bold().frame(maxWidth: .infinity)
                            getVideoDetailEditableText(vm: video, alignment: .leading, showHoverStatus: .desc)
                            Divider()
                            Text("标签").bold().frame(maxWidth: .infinity)
                            getVideoDetailEditableText(vm: video, alignment: .leading, showHoverStatus: .tags)
                        }
                    }
                    HStack {
                        Button("删除") { delSelectedVideo() }
                        if curShowMode() == .playlist {
                            Button("从列表中移除") { addOrDelVideoToPlaylist(isAdd: false) }
                        }
                    }
                }
                .padding(5)
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Color.white))
            }
        }
    }

    private func getVideoDetailEditableText(
        vm: VideoPreviewView.ViewModel,
        alignment: Alignment,
        showHoverStatus: VideoDetailHoverStatus
    ) -> some View {
        let text: String?
        switch showHoverStatus {
        case .desc:
            text = vm.desc
        case .title:
            text = vm.title
        case .tags:
            text = vm.tags
        case .none:
            text = ""
        }
        let showEditHint = videoDetailHoverType == showHoverStatus
        return Button {
            TextInputView(text: text, multiLine: true) { text in
                guard var video = DBManager.share.getVideo(id: vm.id) else { return }
                switch showHoverStatus {
                case .desc:
                    video.desc = text
                case .title:
                    video.title = text
                case .tags:
                    video.tags = text
                case .none:
                    break
                }
                DBManager.share.updateVideo(id: vm.id, item: video)
                guard let index = videoVms.firstIndex(where: { $0.id == vm.id }) else { return }
                var newVm = VideoPreviewView.ViewModel.from(video: video)
                newVm.isSelected = true
                videoVms[index] = newVm
            }.show()
        } label: {
            // TODO: 点击区域优化，现在没有文字的区域点击无响应
            ZStack(alignment: .bottomTrailing) {
                Text(text ?? "").frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                if showEditHint {
                    Image(systemName: "square.and.pencil").padding(3)
                }
            }
            .padding(5)
            .frame(minHeight: 35)
            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(
                showEditHint ? .green : .clear,
                style: StrokeStyle(lineWidth: 1, dash: [5])
            ))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hover in
            videoDetailHoverType = hover ? showHoverStatus : .none
        }
    }

    // MARK: - 视频管理

    private func onVideoPreviewClick(id: Int64, enableMulti: Bool, enablePreview: Bool) {
        if !enableMulti {
            resetVideoSelectStatus(value: false)
        }
        guard let index = videoVms.firstIndex(where: { $0.id == id }) else { return }
        var video = videoVms[index]
        videoVms[index] = video.setSelected(value: !video.isSelected)
        if enablePreview {
            setWallpaper(path: video.file, title: video.title, cleanPlaylist: false)
        }
    }

    private func setWallpaper(path: String?, title: String, cleanPlaylist: Bool) {
        guard let path = path else { return }
        WallpaperManager.share.setWallpaper(
            screenHash: screenInfos[curScreenIndex].screenHash,
            videoName: title,
            videoUrl: URL(fileURLWithPath: path),
            cleanPlaylist: cleanPlaylist
        )
        if !cleanPlaylist {
            return
        }
        var info = screenInfos[curScreenIndex]
        info.playlistName = nil
        screenInfos[curScreenIndex] = info
    }

    private func resetVideoSelectStatus(value: Bool) {
        for i in 0..<videoVms.count {
            videoVms[i] = videoVms[i].setSelected(value: value)
        }
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
            ImportProgressView(paths: filePaths).showInNewWindow(title: "导入本地视频中")
        }
    }

    private func isVideo(url: URL) -> Bool {
        let videoExtensions = ["mkv", "mp4", "flv", "avi"]
        return videoExtensions.contains(url.pathExtension.lowercased())
    }

    private func searchVideo() {
        let videos: [Video]
        if searchTitle.isEmpty {
            videos = DBManager.share.search(type: .video).map { $0.toVideo() }
        } else {
            videos = DBManager.share.search(type: .video, filter: Column.title.like("%\(searchTitle)%"))
                .map { $0.toVideo() }
        }
        videoVms = videos.map {
            VideoPreviewView.ViewModel.from(video: $0)
        }
    }

    private func delSelectedVideo() {
        let videoIds = videoVms.filter { $0.isSelected }.map { $0.id }
        for videoId in videoIds {
            // TODO: 使用 regex 替换
            let playlists = DBManager.share.search(
                type: .playlist,
                filter: Column.videoIds.like("%\(videoId)%")
            ).map { $0.toPlaylist() }
            for var playlist in playlists {
                var videoIds = playlist.videoIdList()
                videoIds.removeAll { $0 == videoId }
                playlist.videoIds = videoIds.map { String($0) }.joined(separator: ",")
                DBManager.share.updatePlaylist(id: playlist.playlistId, item: playlist)
            }
            DBManager.share.delete(type: .video, id: videoId)
        }
        videoVms.removeAll { vm in videoIds.contains(vm.id) }
    }

    // MARK: - 播放列表管理

    private func createPlaylist(name: String) {
        let playlist = Playlist(playlistId: 0, title: name, videoIds: "")
        _ = DBManager.share.insertPlaylist(item: playlist)
        playlists = DBManager.share.search(type: .playlist).map { $0.toPlaylist() }
    }

    private func updatePlaylistName(id: Int64, name: String) {
        guard var playlist = DBManager.share.getPlaylist(id: id) else { return }
        playlist.title = name
        DBManager.share.updatePlaylist(id: id, item: playlist)
        playlists = DBManager.share.search(type: .playlist).map { $0.toPlaylist() }
    }

    private func delPlaylist() {
        guard let playlistId = playlists.safeValue(index: curPlaylistIndex)?.playlistId else { return }
        DBManager.share.delete(type: .playlist, id: playlistId)
        playlists.remove(at: curPlaylistIndex)
        if curPlaylistIndex >= playlists.count {
            curPlaylistIndex -= 1
        }
    }

    private func refreshPlaylistVideo() {
        guard let videoIds = playlists.safeValue(index: curPlaylistIndex)?.videoIdList() else { return }
        videoVms = DBManager.share.search(
            type: .video,
            filter: videoIds.contains(Column.id)
        ).map { VideoPreviewView.ViewModel.from(video: $0.toVideo()) }
    }

    // MARK: - 播放列表包含的视频增删

    private func addOrDelVideoToPlaylist(isAdd: Bool) {
        var playlist = playlists[curPlaylistIndex]
        let selectedIds = videoVms.filter { $0.isSelected }.map { $0.id }
        var videoIds = playlist.videoIdList()
        if isAdd {
            videoIds += selectedIds
            videoIds = Array(Set(videoIds))
        } else {
            videoIds.removeAll(where: { id in selectedIds.contains(id) })
        }
        playlist.videoIds = videoIds.map { String($0) }.joined(separator: ",")
        playlists[curPlaylistIndex] = playlist
        DBManager.share.updatePlaylist(id: playlist.playlistId, item: playlist)
        if curShowMode() == .playlist {
            refreshPlaylistVideo()
        } else {
            resetVideoSelectStatus(value: false)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
