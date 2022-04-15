//
//  VideoPreviewView.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/15.
//

import SwiftUI

/// 视频预览 view
struct VideoPreviewView: View {
    struct ViewModel {
        let id: Int64?
        let title: String
        let previewPath: String?

        static func fromVideo(_ video: Video) -> ViewModel {
            VideoPreviewView.ViewModel(
                id: video.id,
                title: video.title,
                previewPath: VideoHelper.share.getFullPath(videoId: video.id, filename: video.preview)
            )
        }
    }

    @State var vm: ViewModel

    private let corner = RoundedRectangle(cornerRadius: 10, style: .continuous)

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
        }
        .overlay(corner.stroke(Color.white))
    }
}

struct VideoPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPreviewView(vm: VideoPreviewView.ViewModel(id: 0, title: "测试标题", previewPath: nil))
            .frame(width: 400, height: 300)
    }
}
