//
//  DropdownSelector.swift
//  DynamicWallpaper。源自 [Creating a simple and reusable Dropdown selector using SwiftUI](https://emmanuelkehinde.io/creating-a-simple-and-reusable-dropdown-selector-in-swiftui/)
//
//  Created by 吴厚波 on 2022/4/18.
//

import SwiftUI

/// 下拉选项数据结构
struct DropdownOption: Hashable {
    let key: String
    let value: String

    public static func == (lhs: DropdownOption, rhs: DropdownOption) -> Bool {
        return lhs.key == rhs.key
    }
}

/// 下拉选项弹出行 View
struct DropdownRow: View {
    var option: DropdownOption
    var onOptionSelected: ((_ option: DropdownOption) -> Void)?
    @State var isHover = false

    var body: some View {
        Button(action: {
            if let onOptionSelected = onOptionSelected {
                onOptionSelected(option)
            }
        }) {
            HStack {
                Text(option.value)
                    .font(.system(size: 14))
                    .foregroundColor(Color.black)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .onHover {
            isHover = $0
        }
        .background(isHover ? Color.gray.opacity(0.5) : Color.clear)
    }
}

/// 下拉菜单弹出整体 View
struct Dropdown: View {
    var options: [DropdownOption]
    var onOptionSelected: ((_ option: DropdownOption) -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(options, id: \.self) { option in
                    DropdownRow(option: option, onOptionSelected: onOptionSelected)
                }
            }
        }
        .frame(minHeight: CGFloat(options.count) * 30, maxHeight: 250)
        .padding(.vertical, 5)
        .background(Color.white)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
}

/// 下拉菜单整体 View
struct DropdownSelector: View {
    @State private var shouldShowDropdown = false
    var placeholder: String
    var options: [DropdownOption]
    let selectIndex: Int?
    var popAlignment: Alignment = .topLeading
    var buttonHeight: CGFloat = 30
    var onOptionSelected: ((_ option: DropdownOption) -> Void)?

    var body: some View {
        Button(action: {
            self.shouldShowDropdown.toggle()
        }) {
            HStack {
                let selectText = options.safeValue(index: selectIndex)?.value
                Text(selectText ?? placeholder)
                    .font(.system(size: 14))
                    .foregroundColor(selectText == nil ? Color.gray : Color.black)

                Spacer()

                Image(systemName: self.shouldShowDropdown ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .resizable()
                    .frame(width: 9, height: 5)
                    .font(Font.system(size: 9, weight: .medium))
                    .foregroundColor(Color.black)
            }
        }
        .padding(.horizontal)
        .cornerRadius(5)
        .frame(width: .infinity, height: self.buttonHeight)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray, lineWidth: 1)
        )
        .overlay(
            VStack {
                if shouldShowDropdown {
                    if popAlignment.vertical == .top {
                        Spacer(minLength: buttonHeight + 10)
                    }
                    Dropdown(options: self.options, onOptionSelected: { option in
                        shouldShowDropdown = false
                        onOptionSelected?(option)
                    })
                    if popAlignment.vertical == .bottom {
                        Spacer(minLength: buttonHeight + 10)
                    }
                }
            }, alignment: popAlignment
        )
        .background(
            RoundedRectangle(cornerRadius: 5).fill(Color.white)
        )
    }
}

struct DropdownSelector_Previews: PreviewProvider {
    static var uniqueKey: String {
        UUID().uuidString
    }

    static let options: [DropdownOption] = [
        DropdownOption(key: uniqueKey, value: "Sunday"),
        DropdownOption(key: uniqueKey, value: "Monday"),
        DropdownOption(key: uniqueKey, value: "Tuesday"),
        DropdownOption(key: uniqueKey, value: "Wednesday"),
        DropdownOption(key: uniqueKey, value: "Thursday"),
        DropdownOption(key: uniqueKey, value: "Friday"),
        DropdownOption(key: uniqueKey, value: "Saturday")
    ]

    static var previews: some View {
        Group {
            DropdownSelector(
                placeholder: "Day of the week",
                options: options,
                selectIndex: nil,
                buttonHeight: 45,
                onOptionSelected: { option in
                    print(option)
                }
            )
            .padding(.horizontal)
        }
    }
}
