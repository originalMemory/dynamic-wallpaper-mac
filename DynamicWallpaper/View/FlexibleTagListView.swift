//
//  FlexibleTagListView.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/6/13.
//

import SwiftUI

struct Tag: Hashable {
    static let addTagId: Int = -1
    let name: String
    let id: Int

    static func fromPlaylist(_ playlists: [Playlist]) -> [Tag] {
        appendAdd(tags: playlists.map { item in Tag(name: item.title, id: item.id) })
    }

    static func appendAdd(tags: [Tag]) -> [Tag] {
        tags + [Tag(name: "add", id: addTagId)]
    }

    static func fromStrList(_ list: [String]) -> [Tag] {
        appendAdd(tags: list.enumerated().map { i, item in Tag(name: item, id: i) })
    }
}

struct TagView: View {
    let tag: Tag
    let onPress: (Int) -> Void
    private let corner = RoundedRectangle(cornerRadius: 8, style: .continuous)

    var body: some View {
        if tag.id == Tag.addTagId {
            Button {
                onPress(tag.id)
            } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(PlainButtonStyle())

        } else {
            HStack {
                Text(tag.name)
                Button {
                    onPress(tag.id)
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
    let onDel: (Int) -> Void

    var body: some View {
        FlexibleView(data: tags, spacing: 5, alignment: .leading) { item in
            TagView(tag: item) { id in
                if id == Tag.addTagId {
                    onAdd()
                } else {
                    onDel(id)
                }
            }
        }
    }
}

struct FlexibleTagListView_Previews: PreviewProvider {
    static var previews: some View {
        FlexibleTagListView(tags: [
            Tag(name: "第一个", id: 1),
            Tag(name: "第二个", id: 2),
            Tag(name: "add", id: Tag.addTagId),
        ], onAdd: {}, onDel: { _ in })
    }
}
