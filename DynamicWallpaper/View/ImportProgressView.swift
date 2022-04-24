//
//  ImportProgressView.swift
//  DynamicWallpaper
//
//  Created by 吴厚波 on 2022/4/24.
//

import SwiftUI

struct ImportProgressView: View {
    @State private var curIndex = 0
    @State private var value: CGFloat = 0
    @State private var valueAnimation = CGFloat()
    let paths: [String]
    var body: some View {
        VStack(alignment: .leading) {
            if curIndex < paths.count {
                Text("当前导入文件 [\(curIndex)/\(paths.count)] \(paths[curIndex])")
            } else {
                Text("\(paths.count) 全部导入结束")
            }
            ProgressView(
                String(format: "进度%.2f%%", arguments: [value * 100]),
                value: valueAnimation
            ).customAnimation(value: value, valueAnimation: $valueAnimation, duration: 0.2)
                .progressViewStyle(MyProgressViewStyle()).frame(height: 20)
        }
        .padding()
        .frame(width: 600)
        .onReceive(NotificationCenter.default.publisher(for: VideoImportIndexNotification)) { output in
            guard let userInfo = output.userInfo, let index = userInfo["index"] as? Int else { return }
            DispatchQueue.main.async {
                curIndex = index + 1
                value = CGFloat(curIndex) / CGFloat(paths.count)
                if curIndex == paths.count {
                    NSApplication.shared.keyWindow?.close()
                }
            }
        }
    }

    init(paths: [String]) {
        self.paths = paths
        VideoHelper.share.importVideo(filePaths: paths)
    }
}

struct ImportProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ImportProgressView(paths: ["1", "2"])
    }
}

// 定义方法都大同小异。
struct MyProgressViewStyle: ProgressViewStyle {
    let foregroundColor: Color
    let backgroundColor: Color

    init(foregroundColor: Color = .green, backgroundColor: Color = .gray) {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
    }

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                backgroundColor
                Rectangle()
                    .fill(foregroundColor)
                    .frame(width: proxy.size.width * CGFloat(configuration.fractionCompleted ?? 0.0))
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                configuration.label
                    .foregroundColor(.white)
            )
        }
    }
}

struct CustomAnimationViewModifier: ViewModifier {
    var value: CGFloat
    @Binding var valueAnimation: CGFloat
    var duration: Double
    var qualityOfAnimation: Quality

    init(value: CGFloat, valueAnimation: Binding<CGFloat>, duration: Double, qualityOfAnimation: Quality) {
        self.value = value
        self._valueAnimation = valueAnimation
        self.duration = duration
        self.qualityOfAnimation = qualityOfAnimation
    }

    func body(content: Content) -> some View {
        return content
            .onAppear { valueAnimation = value }
            .onChange(of: value) { [value] newValue in

                let millisecondsDuration = Int(duration * 1000)
                let tik: Int = qualityOfAnimation.rawValue
                let step: CGFloat = (newValue - value) / CGFloat(millisecondsDuration / tik)
                valueAnimationFunction(tik: tik, step: step, value: newValue, increasing: step > 0.0 ? true : false)
            }
    }

    func valueAnimationFunction(tik: Int, step: CGFloat, value: CGFloat, increasing: Bool) {
        if increasing {
            if valueAnimation + step < value {
                valueAnimation += step

                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(tik)) {
                    valueAnimationFunction(tik: tik, step: step, value: value, increasing: increasing)
                }
            } else {
                valueAnimation = value
            }
        } else {
            if valueAnimation + step > value {
                valueAnimation += step

                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(tik)) {
                    valueAnimationFunction(tik: tik, step: step, value: value, increasing: increasing)
                }
            } else {
                valueAnimation = value
            }
        }
    }
}

extension View {
    func customAnimation(
        value: CGFloat,
        valueAnimation: Binding<CGFloat>,
        duration: Double,
        qualityOfAnimation: Quality = Quality.excellent
    ) -> some View {
        return self.modifier(CustomAnimationViewModifier(
            value: value,
            valueAnimation: valueAnimation,
            duration: duration,
            qualityOfAnimation: qualityOfAnimation
        ))
    }
}

enum Quality: Int, CustomStringConvertible {
    case excellent = 1, high = 10, basic = 100, slow = 1000

    var description: String {
        switch self {
        case .excellent: return "excellent"
        case .high: return "high"
        case .basic: return "basic"
        case .slow: return "slow"
        }
    }
}

extension Double { var rounded: String { return String(Double(self * 100.0).rounded() / 100.0) } }
