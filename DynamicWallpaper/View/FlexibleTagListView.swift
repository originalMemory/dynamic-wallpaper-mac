//
//  FlexibleTagListView.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/6/13.
//

import SwiftUI

struct Tag: Hashable {
    static let addTagId: Int64 = -1
    let name: String
    let tagId: Int64

    static func fromPlaylist(playlists: [Playlist]) -> [Tag] {
        var res = playlists.map { item in
            Tag(name: item.title, tagId: item.playlistId)
        }
        res.append(Tag(name: "add", tagId: addTagId))
        return res
    }
}

struct TagView: View {
    let name: String
    let tagId: Int64
    let onPress: (Int64) -> Void
    private let corner = RoundedRectangle(cornerRadius: 8, style: .continuous)

    var body: some View {
        if tagId == Tag.addTagId {
            Button {
                onPress(tagId)
            } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(PlainButtonStyle())

        } else {
            HStack {
                Text(name)
                Button {
                    onPress(tagId)
                } label: {
                    Image(systemName: "xmark").frame(width: 10, height: 10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(8)
            .background(Color.gray.opacity(0.2))
            .frame(height: 24)
            .contentShape(corner)
            .clipShape(corner)
        }
    }
}

struct FlexibleTagListView: View {
    let tags: [Tag]
    let onAdd: () -> Void
    let onDel: (Int64) -> Void

    var body: some View {
        FlexibleView(data: tags, spacing: 5, alignment: .leading) { item in
            TagView(name: item.name, tagId: item.tagId) { tagId in
                if tagId == Tag.addTagId {
                    onAdd()
                } else {
                    onDel(tagId)
                }
            }
        }
    }
}

struct FlexibleTagListView_Previews: PreviewProvider {
    static var previews: some View {
        FlexibleTagListView(tags: [
            Tag(name: "第一个", tagId: 1),
            Tag(name: "第二个", tagId: 2),
            Tag(name: "add", tagId: Tag.addTagId),
        ], onAdd: {}, onDel: { _ in })
    }
}
