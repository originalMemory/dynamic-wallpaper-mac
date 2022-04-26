//
//  VideoPreviewView.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/15.
//

import SwiftUI

/// 视频预览 view
struct VideoPreviewView: View {
    struct ViewModel: Hashable {
        let id: Int64
        let title: String
        let desc: String?
        let tags: String?
        let file: String
        let previewImage: NSImage?
        var isSelected: Bool

        static func from(video: Video) -> ViewModel {
            let path = VideoHelper.share.getFullPath(videoId: video.videoId, filename: video.preview)
            return VideoPreviewView.ViewModel(
                id: video.videoId,
                title: video.title,
                desc: video.desc,
                tags: video.tags,
                file: video.file,
                previewImage: path != nil ? NSImage(contentsOfFile: path!) : nil,
                isSelected: false
            )
        }

        func copy(isSelect: Bool) -> ViewModel {
            ViewModel(
                id: id,
                title: title,
                desc: desc,
                tags: tags,
                file: file,
                previewImage: previewImage,
                isSelected: isSelect
            )
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    private let corner = RoundedRectangle(cornerRadius: 10, style: .continuous)

    let vm: ViewModel
    @State var isHover = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // 通过这个限制高度为外面设置的高度
            GeometryReader { _ in
                if let previewImage = vm.previewImage {
                    Image(nsImage: previewImage).resizable().scaledToFill()
                } else {
                    Image("defaultPreview").resizable().scaledToFill()
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
        // 裁剪点击区域，这个必须有，才能裁剪掉点击区域
        .contentShape(corner)
        // 裁剪显示区域
        .clipShape(corner)
        .overlay(corner.stroke(vm.isSelected ? Color.blue : Color.white, lineWidth: vm.isSelected ? 2 : 1))
        .onHover { hover in
            isHover = hover
        }
    }
}

struct VideoPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        let model = VideoPreviewView.ViewModel(
            id: 0,
            title: "测试标题2",
            desc: nil,
            tags: nil,
            file: "",
            previewImage: nil,
            isSelected: false
        )
        return VideoPreviewView(vm: model).frame(width: 400, height: 300)
    }
}
