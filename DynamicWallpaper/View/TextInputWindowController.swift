//
//  TextInputView.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/19.
//

import SwiftUI

typealias InputListener = (String) -> Void

struct TextInputView: View {
    @State private var text: String = ""
    private let onConfirm: InputListener

    init(text: String?, onConfirm: @escaping InputListener) {
        self.onConfirm = onConfirm
        if let safeText = text {
            _text = State(initialValue: safeText)
        }
    }

    var body: some View {
        HStack {
            TextField("输入内容", text: $text)
            Button("确认") {
                onConfirm(text)
                NSApplication.shared.keyWindow?.close()
            }
        }
        .frame(width: 250)
        .padding(10)
    }
}

struct TextInputView_Previews: PreviewProvider {
    static var previews: some View {
        TextInputView(text: nil, onConfirm: { _ in })
    }
}

class TextInputWC: NSWindowController {
    convenience init(text: String? = nil, onConfirm: @escaping InputListener) {
        let view = TextInputView(text: text, onConfirm: onConfirm)
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "输入文本"
        self.init(window: window)
    }
}
