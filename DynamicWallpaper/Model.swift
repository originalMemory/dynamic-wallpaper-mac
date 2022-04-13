//
// Created by 吴厚波 on 2022/4/13.
//

import Foundation

struct VideoInfo {
    let id: Int
    let name: String
    let desc: String
    let relativePath: String
}

struct PlayList {
    let id: Int
    let name: String
    let videos: [VideoInfo]
}
