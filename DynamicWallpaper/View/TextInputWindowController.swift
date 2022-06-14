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
    private let multiline: Bool

    init(text: String?, multiline: Bool, onConfirm: @escaping InputListener) {
        self.onConfirm = onConfirm
        self.multiline = multiline
        if let safeText = text {
            _text = State(initialValue: safeText)
        }
    }

    var body: some View {
        HStack {
            if multiline {
                TextEditor(text: $text)
                    .frame(height: 80)
                    .padding(5)
                    .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Color.white))
            } else {
                TextField("输入内容", text: $text)
            }
            Button("确认") {
                onConfirm(text)
                NSApplication.shared.keyWindow?.close()
            }
        }
        .frame(width: 250)
        .padding(10)
    }

    func show() {
        showInNewWindow(title: "输入文本")
    }
}

struct TextInputView_Previews: PreviewProvider {
    static var previews: some View {
        TextInputView(text: nil, multiline: true, onConfirm: { _ in })
    }
}

class TextInputWC: NSWindowController {
    convenience init(text: String? = nil, onConfirm: @escaping InputListener) {
        let view = TextInputView(text: text, multiline: false, onConfirm: onConfirm)
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "输入文本"
        self.init(window: window)
    }
}
