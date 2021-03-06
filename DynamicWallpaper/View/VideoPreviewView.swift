//
//  VideoPreviewView.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/15.
//

import SwiftUI
import GIFImage

/// 视频预览 view
struct VideoPreviewView: View {
    struct ViewModel: Hashable {
        let id: Int
        let title: String
        let desc: String?
        let tags: [String]
        let file: String
        let previewPath: String?
        var isSelected: Bool = false

        static func from(video: Video) -> ViewModel {
            VideoPreviewView.ViewModel(
                id: video.pkid,
                title: video.title,
                desc: video.desc,
                tags: video.tags,
                file: video.fullFilePath() ?? "",
                previewPath: video.fullPreviewPath()
            )
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        mutating func setSelected(value: Bool) -> Self {
            isSelected = value
            return self
        }
    }

    private let corner = RoundedRectangle(cornerRadius: 10, style: .continuous)

    let vm: ViewModel
    let index: String
    @State var isHover = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // 通过这个限制高度为外面设置的高度
            GeometryReader { _ in
                if let path = vm.previewPath {
                    if path.components(separatedBy: ".").last?.lowercased() == "gif" {
                        GIFImage(source: .local(filePath: path)).scaledToFill()
                    } else if let previewImage = NSImage(contentsOfFile: path) {
                        Image(nsImage: previewImage).resizable().scaledToFill()
                    } else {
                        Image("defaultPreview").resizable().scaledToFill()
                    }
                } else {
                    Image("defaultPreview").resizable().scaledToFill()
                }
            }
            VStack {
                createLine(text: index)
                Spacer()
                createLine(text: vm.title)
            }
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

    private func createLine(text: String) -> some View {
        HStack {
            Spacer()
            Text(text)
            Spacer()
        }
        .frame(height: 30).foregroundColor(Color.white)
        .background(Color.black.opacity(0.4))
    }
}

struct VideoPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        let model = VideoPreviewView.ViewModel(
            id: 0,
            title: "测试标题2",
            desc: nil,
            tags: [],
            file: "",
            previewPath: nil
        )
        return VideoPreviewView(vm: model, index: "1").frame(width: 400, height: 300)
    }
}
