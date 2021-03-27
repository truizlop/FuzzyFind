import Foundation

public struct Alignment {
    public let score: Score
    public let result: FuzzyResult

    static var empty: Alignment {
        return Alignment(score: 0, result: .empty)
    }

    func combine(_ other: Alignment) -> Alignment {
        return Alignment(
            score: self.score + other.score,
            result: self.result.merge(other.result)
        )
    }

    public func highlight() -> String {
        return """
        \(result.segments.map(\.asString).joined())
        \(result.segments.map(\.asGaps).joined())
        """
    }

    public var asString: String {
        return result.asString
    }
}

extension Alignment: Equatable {}
