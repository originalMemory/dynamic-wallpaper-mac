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
        let previewImage: NSImage?

        static func from(video: Video) -> ViewModel {
            let path = VideoHelper.share.getFullPath(videoId: video.id, filename: video.preview)
            return VideoPreviewView.ViewModel(
                id: video.id,
                title: video.title,
                previewImage: path != nil ? NSImage(contentsOfFile: path!) : nil
            )
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    private let corner = RoundedRectangle(cornerRadius: 10, style: .continuous)

    let vm: ViewModel
    let isSelected: Bool
    @State var isHover = false

    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geometryProxy in
                if let previewImage = vm.previewImage {
                    Image(nsImage: previewImage).resizable().scaledToFill().frame(
                        width: geometryProxy.size.width,
                        height: geometryProxy.size.height
                    ).clipShape(corner)
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
        .overlay(corner.stroke(isSelected ? Color.blue : Color.white, lineWidth: isSelected ? 2 : 1))
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
            previewImage: nil
        )
        return VideoPreviewView(vm: model, isSelected: false).frame(width: 400, height: 300)
    }
}
