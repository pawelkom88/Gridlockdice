import XCTest
@testable import GridlockDice

final class LevelSelectBehaviourTests: XCTestCase {

    func testLevelSelectShowsFiftyLevels() {
        let sections: [(label: String, sub: String, range: ClosedRange<Int>)] = [
            ("Tutorial",    "Free · No rotation",   1...5),
            ("Beginner",    "Free · No rotation",   6...15),
            ("Rotation",    "Unlock required",      16...30),
            ("Advanced",    "Unlock required",      31...50),
        ]

        var allIDs = Set<Int>()
        for sec in sections {
            for id in sec.range {
                allIDs.insert(id)
            }
        }
        XCTAssertEqual(allIDs.count, 50)
        XCTAssertEqual(allIDs.min(), 1)
        XCTAssertEqual(allIDs.max(), 50)
        for i in 1...50 {
            XCTAssertTrue(allIDs.contains(i), "Missing level \(i)")
        }
    }

    func testLevelSelectTutorialSectionIsFree() {
        let range = 1...5
        for id in range {
            let def = LevelCatalogue.all.first(where: { $0.id == id })
            XCTAssertNotNil(def)
            XCTAssertTrue(def?.isFree ?? false, "Tutorial level \(id) should be free")
        }
    }

    func testLevelSelectBeginnerSectionIsFree() {
        let range = 6...15
        for id in range {
            let def = LevelCatalogue.all.first(where: { $0.id == id })
            XCTAssertNotNil(def)
            XCTAssertTrue(def?.isFree ?? false, "Beginner level \(id) should be free")
        }
    }

    func testLevelSelectRotationAndAdvancedSectionsArePaid() {
        let paidRanges = [16...30, 31...50]
        for range in paidRanges {
            for id in range {
                let def = LevelCatalogue.all.first(where: { $0.id == id })
                XCTAssertNotNil(def)
                XCTAssertFalse(def?.isFree ?? true, "Level \(id) should be paid")
            }
        }
    }

    func testLevelSelectFreePaidBoundaryAtSixteen() {
        let free = LevelCatalogue.all.filter { $0.isFree }
        let paid = LevelCatalogue.all.filter { !$0.isFree }
        XCTAssertEqual(free.count, 15)
        XCTAssertEqual(paid.count, 35)
    }
}
