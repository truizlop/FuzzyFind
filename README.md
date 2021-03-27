# FuzzyFind

A Swift package with utilities to perform fuzzy search, using a modified version of the Smith-Waterman algorithm. This implementation is a port from the [Haskell version](https://github.com/runarorama/fuzzyfind) implemented by Rúnar Bjarnason.

## Usage

This package includes two core functions: `bestMatch` and `fuzzyFind`.

With `bestMatch`, you can find the best alignment of your query into a single string, if any alignment is possible:

```swift
import FuzzyFind 

let alignment = bestMatch(query: "ff", input: "FuzzyFind") // Matches
let noAlignment = bestMatch(query: "ww", input: FuzzyFind") // Not possible to find a match, returns nil
```

With `fuzzyFind`, you can run multiple queries over multiple inputs, and get all alignments for inputs that match all provided queries. Alignments will be provided in an array and sorted by their score; a higher score means a better alignment.

```swift
import FuzzyFind

let allAlignments = fuzzyFind(queries: ["dad", "mac", "dam"], inputs: ["red macadamia", "Madam Card"])
```
