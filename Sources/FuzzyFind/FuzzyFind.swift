import Foundation

/// Finds input strings that match all the given input patterns. For each input that matches, it returns one `Alignment`. The output is sorted by ascending `score`.
///
/// - Parameters:
///   - queries: An array of patterns to match.
///   - inputs: An array of strings to search into.
///   - match: Score for a match.
///   - mismatch: Score for a mismatch.
///   - gapPenalty: Function to provide a penalty for a gap.
///   - boundaryBonus: Bonus for a match in a boundary.
///   - camelCaseBonus: Bonus for a match in camel case.
///   - firstCharBonusMultiplier: Multiplier for a match in the first character of the input.
///   - consecutiveBonus: Bonus for consecutive matches.
/// - Returns: An array of all alignments found for the input words, sorted by their score.
public func fuzzyFind(
    queries: [String],
    inputs: [String],
    match: Score = .defaultMatch,
    mismatch: Score = .defaultMismatch,
    gapPenalty: (Int) -> Score = Score.defaultGapPenalty,
    boundaryBonus: Score = .defaultBoundary,
    camelCaseBonus: Score = .defaultCamelCase,
    firstCharBonusMultiplier: Int = Score.defaultFirstCharBonusMultiplier,
    consecutiveBonus: Score = Score.defaultConsecutiveBonus
) -> [Alignment] {
    inputs.compactMap { input in
        queries.reduce(.some(Alignment.empty)) { partial, next in
            partial.flatMap { alignment in
                bestMatch(
                    query: next,
                    input: input,
                    match: match,
                    mismatch: mismatch,
                    gapPenalty: gapPenalty,
                    boundaryBonus: boundaryBonus,
                    camelCaseBonus: camelCaseBonus,
                    firstCharBonusMultiplier: firstCharBonusMultiplier,
                    consecutiveBonus: consecutiveBonus).map { match in
                    alignment.combine(match)
                }
            }
        }
    }.sorted { a1, a2 in a1.score > a2.score }
}

/// Finds the best Alignment, if any, for the query in the input word.
///
/// If an alignment can be found, it returns the best way, according to the provided scores, to line up the characters in the query with the ones in the input.
///
/// The score indicates how good the match is. Better matches have higher scores.
///
/// A substring from the query will generate a match, and any characters from the input the don't result in a match will generate a gap. Concatenating all match and gap results should yield the original input string.
///
/// All matched characters in the input always occur in the same order as the do in the query pattern.
///
/// The algorithm prefers (and will generate higher scorers for) the following kind of matches:
///
/// 1. Contiguous characters from the query string.
/// 2. Characters at the beginnings of words.
/// 3. Characters at CamelCase humps.
/// 4. First character of the query pattern at the beginning of a word or CamelHump.
/// 5. All else being equal, matchs that occur later in the input string are preferred.
///
/// - Parameters:
///   - query: Query pattern.
///   - input: Input string to match the query.
///   - match: Score for a match.
///   - mismatch: Score for a mismatch.
///   - gapPenalty: Function to provide a penalty for a gap.
///   - boundaryBonus: Bonus for a match in a boundary.
///   - camelCaseBonus: Bonus for a match in camel case.
///   - firstCharBonusMultiplier: Multiplier for a match in the first character of the input.
///   - consecutiveBonus: Bonus for consecutive matches.
/// - Returns: An `Alignment` of the query and the input, if it is possible.
public func bestMatch(
    query: String,
    input: String,
    match: Score = .defaultMatch,
    mismatch: Score = .defaultMismatch,
    gapPenalty: (Int) -> Score = Score.defaultGapPenalty,
    boundaryBonus: Score = .defaultBoundary,
    camelCaseBonus: Score = .defaultCamelCase,
    firstCharBonusMultiplier: Int = Score.defaultFirstCharBonusMultiplier,
    consecutiveBonus: Score = Score.defaultConsecutiveBonus
) -> Alignment? {
    let a = query.map { $0 }
    let b = input.map { $0 }
    let m = query.count
    let n = input.count
    let bonuses = (0 ... m).map { i in
        (0 ... n).map { j in bonus(i,j) }
    }
    var hs: [Pair<Int, Int>: Score] = [:]

    func find(_ array: [Character], at position: Int) -> Character {
        return array[position - 1]
    }

    func similarity(_ a: Character, _ b: Character) -> Score {
        return (a.lowercased() == b.lowercased()) ? match : mismatch
    }

    func bonus(_ i: Int, _ j: Int) -> Score {
        if i == 0 || j == 0 {
            return 0
        } else {
            let similarityScore = similarity(find(a, at: i), find(b, at: j))
            if similarityScore > 0 {
                let boundary = (j < 2 || (find(b, at: j).isAlphaNum) && !(find(b, at: j - 1).isAlphaNum)) ? boundaryBonus : 0
                let camel = (j > 1 && find(b, at: j - 1).isLowercase && find(b, at: j).isUppercase) ? camelCaseBonus : 0
                let multiplier = (i == 1) ? firstCharBonusMultiplier : 1
                let similar = i > 0 && j > 0 && similarityScore > 0
                let afterMatch = i > 1 && j > 1 && similarity(find(a, at: i - 1), find(b, at: j - 1)) > 0
                let beforeMatch = i < m && j < n && similarity(find(a, at: i + 1), find(b, at: j + 1)) > 0
                let consecutive = (similar && (afterMatch || beforeMatch)) ? consecutiveBonus : 0
                return multiplier * (boundary + camel + consecutive)
            } else {
                return 0
            }
        }
    }

    func h(_ i: Int, _ j: Int) -> Score {
        if let score = hs[Pair(i, j)] { return score }
        if i == 0 || j == 0 {
            hs[Pair(i, j)] = 0
            return 0
        }
        let scoreMatch = h(i - 1, j - 1) + similarity(find(a, at: i), find(b, at: j)) + bonuses[i][j]
        let scoreGap = (1 ... j).map { l in
            h(i, j - l) - gapPenalty(l)
        }.max()!
        let score = [scoreMatch, scoreGap, Score(integerLiteral: 0)].max()!
        hs[Pair(i, j)] = score
        return score
    }

    func localMax(_ m: Int, _ n: Int) -> Int {
        return (1 ... n).max { b, d in
            totalScore(m, b) < totalScore(m, d)
        }!
    }

    func totalScore(_ i: Int, _ j: Int) -> Score {
        return (i > m) ? 0 : (h(i, j) + bonuses[i][j])
    }

    func go(_ x: Int, _ y: Int) -> FuzzyResult? {
        var i = x
        var j = y
        var result = FuzzyResult.empty
        while true {
            if i == 0 {
                return result.combine(.gaps(String(input.prefix(j))))
            } else if j == 0 {
                return nil
            } else {
                if similarity(find(a, at: i), find(b, at: j)) > 0 {
                    result = result.combine(.match(find(b, at: j)))
                    i -= 1
                    j -= 1
                } else {
                    result = result.combine(.gap(find(b, at: j)))
                    j -= 1
                }
            }
        }
    }

    let nx = localMax(m, n)
    let traceback = go(m, nx).flatMap { result in
        FuzzyResult.gaps(String(input.dropFirst(nx))).combine(result)
    }

    return traceback.flatMap { result in
        Alignment(score: totalScore(m, nx), result: result.reversed())
    }
}

private extension Character {
    var isAlphaNum: Bool {
        isLetter || isNumber
    }
}

private struct Pair<A: Hashable, B: Hashable>: Hashable {
    let a: A
    let b: B

    init(_ a: A, _ b: B) {
        self.a = a
        self.b = b
    }
}
