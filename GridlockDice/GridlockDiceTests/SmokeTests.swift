import XCTest
@testable import GridlockDice

final class SmokeTests: XCTestCase {

    func testAppBuildInfoMinimumSupportedOS() {
        XCTAssertEqual(AppBuildInfo.minimumSupportedOS, "iOS 17")
    }
}
