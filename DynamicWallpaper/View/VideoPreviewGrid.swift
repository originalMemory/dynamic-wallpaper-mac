//
//  VideoPreviewGrid.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/21.
//

import SwiftUI

struct VideoPreviewGrid: View {
    @Binding var vms: [VideoPreviewView.ViewModel]
    let onClick: (Int, Bool, Bool) -> Void
    let selectAll: () -> Void
    let onSortChange: (VideoSortType) -> Void

    let padding: CGFloat = 10

    @State var enableMulti: Bool = false
    @State var enablePreview: Bool = false
    @State var curSortIndex = 1

    var body: some View {
        VStack {
            HStack {
                Text("总数：\(vms.count)")
                Button(vms.allSatisfy { $0.isSelected } ? "取消全选" : "全选") {}.keyboardShortcut("A", modifiers: [.command])
                Spacer()
                Toggle("允许多选", isOn: $enableMulti).toggleStyle(SwitchToggleStyle(tint: .green))
                Toggle("点击即预览", isOn: $enablePreview).toggleStyle(SwitchToggleStyle(tint: .green))
                sortTypePicker.frame(width: 150)
            }
            .padding(EdgeInsets(top: padding, leading: padding, bottom: 0, trailing: padding))
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: padding), count: 3)) {
                    let indexLength = String(vms.count).count
                    ForEach(0..<vms.count, id: \.self) { index in
                        let vm = vms[index]
                        Button {
                            onClick(vm.id, enableMulti, enablePreview)
                        } label: {
                            VideoPreviewView(
                                vm: vm,
                                index: String(format: "%0\(indexLength)d", arguments: [index + 1])
                            ).frame(height: 200)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(padding)
            }
        }
    }

    var sortTypePicker: some View {
        Picker("排序", selection: $curSortIndex) {
            ForEach(0..<VideoSortType.allCases.count, id: \.self) { i in
                Text(VideoSortType.allCases[i].text())
            }
        }
        .onChange(of: curSortIndex) { index in
            onSortChange(VideoSortType.allCases[index])
        }
    }
}

struct VideoPreviewGrid_Previews: PreviewProvider {
    static var previews: some View {
        let vms: [VideoPreviewView.ViewModel] = [
            VideoPreviewView.ViewModel.mock(id: 1, title: "1"),
            VideoPreviewView.ViewModel.mock(id: 2, title: "2"),
            VideoPreviewView.ViewModel.mock(id: 3, title: "3"),
            VideoPreviewView.ViewModel.mock(id: 4, title: "4"),
            VideoPreviewView.ViewModel.mock(id: 5, title: "5")
        ]
        VideoPreviewGrid(vms: .constant(vms)) { id, enableMulti, enablePreview in
            print(id)
        } selectAll: {} onSortChange: { type in }
            .frame(width: 800, height: 500)
    }
}

private extension VideoPreviewView.ViewModel {
    static func mock(id: Int, title: String) -> VideoPreviewView.ViewModel {
        VideoPreviewView.ViewModel(
            id: id,
            title: title,
            desc: nil,
            tags: [],
            file: "",
            previewPath: nil
        )
    }
}
