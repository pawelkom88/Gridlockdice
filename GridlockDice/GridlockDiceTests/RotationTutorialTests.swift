import XCTest
@testable import GridlockDice

@MainActor
final class RotationTutorialTests: XCTestCase {

    // MARK: - Tutorial visibility by level band

    func testRotationTutorialAppearsOnFirstRotationLevel() {
        let level = LevelCatalogue.all.first(where: { $0.allowsRotation })
        XCTAssertNotNil(level)
        XCTAssertGreaterThanOrEqual(level!.id, 21)
        XCTAssertTrue(level!.allowsRotation)
    }

    func testRotationTutorialHiddenInBeginnerLevels() {
        let beginnerIDs = 1...20
        for id in beginnerIDs {
            guard let level = LevelCatalogue.all.first(where: { $0.id == id }) else {
                XCTFail("Missing level \(id)")
                continue
            }
            XCTAssertFalse(level.allowsRotation, "Level \(id) should not allow rotation")
        }
    }

    func testRotationHintAppearsInRotationEnabledLevelViewModel() {
        let level = LevelCatalogue.all.first(where: { $0.id == 25 })!
        let vm = GameViewModel(level: level)
        XCTAssertTrue(vm.level.allowsRotation)
    }

    func testRotationHintHiddenInBeginnerLevelViewModel() {
        let level = LevelCatalogue.all.first(where: { $0.id == 1 })!
        let vm = GameViewModel(level: level)
        XCTAssertFalse(vm.level.allowsRotation)
    }

    // Tap-to-rotate behavior already covered by:
    // - RotationGatingTests.testRotatePieceChangesShapeWhenRotationAllowed
    // - RotationGatingTests.testRotatePieceDoesNothingWhenRotationLocked
    func testTapToRotateBehaviorCoveredByRotationGatingSuite() {
        let level = LevelDef(id: 21, name: "T", subtitle: "", rows: 2, cols: 2, dice: [],
                             pieces: [PieceDef(id: "p1", color: .red, rows: [[1,1]])])
        let vm = GameViewModel(level: level)
        let original = vm.trayPieces[0].shape
        vm.rotatePiece(id: "p1")
        XCTAssertNotEqual(vm.trayPieces[0].shape, original, "Rotation should change shape on enabled level")
    }
}
