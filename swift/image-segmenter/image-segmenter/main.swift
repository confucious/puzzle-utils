//
//  main.swift
//  image-segmenter
//
//  Created by Jerry Hsu on 1/4/21.
//

import Foundation
import ArgumentParser
import SwiftImage

typealias Point = Int

extension Point {
    init(_ x: Int, _ y: Int) {
        self = x + 10000 + y * 100_000_000
    }

    var x: Int {
        self % 100_000_000 - 10_000
    }

    var y: Int {
        self / 100_000_000
    }

    func offset(_ deltaX: Int, _ deltaY: Int) -> Point {
        return Point(self.x + deltaX, self.y + deltaY)
    }
}

struct Segment: ParsableCommand {
    typealias FullColor=RGBA<UInt8>

    static var configuration = CommandConfiguration(
        abstract: "Utility to find and extract sub-images from image files.",
        version: "0.0.0")

    @Argument(help: "Input image files")
    var filenames: [String]

    func segment(filename: String) -> [Image<FullColor>] {
        guard let image = Image<FullColor>(contentsOfFile: filename) else {
            fatalError("Could not load image \(filename)")
        }

        var segments = Set<IndexSet>()

        for y in 0..<image.height {
            for x in 0..<image.width {
                if image[x, y].gray == 255 {
                    continue
                }
                let point = Point(x, y)
                let candidates = [
                    point.offset(-1, 0),
                    point.offset(0, -1),
                    point.offset(-1, -1),
                    point.offset(1, -1)
                ]
                var matchingSets = Array<IndexSet>()
                for segment in segments {
                    if candidates.first(where: { (candidate) -> Bool in
                        segment.contains(candidate)
                    }) != nil {
                        matchingSets.append(segment)
                    }
                }
                if matchingSets.count > 1 {
                    segments.subtract(matchingSets)
                    var union = matchingSets.reduce(into: IndexSet()) { (union, nextSet) in
                        union.formUnion(nextSet)
                    }
                    union.insert(point)
                    segments.insert(union)
                } else if matchingSets.count == 1 {
                    var matchingSet = matchingSets[0]
                    segments.remove(matchingSet)
                    matchingSet.insert(point)
                    segments.insert(matchingSet)
                } else {
                    segments.insert([point])
                }
            }
        }

        var results = Array<Image<FullColor>>()
        for segment in segments {
            let point = segment.first!
            var minPointX = point.x
            var minPointY = point.y
            var maxPointX = point.x
            var maxPointY = point.y
            for point in segment {
                minPointX = min(minPointX, point.x)
                minPointY = min(minPointY, point.y)
                maxPointX = max(maxPointX, point.x)
                maxPointY = max(maxPointY, point.y)
            }
            let minPoint = Point(minPointX, minPointY)
            let maxPoint = Point(maxPointX, maxPointY)
            let floodMin = minPoint.offset(-1, -1)
            let floodMax = maxPoint.offset(1, 1)
            var outside: IndexSet = [floodMin]
            var seen = outside
            var active = outside
            while !active.isEmpty {
                let current = active[active.startIndex]
                active.remove(current)
                let candidates = [
                    current.offset(-1, 0),
                    current.offset(0, -1),
                    current.offset(1, 0),
                    current.offset(0, 1)
                ]
                for candidate in candidates {
                    if !segment.contains(candidate)
                        && !seen.contains(candidate)
                        && candidate.x >= floodMin.x
                        && candidate.y >= floodMin.y
                        && candidate.x <= floodMax.x
                        && candidate.y <= floodMax.y {
                        outside.insert(candidate)
                        active.insert(candidate)
                    }
                    seen.insert(candidate)
                }
            }
            let outWidth = maxPointX - minPointX + 1
            let outHeight = maxPointY - minPointY + 1
            if outHeight < 25 || outWidth < 25 {
                continue
            }
            var out = Image<FullColor>(width: outWidth, height: outHeight, pixel: .clear)
            for y in 0..<outHeight {
                for x in 0..<outWidth {
                    let testPoint = minPoint.offset(x, y)
                    if !outside.contains(testPoint) {
                        out[x, y] = image[testPoint.x, testPoint.y]
                    }
                }
            }
            results.append(out)
        }
        return results
    }

    func run() {
        print(filenames)
        let images = filenames.flatMap { segment(filename: $0) }
        images.enumerated().forEach { (index, image) in
            try! image.write(toFile: "out-\(index + 1).png", atomically: false, format: .png)
        }
    }
}

Segment.main()
