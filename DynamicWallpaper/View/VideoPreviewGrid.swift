//
//  VideoPreviewGrid.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/21.
//

import SwiftUI

struct VideoPreviewGrid: View {
    @Binding var vms: [VideoPreviewView.ViewModel]
    let onClick: (Int64, Bool) -> Void

    let padding: CGFloat = 10

    @State var enableMulti: Bool = false

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Toggle("允许多选", isOn: $enableMulti).toggleStyle(SwitchToggleStyle(tint: .green))
            }
            .padding(EdgeInsets(top: padding, leading: padding, bottom: 0, trailing: padding))
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: padding), count: 3)) {
                    ForEach(vms, id: \.self) { vm in
                        VideoPreviewView(vm: vm).frame(height: 200)
                            .onTapGesture {
                                onClick(vm.id, enableMulti)
                            }
                    }
                }
                .padding(padding)
            }
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
        VideoPreviewGrid(vms: .constant(vms)) { id, enableMulti in
            print(id)
        }
        .frame(width: 800, height: 500)
    }
}

private extension VideoPreviewView.ViewModel {
    static func mock(id: Int64, title: String, isSelected: Bool = false) -> VideoPreviewView.ViewModel {
        VideoPreviewView.ViewModel(
            id: id,
            title: title,
            desc: nil,
            tags: nil,
            file: "",
            previewImage: nil,
            isSelected: isSelected
        )
    }
}
