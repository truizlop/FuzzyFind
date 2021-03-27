import Foundation

public enum FuzzyResultSegment {
    case gap([Character])
    case match([Character])

    func reversed() -> FuzzyResultSegment {
        switch self {
        case let .gap(array): return .gap(array.reversed())
        case let .match(array): return .match(array.reversed())
        }
    }

    var isEmpty: Bool {
        switch self {
        case .gap(let array), .match(let array): return array.isEmpty
        }
    }

    var asString: String {
        switch self {
        case .gap(let array), .match(let array): return String(array)
        }
    }

    var asGaps: String {
        switch self {
        case .gap(let array): return String(repeating: " ", count: array.count)
        case .match(let array): return String(repeating: "*", count: array.count)
        }
    }
}

extension FuzzyResultSegment: Equatable {}
