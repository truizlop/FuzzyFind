import XCTest
@testable import FuzzyFind

final class FuzzyFindTests: XCTestCase {
    func testMatch() {
        let actual = bestMatch(query: "ff", input: "FuzzyFind")
        let expected = Alignment(
            score: 55,
            result: FuzzyResult(segments: [
                .match(["F"]),
                .gap(["u", "z", "z", "y"]),
                .match(["F"]),
                .gap(["i"]),
                .gap(["n"]),
                .gap(["d"])
            ])
        )
        XCTAssertEqual(actual, expected)
    }

    func testContiguousCharactersHaveHigherScore() {
        let a1 = bestMatch(query: "pp", input: "pickled pepper")!
        let a2 = bestMatch(query: "pp", input: "Pied Piper")!
        XCTAssertTrue(a1.score > a2.score)
    }

    func testCharactersAtBeginningOfWordsHaveHigherScore() {
        let a1 = bestMatch(query: "pp", input: "Pied Piper")!
        let a2 = bestMatch(query: "pp", input: "porcupine")!
        XCTAssertTrue(a1.score > a2.score)
    }

    func testCamelCaseHumpsHaveHigherScore() {
        let a1 = bestMatch(query: "bm", input: "BatMan")!
        let a2 = bestMatch(query: "bm", input: "Batman")!
        XCTAssertTrue(a1.score > a2.score)
    }

    func testFirstLettersOfWordsHaveHigherScore() {
        let a1 = bestMatch(query: "bm", input: "Bat man")!
        let a2 = bestMatch(query: "bm", input: "Batman")!
        XCTAssertTrue(a1.score > a2.score)
    }
}
