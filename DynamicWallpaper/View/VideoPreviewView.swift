//
//  VideoPreviewView.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/15.
//

import SwiftUI

/// 视频预览 view
struct VideoPreviewView: View {
    class ViewModel {
        let id: Int64
        let title: String
        let filePath: String?
        let previewPath: String?
        let desc: String?
        let tags: String?
        var isSelected: Bool

        init(
            id: Int64,
            title: String,
            filePath: String?,
            previewPath: String?,
            desc: String?,
            tags: String?,
            isSelected: Bool
        ) {
            self.id = id
            self.title = title
            self.filePath = filePath
            self.previewPath = previewPath
            self.desc = desc
            self.tags = tags
            self.isSelected = isSelected
        }

        static func from(video: Video) -> ViewModel {
            VideoPreviewView.ViewModel(
                id: video.id,
                title: video.title,
                filePath: VideoHelper.share.getFullPath(videoId: video.id, filename: video.file),
                previewPath: VideoHelper.share.getFullPath(videoId: video.id, filename: video.preview),
                desc: video.desc,
                tags: video.tags,
                isSelected: false
            )
        }
    }

    private let corner = RoundedRectangle(cornerRadius: 10, style: .continuous)

    @Binding var vm: ViewModel
    @State var isHover = false

    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geometryProxy in
                if let previewPath = vm.previewPath {
                    AsyncImage(url: URL(fileURLWithPath: previewPath)) { phase in
                        switch phase {
                        case .empty:
                            // TODO: loading image
                            Image("defaultPreview").resizable().scaledToFill().frame(
                                width: geometryProxy.size.width,
                                height: geometryProxy.size.height
                            ).clipped()
                        case let .success(image):
                            image.resizable().scaledToFill().frame(
                                width: geometryProxy.size.width,
                                height: geometryProxy.size.height
                            ).clipShape(corner)
                        case .failure:
                            Image(systemName: "exclamationmark.icloud")
                                .resizable()
                                .scaledToFit()
                        @unknown default:
                            Image(systemName: "exclamationmark.icloud")
                        }
                    }
                } else {
                    Image("defaultPreview").resizable().scaledToFill().frame(
                        width: geometryProxy.size.width,
                        height: geometryProxy.size.height
                    ).clipShape(corner)
                }
            }
            HStack {
                Spacer()
                Text(vm.title)
                Spacer()
            }
            .frame(height: 30).foregroundColor(Color.white)
            .background(Color.black.opacity(0.4))
            if isHover {
                Color.white.opacity(0.3).clipShape(corner)
            }
        }
        .overlay(corner.stroke(vm.isSelected ? Color.blue : Color.white, lineWidth: vm.isSelected ? 2 : 1))
        .onHover { hover in
            isHover = hover
        }
    }
}

struct VideoPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        @State var model = VideoPreviewView.ViewModel(
            id: 0,
            title: "测试标题",
            filePath: nil,
            previewPath: nil,
            desc: "",
            tags: "",
            isSelected: false
        )
        return VideoPreviewView(vm: $model).frame(width: 400, height: 300)
    }
}
