//
//  File.swift
//
//
//  Created by Igor Ferreira on 05/04/2022.
//

import Foundation
import ImageIO

public struct CGImageSourceFrameSequence: AsyncSequence {
    public typealias Element = ImageFrame

    public let source: CGImageSource
    public let loop: Bool

    public init?(data: Data, loop: Bool) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        self.init(source: source, loop: loop)
    }

    public init(source: CGImageSource, loop: Bool) {
        self.source = source
        self.loop = loop
    }

    public func makeAsyncIterator() -> CGImageSourceIterator {
        CGImageSourceIterator(source: source, loop: loop)
    }
}
