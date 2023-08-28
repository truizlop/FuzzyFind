import Foundation

public struct FuzzyResult {
    public let segments: [FuzzyResultSegment]

    public var asString: String {
        return segments.map(\.asString).joined()
    }

    static func match(_ a: Character) -> FuzzyResult {
        return FuzzyResult(segments: [.match([a])])
    }

    static func gap(_ a: Character) -> FuzzyResult {
        return FuzzyResult(segments: [.gap([a])])
    }

    static func gaps(_ str: String) -> FuzzyResult {
        return FuzzyResult(segments: str.reversed().map { char in
            FuzzyResultSegment.gap([char])
        })
    }

    static let empty: FuzzyResult = FuzzyResult(segments: [])

    func reversed() -> FuzzyResult {
        return FuzzyResult(segments: self.segments.map { segment in
            segment.reversed()
        }.reversed())
    }

    func combine(_ other: FuzzyResult) -> FuzzyResult {
        if let last = self.segments.last, let first = other.segments.first {
            if last.isEmpty {
                return FuzzyResult(segments: self.segments.lead).combine(other)
            } else if first.isEmpty {
                return self.combine(FuzzyResult(segments: other.segments.tail))
            } else if case let .gap(l) = last, case let .gap(h) = first {
                return FuzzyResult(segments: self.segments.lead + [.gap(l + h)] + other.segments.tail)
            } else if case let .match(l) = last, case let .match(h) = first {
                return FuzzyResult(segments: self.segments.lead + [.match(l + h)] + other.segments.tail)
            } else {
                return FuzzyResult(segments: self.segments + other.segments)
            }
        } else {
            return self.isEmpty ? other : self
        }
    }

    func merge(_ other: FuzzyResult) -> FuzzyResult {
        if self.isEmpty { return other }
        if other.isEmpty { return self }
        let xs = self.segments[0]
        let ys = other.segments[0]
        switch (xs, ys) {
        case let (.gap(g1), .gap(g2)):
            if g1.count <= g2.count {
                return FuzzyResult(segments: [.gap(g1)]).combine(
                    self.tail.merge(other.drop(g1.count))
                )
            } else {
                return FuzzyResult(segments: [.gap(g2)]).combine(
                    self.drop(g2.count).merge(other.tail)
                )
            }
        case let (.match(m1), .match(m2)):
            if m1.count >= m2.count {
                return FuzzyResult(segments: [.match(m1)]).combine(
                    self.tail.merge(other.drop(m1.count))
                )
            } else {
                return FuzzyResult(segments: [.match(m2)]).combine(
                    self.drop(m2.count).merge(other.tail)
                )
            }
        case let (.gap(_), .match(m)):
            return FuzzyResult(segments: [.match(m)]).combine(
                self.drop(m.count).merge(other.tail)
            )
        case let (.match(m), .gap(_)):
            return FuzzyResult(segments: [.match(m)]).combine(
                self.tail.merge(other.drop(m.count))
            )
        }
    }

    private func drop(_ n: Int) -> FuzzyResult {
        guard n >= 1 else { return self }
        if let first = self.segments.first {
            switch first {
            case .gap(let array):
                if n >= array.count {
                    return self.tail.drop(n - array.count)
                } else {
                    return FuzzyResult(segments: [.gap(array.drop(n))]).combine(self.tail)
                }
            case .match(let array):
                if n >= array.count {
                    return self.tail.drop(n - array.count)
                } else {
                    return FuzzyResult(segments: [.match(array.drop(n))]).combine(self.tail)
                }
            }
        } else {
            return .empty
        }
    }

    private var isEmpty: Bool {
        return segments.isEmpty
    }

    private var tail: FuzzyResult {
        return FuzzyResult(segments: self.segments.tail)
    }

    private var lead: FuzzyResult {
        return FuzzyResult(segments: self.segments.lead)
    }
}

extension FuzzyResult: Equatable {}

private extension Array {
    func drop(_ n: Int) -> Array {
        return Array(self.dropFirst(n))
    }

    var tail: Array {
        if isEmpty { return [] }
        return Array(self.dropFirst())
    }

    var lead: Array {
        if isEmpty { return [] }
        return Array(self.dropLast())
    }
}

extension FuzzyResult {
    /// Compute the ranges highlighed in a Swift string.
    public func highlightedRanges(for string: String) -> [Range<String.Index>] {
        var index = string.startIndex
        var ranges = [Range<String.Index>]()

        for segment in segments {
            switch segment {
            case .gap(let array):
                index = string.index(index, offsetBy: array.count)
            case .match(let array):
                let start = index
                let end = string.index(start, offsetBy: array.count)

                ranges.append(start..<end)
            }
        }

        return ranges
    }
}
