//
//  main.swift
//  image-segmenter
//
//  Created by Jerry Hsu on 1/4/21.
//

import Foundation
import ArgumentParser
import SwiftImage

struct Point: Hashable, Equatable {
    var x, y: Int
    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
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

        var segments = Set<Set<Point>>()

        for y in 0..<image.height {
            for x in 0..<image.width {
                if image[x, y].gray == 255 {
                    continue
                }
                let point = Point(x, y)
                let candidates = [
                    point.offset(-1, -1),
                    point.offset(-1, 0),
                    point.offset(0, -1),
                    point.offset(1, -1)
                ]
                var matchingSets = Array<Set<Point>>()
                for segment in segments {
                    if !segment.intersection(candidates).isEmpty {
                        matchingSets.append(segment)
                    }
                }
                if matchingSets.count > 1 {
                    segments.subtract(matchingSets)
                    var union = matchingSets.reduce(into: Set<Point>()) { (union, nextSet) in
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
            var minPoint = point
            var maxPoint = point
            for point in segment {
                minPoint.x = min(minPoint.x, point.x)
                minPoint.y = min(minPoint.y, point.y)
                maxPoint.x = max(maxPoint.x, point.x)
                maxPoint.y = max(maxPoint.y, point.y)
            }
            let floodMin = minPoint.offset(-1, -1)
            let floodMax = maxPoint.offset(1, 1)
            var outside: Set<Point> = [floodMin]
            var seen = outside
            var active = outside
            while let current = active.popFirst() {
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
            let outWidth = maxPoint.x - minPoint.x + 1
            let outHeight = maxPoint.y - minPoint.y + 1
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
            try! image.write(toFile: "out-\(index).png", atomically: false, format: .png)
        }
    }
}

Segment.main()
