//
//  VideoPreviewGrid.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/21.
//

import SwiftUI

struct VideoPreviewGrid: View {
    @Binding var vms: [VideoPreviewView.ViewModel]
    let onClick: ([Int64]) -> Void

    let padding: CGFloat = 10

    @State private var selectedIds: [Int64] = []
    @State var enableMulti: Bool = false

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Spacer()
                    Toggle("允许多选", isOn: $enableMulti).toggleStyle(SwitchToggleStyle(tint: .green))
                }.padding(EdgeInsets(top: padding, leading: padding, bottom: 0, trailing: padding))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: padding), count: 3)) {
                    ForEach(vms, id: \.self) { vm in
                        VideoPreviewView(vm: vm, isSelected: selectedIds.contains(vm.id)).frame(height: 200)
                            .onTapGesture {
                                if !enableMulti {
                                    selectedIds.removeAll()
                                }
                                if selectedIds.contains(vm.id) {
                                    selectedIds.removeAll { $0 == vm.id }
                                } else {
                                    selectedIds.append(vm.id)
                                }
                                onClick(selectedIds)
                            }
                    }
                }.padding(padding)
            }
        }
    }
}

struct VideoPreviewGrid_Previews: PreviewProvider {
    static var previews: some View {
        let vms: [VideoPreviewView.ViewModel] = [
            VideoPreviewView.ViewModel(id: 1, title: "1", previewPath: nil),
            VideoPreviewView.ViewModel(id: 2, title: "2", previewPath: nil),
            VideoPreviewView.ViewModel(id: 3, title: "3", previewPath: nil),
            VideoPreviewView.ViewModel(id: 4, title: "4", previewPath: nil),
            VideoPreviewView.ViewModel(id: 5, title: "5", previewPath: nil),
            VideoPreviewView.ViewModel(id: 6, title: "6", previewPath: nil),
            VideoPreviewView.ViewModel(id: 7, title: "7", previewPath: nil),
            VideoPreviewView.ViewModel(id: 8, title: "8", previewPath: nil),
            VideoPreviewView.ViewModel(id: 9, title: "9", previewPath: nil),
            VideoPreviewView.ViewModel(id: 10, title: "10", previewPath: nil)
        ]
        VideoPreviewGrid(vms: .constant(vms)) { ids in
            print(ids)
        }.frame(width: 800, height: 500)
    }
}
