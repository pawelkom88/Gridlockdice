import XCTest

final class ScopeGuardTests: XCTestCase {

    private var sourceFiles: [String] = []

    override func setUp() {
        let root = "/Users/paw/WebstormProjects/BLOCK-GAME/GridlockDice/GridlockDice"
        let enumerator = FileManager.default.enumerator(atPath: root)
        sourceFiles = []
        while let path = enumerator?.nextObject() as? String {
            if path.hasSuffix(".swift") {
                sourceFiles.append(root + "/" + path)
            }
        }
    }

    private func readAllSources() -> String {
        sourceFiles.compactMap { try? String(contentsOfFile: $0) }.joined(separator: "\n")
    }

    private func assertNotContained(_ pattern: String, message: String, file: StaticString = #file, line: UInt = #line) {
        let content = readAllSources()
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) {
            let loc = match.range.location
            let snippet = (content as NSString).substring(with: match.range)
            XCTFail("\(message). Found: \"\(snippet)\" at offset \(loc)", file: file, line: line)
        }
    }

    // MARK: - No subscriptions

    func testNoSubscriptionProductIdentifiers() {
        assertNotContained(
            "product(identifier|id).*.subscription|subscription.*product|auto.?renew",
            message: "Subscription product IDs should not exist"
        )
    }

    // MARK: - No ads

    func testNoAdFrameworkImports() {
        assertNotContained(
            "import\\s+(GoogleMobileAds|AdSupport|AdServices|iAd|AppLovin|UnityAds)",
            message: "Ad framework imports should not exist"
        )
    }

    // MARK: - No accounts / login

    func testNoAccountLoginUIRefs() {
        let patterns = [
            "sign.?in|sign.?up|log.?in|log.?out",
            "auth.*token|token.*auth|oauth",
            "account.*settings|profile.*settings",
            "email.*password|password.*email",
            "create.*account|register.*account",
            "authentication.*required",
        ]
        for p in patterns {
            assertNotContained(p, message: "Account/login strings should not exist")
        }
    }

    // MARK: - No leaderboards / daily challenge / hints

    func testNoLeaderboardOrDailyChallengeRefs() {
        assertNotContained(
            "leaderboard|daily.?challenge|challenge.*day|weekly.?challenge",
            message: "Leaderboard or daily challenge references should not exist"
        )
    }

    func testNoPaidHints() {
        assertNotContained(
            "purchaseHint|hint.*price|paid.*hint|unlock.*hint",
            message: "Paid hint system should not exist"
        )
    }

    // MARK: - No social sharing

    func testNoSocialSharingRefs() {
        assertNotContained(
            "share.*score|share.*level|share.*progress|UIActivity|social.*share",
            message: "Social sharing references should not exist"
        )
    }

    // MARK: - No hardcoded final price

    func testPaywallDoesNotHardcodeFinalPrice() {
        let paywall = sourceFiles.first(where: { $0.hasSuffix("PaywallView.swift") })
        guard let path = paywall, let content = try? String(contentsOfFile: path) else {
            XCTFail("Could not read PaywallView.swift")
            return
        }
        let pricePatterns = [
            "\\$\\d+\\.\\d{2}",  // $4.99
            "€\\d+,\\d{2}",      // €4,99
            "£\\d+\\.\\d{2}",    // £3.99
        ]
        for pattern in pricePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) != nil {
                XCTFail("PaywallView contains hardcoded price matching \(pattern)")
            }
        }
    }

    // MARK: - No hardcoded final app name

    func testAppNameRemainsConfigurable() {
        let forbiddenNames = ["Gridlock Dice", "Block Puzzle Game", "Polyomino Puzzle"]
        let content = readAllSources()
        for name in forbiddenNames {
            let pattern = "\"" + NSRegularExpression.escapedPattern(for: name) + "\""
            if let regex = try? NSRegularExpression(pattern: pattern),
               regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) != nil {
                XCTFail("App contains hardcoded name: \(name)")
            }
        }
    }

    // MARK: - No backend references

    func testNoBackendReferences() {
        assertNotContained(
            "https?://|api\\.|backend|baseURL|network.*client|RESTClient|GraphQL|websocket",
            message: "Backend/networking references should not exist"
        )
    }

    // MARK: - Only one unlock product

    func testOnlyOneStoreProductDefined() {
        let content = readAllSources()
        let pattern = "\"gridlockdice.lifetime.unlock\""
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
        XCTAssertTrue(matches.count >= 1, "Product ID gridlockdice.lifetime.unlock should be defined")
        XCTAssertTrue(matches.count <= 2, "Should not define extra product IDs beyond gridlockdice.lifetime.unlock")
    }

    // MARK: - No third-party dependencies

    func testNoThirdPartyImports() {
        let allowed = Set(["SwiftUI", "Foundation", "StoreKit", "SpriteKit", "CoreGraphics", "XCTest", "UIKit"])
        for path in sourceFiles {
            guard let content = try? String(contentsOfFile: path) else { continue }
            let lines = content.components(separatedBy: "\n")
            for (idx, line) in lines.enumerated() {
                if line.hasPrefix("import ") {
                    let module = line.replacingOccurrences(of: "import ", with: "").trimmingCharacters(in: .whitespaces)
                    if module.hasPrefix("XCTest") { continue }
                    if module == "GridlockDice" { continue }
                    XCTAssertTrue(allowed.contains(module),
                        "Unexpected import \(module) in \(path):\(idx+1)")
                }
            }
        }
    }
}
