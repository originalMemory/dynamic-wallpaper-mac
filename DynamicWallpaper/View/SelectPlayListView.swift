//
// Created by 吴厚波 on 2022/6/14.
//

import SwiftUI

struct SelectPlayListView: View {
    let data: [Playlist]
    let onConfirm: (Int) -> Void
    @State private var index = 0

    var body: some View {
        VStack(alignment: .leading) {
            Picker("", selection: $index) {
                ForEach(0..<data.count, id: \.self) { i in
                    Text(data[i].title)
                }
            }
            .labelsHidden()
            HStack {
                Spacer()
                Button("保存") {
                    onConfirm(data[index].playlistId)
                    NSApplication.shared.keyWindow?.close()
                }
                Button("取消") {
                    NSApplication.shared.keyWindow?.close()
                }
                Spacer()
            }
        }
        .padding().frame(width: 200)
    }
}

struct SelectPlayListView_Previews: PreviewProvider {
    static var previews: some View {
        SelectPlayListView(data: []) { _ in }
    }
}
