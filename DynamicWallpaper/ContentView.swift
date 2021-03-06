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
    @State private var videoSortType: VideoSortType = .addTimeDesc

    init() {
        let videos: [Video] = DBManager.share.searchAll(type: .video, orders: [VideoSortType.addTimeDesc.dbOrder()])
        videoVms = videos.map {
            VideoPreviewView.ViewModel.from(video: $0)
        }
        screenInfos = NSScreen.screens.map { screen in
            var info = ScreenInfo.from(screen: screen)
            info.playlistName = WallpaperManager.share.getScreenPlaylistName(screenHash: screen.hash)
            info.videoName = WallpaperManager.share.getScreenPlayingVideoName(screenHash: screen.hash)
            return info
        }

        let playlists = DBManager.share.searchPlaylists()
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
                    refreshVideo()
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
                } onSortChange: { type in
                    videoSortType = type
                    refreshVideo()
                }
                .onReceive(NotificationCenter.default.publisher(for: VideoImportIndexNotification)) { output in
                    if curShowMode() == .allVideo {
                        DispatchQueue.main.async {
                            refreshVideo()
                        }
                    }
                }
            }
            Divider()
            screenAndDetailView.padding(.trailing, Metric.horizontalMargin)
        }
        .frame(width: 1100, height: 850, alignment: .center)
        .onLoad {
            if videoVms.count > 0 {
                videoVms[0].isSelected = true
                curBelongPlaylists = getBelongPlaylists(videoId: videoVms[0].id)
            }
        }
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
                    refreshVideo()
                }
                Button("搜索") {
                    refreshVideo()
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
                        updatePlaylistName(id: playlists[curPlaylistIndex].pkid, name: text)
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
                refreshVideo()
            }
        }
    }

    @State private var showNoPlaylistAlert = false

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
            if curShowMode() == .allVideo, videoVms.contains { model in model.isSelected } {
                Text("播放列表")
                VStack {
                    FlexibleTagListView(tags: Tag.fromPlaylist(curBelongPlaylists), onAdd: {
                        if playlists.isEmpty {
                            showNoPlaylistAlert = true
                        } else {
                            SelectPlayListView(data: playlists) { id in
                                addOrDelVideoToPlaylist(isAdd: true, playlistId: id)
                            }
                            .showInNewWindow(title: "选择播放列表")
                        }
                    }) { tagId in
                        addOrDelVideoToPlaylist(isAdd: false, playlistId: tagId)
                    }
                    .alert(isPresented: $showNoPlaylistAlert) {
                        Alert(title: Text("没有播放列表！"))
                    }
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
            HStack {
                Button("播放设置") {
                    if let screenHash = screenInfos.safeValue(index: curScreenIndex)?.screenHash {
                        PlayConfigView(screenHash: screenHash).showInNewWindow(title: "播放设置")
                    }
                }
                switch curShowMode() {
                case .allVideo:
                    Button("设置壁纸") {
                        guard let video = videoVms.first(where: { $0.isSelected }) else {
                            return
                        }
                        setWallpaper(path: video.file, title: video.title, cleanPlaylist: true)
                    }
                case .playlist:
                    Button("设置播放列表") {
                        if let playlist = playlists.safeValue(index: curPlaylistIndex) {
                            info.playlistName = playlist.title
                            screenInfos[curScreenIndex] = info
                            WallpaperManager.share.setPlaylistToMonitor(
                                playlistId: playlist.pkid,
                                screenHash: info.screenHash
                            )
                        }
                    }
                }
            }
            Text("当前壁纸：\n\(info.videoName ?? "")").frame(maxWidth: .infinity, alignment: .leading)
            Text("当前播放列表: \n\(info.playlistName ?? "")").frame(maxWidth: .infinity, alignment: .leading)
            if info.playlistName != nil {
                HStack {
                    Button("切换下一个") {
                        WallpaperManager.share.switch2NextWallpaper(screenHash: info.screenHash)
                    }
                    Button("清除") {
                        info.playlistName = nil
                        info.videoName = nil
                        screenInfos[curScreenIndex] = info
                        WallpaperManager.share.removePlaylistToMonitor(screenHash: info.screenHash)
                    }
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
                            FlexibleTagListView(tags: Tag.fromStrList(video.tags), onAdd: {
                                TextInputView(text: nil, multiline: false) { text in
                                    if text.isEmpty {
                                        return
                                    }
                                    var tags = video.tags
                                    tags.append(text)
                                    updateVideoTags(videoId: video.id, tags: tags)
                                }
                                .showInNewWindow(title: "添加标签")
                            }) { index in
                                var tags = video.tags
                                tags.remove(at: index)
                                updateVideoTags(videoId: video.id, tags: tags)
                            }
                        }
                    }
                    HStack {
                        Button("删除") { delSelectedVideo() }
                        if curShowMode() == .playlist {
                            Button("从列表中移除") {
                                addOrDelVideoToPlaylist(
                                    isAdd: false,
                                    playlistId: playlists[curPlaylistIndex].pkid
                                )
                            }
                        }
                    }
                }
                .padding(5)
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Color.white))
            }
        }
    }

    private func updateVideoTags(videoId: Int, tags: [String]) {
        guard var video = DBManager.share.getVideo(id: videoId) else { return }
        video.tags = tags
        DBManager.share.update(type: .video, obj: video)
        guard let index = videoVms.firstIndex(where: { $0.id == videoId }) else { return }
        var newVm = VideoPreviewView.ViewModel.from(video: video)
        newVm.isSelected = true
        videoVms[index] = newVm
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
        case .none:
            text = ""
        }
        let showEditHint = videoDetailHoverType == showHoverStatus
        return Button {
            TextInputView(text: text, multiline: true) { text in
                guard var video = DBManager.share.getVideo(id: vm.id) else { return }
                switch showHoverStatus {
                case .desc:
                    video.desc = text
                case .title:
                    video.title = text
                case .none:
                    break
                }
                DBManager.share.update(type: .video, obj: video)
                guard let index = videoVms.firstIndex(where: { $0.id == vm.id }) else { return }
                var newVm = VideoPreviewView.ViewModel.from(video: video)
                newVm.isSelected = true
                videoVms[index] = newVm
            }
            .show()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Text(text ?? "").frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                if showEditHint {
                    Image(systemName: "square.and.pencil").foregroundColor(.green).padding(3)
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

    @State private var curBelongPlaylists: [Playlist] = []

    private func onVideoPreviewClick(id: Int, enableMulti: Bool, enablePreview: Bool) {
        if !enableMulti {
            resetVideoSelectStatus(value: false)
        }
        guard let index = videoVms.firstIndex(where: { $0.id == id }) else { return }
        var video = videoVms[index]
        videoVms[index] = video.setSelected(value: !video.isSelected)
        curBelongPlaylists = enableMulti ? [] : getBelongPlaylists(videoId: video.id)
        if enablePreview {
            setWallpaper(path: video.file, title: video.title, cleanPlaylist: false)
        }
    }

    private func getBelongPlaylists(videoId: Int) -> [Playlist] {
        let playlists = DBManager.share.searchPlaylists(sqlWhere: "videoIds like '%\(videoId)%'")
        return playlists.filter { $0.videoIds.contains(videoId) }
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

    private func refreshVideo() {
        var sqlWhere = "1=1"
        let prefix = " AND "
        if !searchTitle.isEmpty {
            sqlWhere += prefix + "title like '%\(searchTitle)%'"
        }
        if curShowMode() == .playlist, let videoIds = playlists.safeValue(index: curPlaylistIndex)?.videoIds {
            let videoIdStr = videoIds.map { String($0) }.joined(separator: ",")
            sqlWhere += prefix + "rowid in(\(videoIdStr))"
        }
        videoVms = DBManager.share.searchVideos(sqlWhere: sqlWhere, orders: [videoSortType.dbOrder()]).map {
            VideoPreviewView.ViewModel.from(video: $0)
        }
    }

    private func delSelectedVideo() {
        let videoIds = videoVms.filter { $0.isSelected }.map { $0.id }
        for videoId in videoIds {
            for playlist in playlists {
                playlist.videoIds.removeAll { $0 == videoId }
                DBManager.share.update(type: .playlist, obj: playlist)
            }
            DBManager.share.delete(type: .video, id: videoId)
            VideoHelper.share.delVideo(id: videoId)
        }
        videoVms.removeAll { vm in videoIds.contains(vm.id) }
        refreshPlaylist()
    }

    // MARK: - 播放列表管理

    private func createPlaylist(name: String) {
        let playlist = Playlist()
        playlist.title = name
        DBManager.share.insert(type: .playlist, obj: playlist)
        refreshPlaylist()
    }

    private func updatePlaylistName(id: Int, name: String) {
        guard var playlist = DBManager.share.getPlaylist(id: id) else { return }
        playlist.title = name
        DBManager.share.update(type: .playlist, obj: playlist)
        refreshPlaylist()
    }

    private func delPlaylist() {
        guard let playlistId = playlists.safeValue(index: curPlaylistIndex)?.pkid else { return }
        DBManager.share.delete(type: .playlist, id: playlistId)
        refreshPlaylist()
        if curPlaylistIndex >= playlists.count {
            curPlaylistIndex -= 1
        }
    }

    private func refreshPlaylist() {
        playlists = DBManager.share.searchPlaylists()
    }

    // MARK: - 播放列表包含的视频增删

    private func addOrDelVideoToPlaylist(isAdd: Bool, playlistId: Int) {
        guard var playlist = playlists.first(where: { $0.pkid == playlistId }) else { return }
        let selectedIds = videoVms.filter { $0.isSelected }.map { $0.id }
        if isAdd {
            playlist.videoIds += selectedIds
            curBelongPlaylists.append(playlist)
        } else {
            playlist.videoIds.removeAll(where: { id in selectedIds.contains(id) })
            curBelongPlaylists.removeAll { $0.pkid == playlistId }
        }
        DBManager.share.update(type: .playlist, obj: playlist)
        refreshPlaylist()
        if curShowMode() == .playlist {
            refreshVideo()
        } else if selectedIds.count > 1 {
            resetVideoSelectStatus(value: false)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
