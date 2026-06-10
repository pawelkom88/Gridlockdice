# TDD Breakdown Plan

## Product Goal

Build a brand-new native **iOS/iPadOS 17+ Xcode project** for a tactile block puzzle game. The player opens ordered levels, sees fixed coordinate dice on a grid, drags colourful pieces from a tray, fills every non-fixed cell, and unlocks levels 16–50 through a one-time StoreKit purchase using product ID `full_game_unlock`.

The app must use SwiftUI for the shell, SpriteKit for gameplay, include 50 ordered levels, keep the first 15 levels free, and avoid ads, subscriptions, accounts, backend, leaderboards, daily challenges, social sharing, hints, hardcoded final app name, and hardcoded final price.

## Behaviour Inventory

### App shell and navigation

- App launches into level select.
- User can start available levels.
- User can return from game to level select.
- Solving a level shows completion.
- Next level starts from completion.
- Locked levels route to paywall.

### Level progression

- Exactly 50 ordered levels.
- Levels 1–15 are free.
- Levels 16–50 are locked until purchase.
- Level bands follow the defined difficulty progression.
- Multiple valid solves are allowed.
- Every shipped level must be solvable.

### Gameplay rules

- Board supports 4×4, 5×5, and 6×6.
- Fixed dice display coordinate labels and cannot be moved.
- Pieces are connected polyomino blocks.
- Valid placements snap into the board.
- Invalid placements are rejected.
- Placed pieces can be removed.
- Level completes only when every non-fixed cell is filled.

### Rotation

- Beginner/tutorial levels do not allow rotation.
- Later levels allow rotation.
- Rotation is introduced gently around levels 16–20.
- Suggested copy: “Tap a piece to rotate it. Some shapes only fit after turning.”

### Purchase flow

- Paywall uses StoreKit 2.
- Product ID is exactly `full_game_unlock`.
- StoreKit localized price is used when available.
- Generic unlock copy is shown if product unavailable.
- Restore purchases is available.
- Purchase state persists locally.

### Design and UI

- Dark board surface.
- Row letters and column numbers visible.
- White/cream fixed coordinate dice.
- Bright chunky pieces.
- Rounded corners, soft shadows, premium digital toy feel.
- Use the provided reference pack as visual/source-of-truth.
- No Figma links exist.

### SpriteKit responsibilities

- Board rendering.
- Dice rendering.
- Piece rendering.
- Drag handling.
- Snapping.
- Placement feedback.
- Removal of placed pieces.
- Rotation animation.
- Completion animation.

## Key Assumptions

- Codex will run inside a fresh repo and can create an Xcode project.
- The project will use XCTest for model/view-model tests.
- SwiftUI view tests may be limited unless the repo has a UI testing helper. Prefer model/view-model tests for core behaviour and XCUITest for the critical happy path.
- StoreKit will use a `.storekit` configuration file for local testability.
- SpriteKit internals should be tested through public game-state outcomes, not node hierarchy details.
- UI visual polish is verified mainly through manual QA and accessibility-visible state, not brittle snapshot tests.
- Reference file names and structure can guide implementation, but tests should not depend on exact file splitting.

## Risks and Dependencies

- **Xcode project creation first:** nothing else can compile until the project and test targets exist.
- **SpriteKit UI testing risk:** drag gestures and node interactions can be harder to test than pure SwiftUI. Keep core placement logic in testable models/view models.
- **Level catalogue risk:** 50 levels is large. Add catalogue validation tests before manually filling all level data.
- **StoreKit risk:** product metadata may not exist in development. Use StoreKit configuration and fallback UI.
- **Progress persistence risk:** completed levels and purchase unlock must survive relaunch.
- **Scope creep risk:** no hints, accounts, leaderboards, ads, subscriptions, daily challenge, social sharing, skins, backend, or final price/name should be added.
- **Architecture risk:** the reference suggests `@Observable`, `@Environment`, value-type `BoardState`, pure shape rotation, and no third-party dependencies. Keep behaviour tests stable while still respecting those constraints.

## Recommended Test Strategy

### Unit tests

Use XCTest for:

- shape rotation
- board placement validation
- dice blockers
- win condition
- level catalogue validation
- free/paid lock rules
- purchase state persistence wrapper
- app navigation state
- solver/validator behaviour

### Integration tests

Use XCTest against app/view models for:

- start level → place pieces → solved callback
- locked level → paywall route
- purchase restored → locked levels become available
- completed level persists

### UI tests

Use XCUITest sparingly for:

- app launches to level select
- Level 1 can be opened
- locked level opens paywall
- paywall shows unlock/restore actions
- completion appears after a test-friendly solvable level

### SpriteKit tests

Do not assert exact node tree or private node types. Test:

- scene creates visible board/dice/piece labels through accessibility identifiers where practical
- dragging a piece results in model placement
- invalid drop leaves board unchanged

### What not to test

- private methods
- exact internal component hierarchy
- exact animation timing
- raw CSS/SwiftUI implementation details
- exact shadow/radius values outside theme token tests
- screenshots as primary verification

## TDD Slices

### Slice 1 — Create a Compilable iOS/iPadOS 17+ Xcode Project

#### Behaviour

The repo contains a new iOS/iPadOS Swift project that builds and runs a minimal app. A test target exists and can run one passing smoke test.

#### Why this slice exists

Everything depends on a working Xcode project and test target. This slice creates the safe foundation before product code.

#### Red

Write a smoke test that imports the app module and verifies a trivial public app constant exists, for example `AppBuildInfo.minimumSupportedOS == "iOS 17"`.

#### Green

Create the Xcode project, app target, test target, and minimal SwiftUI app entry point. Add the simplest public build info type needed for the test.

#### Refactor

Organize initial folders: `App`, `Theme`, `Models`, `ViewModels`, `Views`, `SpriteKit`, `Store`, `Tests`.

#### Acceptance Criteria

- Project opens in Xcode.
- App target builds.
- Test target runs.
- Minimum deployment target is iOS/iPadOS 17+.
- No third-party dependencies.

#### Suggested `/goal` Prompt

```text
/goal Create a brand-new iOS/iPadOS 17+ SwiftUI Xcode project with an app target and XCTest target. Follow TDD: first add a failing smoke test that imports the app module and checks a public build-info value, then implement the minimal app entry point and build-info type to pass. Do not add gameplay yet.
```

---

### Slice 2 — Add Theme Tokens from the Reference Pack

#### Behaviour

The app exposes centralized theme tokens for colours, spacing, typography, radii, and piece colours. Views can use these tokens without hardcoded styling values.

#### Why this slice exists

The master prompt requires a theme layer based on `AppTheme.swift` and says styling should not be scattered through views.

#### Red

Write tests that verify:

- hex colours can initialize without crashing.
- all expected piece colour names exist.
- each piece colour exposes fill, shadow, and border values.
- spacing/radius token values are positive.

Suggested tests:

- `testPieceColorPaletteContainsAllGameplayColours`
- `testThemeSpacingAndRadiusTokensAreUsable`
- `testHexColorInitializerAcceptsReferenceHexValues`

#### Green

Implement `AppTheme.swift` based on the reference theme.

#### Refactor

Move theme code into `Theme/AppTheme.swift`. Keep names close to the reference.

#### Acceptance Criteria

- Tests pass.
- Theme tokens compile.
- No external fonts/assets are introduced.
- No app screen contains product UI yet.

#### Suggested `/goal` Prompt

```text
/goal Add the centralized AppTheme layer using the reference pack tokens. Start with tests for palette completeness and usable spacing/radius values, then implement the smallest theme code needed to pass. Do not build screens yet.
```

---

### Slice 3 — Model Shapes, Pieces, Dice, Levels, and Board State

#### Behaviour

The system can represent a board, fixed dice, piece shapes, tray pieces, cell states, and levels. The board prevents placements outside bounds, over fixed dice, or over occupied cells.

#### Why this slice exists

All gameplay, solver, SpriteKit, and view-model logic depends on correct domain models.

#### Red

Write tests for observable model behaviour:

- A board initialized with dice reports those cells as blocked.
- A piece can be placed into empty cells.
- A piece cannot be placed outside the board.
- A piece cannot overlap dice.
- A piece cannot overlap another piece.
- Removing a placed piece empties its cells but leaves dice intact.

Suggested tests:

- `testBoardStartsWithFixedDiceCells`
- `testCanPlacePieceInEmptyArea`
- `testCannotPlacePieceOutsideBoard`
- `testCannotPlacePieceOverDice`
- `testCannotPlacePieceOverFilledCells`
- `testRemovingPiecePreservesDice`

#### Green

Implement `Shape`, `PieceDef`, `TrayPiece`, `DiceMarker`, `LevelDef`, `CellState`, and `BoardState`.

#### Refactor

Keep `BoardState` as a value type. Add helper methods only when tests need behaviour.

#### Acceptance Criteria

- Board placement rules work.
- Dice are immutable blockers.
- Tests verify behaviour, not storage structure.

#### Suggested `/goal` Prompt

```text
/goal Implement the core puzzle models and BoardState. Start by writing failing XCTest cases for dice blockers, valid placement, invalid placement outside the board, overlap rejection, and piece removal. Then implement only the model behaviour required to pass.
```

---

### Slice 4 — Add Shape Rotation Behaviour

#### Behaviour

A piece shape can rotate 90° clockwise. Rotation does not mutate immutable piece definitions. Tray pieces can rotate their current shape.

#### Why this slice exists

Rotation is introduced later in progression and must be reliable before gameplay uses it.

#### Red

Write tests:

- Rotating a non-square L shape returns the expected new shape.
- Four rotations returns the original shape.
- Rotating a tray piece changes only the tray piece shape.
- A level/piece definition remains unchanged after tray rotation.

Suggested tests:

- `testShapeRotatesClockwise`
- `testFourRotationsReturnOriginalShape`
- `testTrayPieceRotationDoesNotMutatePieceDefinition`

#### Green

Implement `Shape.rotatedCW()` and `TrayPiece.rotateCW()`.

#### Refactor

Normalize shape helpers: `width`, `height`, occupied cell iteration.

#### Acceptance Criteria

- Rotation works for rectangular and square shapes.
- No level template mutation.
- Tests avoid private implementation details.

#### Suggested `/goal` Prompt

```text
/goal Add shape rotation behaviour. Write failing tests for clockwise rotation, four-rotation identity, and tray-piece mutation without mutating PieceDef. Then implement the smallest rotation helpers to pass.
```

---

### Slice 5 — Add a 50-Level Catalogue Contract

#### Behaviour

The app exposes exactly 50 ordered levels. Levels 1–15 are free. Levels 16–50 are paid. Level metadata follows the required progression bands.

#### Why this slice exists

The master prompt requires exactly 50 ordered levels, first 15 free, and defined level bands.

#### Red

Write catalogue validation tests:

- Catalogue has exactly 50 levels.
- Level IDs are 1...50 with no gaps.
- Levels 1–15 are free.
- Levels 16–50 are paid/locked before unlock.
- Board sizes are only 4×4, 5×5, or 6×6.
- Levels 1–15 have rotation disabled.
- Levels 16+ can include rotation according to the progression rules.
- Each dice label matches its row/column coordinate.

Suggested tests:

- `testCatalogueContainsExactlyFiftyOrderedLevels`
- `testFirstFifteenLevelsAreFree`
- `testPaidLevelsStartAtSixteen`
- `testDiceLabelsMatchCoordinates`
- `testBoardSizesAreWithinSupportedRange`

#### Green

Create `LevelCatalogue` and enough level data to satisfy the tests. Use simple generated/hand-authored levels at first, but ensure each has valid pieces and dice.

#### Refactor

Extract progression metadata helpers such as `isFree`, `allowsRotation`, `band`.

#### Acceptance Criteria

- Exactly 50 levels.
- No gaps or duplicate IDs.
- Free/paid boundary is correct.
- Dice labels are valid.

#### Suggested `/goal` Prompt

```text
/goal Add the 50-level catalogue contract. First write failing tests that enforce exactly 50 ordered levels, the free/paid boundary after level 15, supported board sizes, rotation flags, and dice-label correctness. Then implement LevelCatalogue and metadata helpers to pass.
```

---

### Slice 6 — Validate Level Solvability

#### Behaviour

Each shipped level can be validated as solvable. Multiple valid solutions are allowed. The validator rejects impossible levels.

#### Why this slice exists

Every level must have at least one valid solution, and uniqueness is not required.

#### Red

Write tests:

- A simple known-solvable level returns solvable.
- A known-impossible level returns not solvable.
- Catalogue validation confirms all shipped levels are solvable.
- Solver stops after finding at least one solution unless asked to count more.

Suggested tests:

- `testSolverReturnsTrueForKnownSolvableLevel`
- `testSolverReturnsFalseForKnownImpossibleLevel`
- `testAllCatalogueLevelsAreSolvable`
- `testMultipleSolutionsAreAllowed`

#### Green

Implement a backtracking `PuzzleSolver` over `BoardState` and remaining pieces. Keep it simple and deterministic.

#### Refactor

Add timeout/node-limit safety if needed, but keep tests deterministic.

#### Acceptance Criteria

- All 50 levels pass solvability validation.
- Impossible fixture fails.
- No requirement for unique solution.
- Solver tests do not depend on private recursion structure.

#### Suggested `/goal` Prompt

```text
/goal Implement level solvability validation. Start with tests for a known solvable level, a known impossible level, and all catalogue levels being solvable. Then add a simple backtracking PuzzleSolver that proves at least one solution exists. Multiple solutions are allowed.
```

---

### Slice 7 — Add App State, Progress, and Local Persistence

#### Behaviour

The app tracks current screen, completed levels, current game session, unlock state, and persists completed/unlocked state locally.

#### Why this slice exists

Navigation, progression, paywall, completion, and relaunch behaviour depend on app-level state.

#### Red

Write tests:

- New app state starts at level select.
- Starting an unlocked level creates a game session.
- Solving a level marks it completed.
- Completed levels persist across app state reload.
- Unlock state persists across app state reload.
- Starting a locked level before purchase routes to paywall.

Suggested tests:

- `testInitialScreenIsLevelSelect`
- `testStartAvailableLevelCreatesGameSession`
- `testSolvedLevelIsMarkedCompleted`
- `testCompletedLevelsPersist`
- `testUnlockStatePersists`
- `testLockedLevelRoutesToPaywallBeforePurchase`

#### Green

Implement `AppViewModel`, local persistence abstraction, and screen enum. Use `UserDefaults` behind a small protocol so tests can use in-memory storage.

#### Refactor

Separate persistence concerns from navigation logic.

#### Acceptance Criteria

- State is observable from tests.
- Persistence is testable without real app relaunch.
- Locked levels cannot be started before unlock.

#### Suggested `/goal` Prompt

```text
/goal Add AppViewModel state and local persistence. Write failing tests for initial screen, starting available levels, locked-level routing to paywall, completed-level persistence, and unlock persistence. Implement the smallest state/persistence layer to pass.
```

---

### Slice 8 — Add Game Session Behaviour

#### Behaviour

A game session starts from a level, exposes board/progress/tray state, places valid pieces, rejects invalid placements, removes placed pieces, and calls solved callback only when the board is complete.

#### Why this slice exists

This is the core gameplay loop, testable without SpriteKit.

#### Red

Write tests:

- New game session starts with dice on board and all pieces in tray.
- Valid placement removes piece from tray and fills cells.
- Invalid placement leaves tray and board unchanged.
- Removing a placed piece returns it to tray and empties cells.
- Progress updates after placement/removal.
- Solved callback fires only after all playable cells are filled.

Suggested tests:

- `testGameSessionStartsWithLevelBoardAndTrayPieces`
- `testValidPlacementMovesPieceFromTrayToBoard`
- `testInvalidPlacementDoesNotChangeBoardOrTray`
- `testRemovingPlacedPieceReturnsItToTray`
- `testProgressReflectsFilledPlayableCells`
- `testSolvedCallbackFiresWhenBoardComplete`

#### Green

Implement `GameViewModel` behaviour around `BoardState`.

#### Refactor

Extract pure placement result types if useful.

#### Acceptance Criteria

- Gameplay rules are covered without UI.
- Invalid placements do not corrupt state.
- Completion is based on filled non-dice cells.

#### Suggested `/goal` Prompt

```text
/goal Implement GameViewModel gameplay behaviour. Start with tests for session initialization, valid placement, invalid placement rejection, removing placed pieces, progress updates, and solved callback. Then implement only the game-session logic needed to pass.
```

---

### Slice 9 — Gate Rotation by Level

#### Behaviour

Rotation attempts do nothing on beginner/tutorial levels and work on later rotation-enabled levels. The UI can ask whether rotation is available.

#### Why this slice exists

The product teaches no rotation early, then unlocks rotation as difficulty increases.

#### Red

Write tests:

- Level 1 rotation is unavailable.
- Attempting to rotate a tray piece in Level 1 leaves shape unchanged.
- A rotation-enabled level allows tray piece rotation.
- Rotation state affects placement validation.

Suggested tests:

- `testBeginnerLevelDoesNotAllowRotation`
- `testRotatePieceDoesNothingWhenRotationLocked`
- `testRotatePieceChangesShapeWhenRotationAllowed`
- `testRotatedShapeCanBePlacedWhereOriginalCannot`

#### Green

Add `allowsRotation` to level metadata and enforce it in `GameViewModel.rotatePiece`.

#### Refactor

Keep rotation policy in level metadata, not scattered across views.

#### Acceptance Criteria

- Beginner levels cannot rotate.
- Later levels can rotate.
- Tests verify public behaviour.

#### Suggested `/goal` Prompt

```text
/goal Gate rotation by level. Write failing tests proving Level 1 cannot rotate pieces, rotation-enabled levels can, and rotated shapes affect legal placement. Then implement allowsRotation metadata and enforce it in GameViewModel.
```

---

### Slice 10 — Build SwiftUI Level Select Behaviour

#### Behaviour

The user sees level sections, can start free/unlocked levels, sees locked paid levels, and tapping locked content routes to paywall.

#### Why this slice exists

This is the first user-visible screen and the entry into gameplay.

#### Red

Write UI/view-model integration tests where possible:

- Level select exposes 50 levels.
- Free levels are accessible.
- Paid levels show locked state before unlock.
- Tapping Level 16 before unlock changes screen to paywall.
- After unlock, Level 16 starts a game.

Suggested tests:

- `testLevelSelectShowsFiftyLevels`
- `testFreeLevelTapStartsGame`
- `testPaidLevelTapRoutesToPaywallBeforeUnlock`
- `testPaidLevelTapStartsGameAfterUnlock`

#### Green

Implement `RootView` and `LevelSelectView` using existing app state. Add accessibility identifiers for key controls.

#### Refactor

Extract `LevelCell` only after tests pass.

#### Acceptance Criteria

- Level select is visible on launch.
- Levels 1–15 can start.
- Levels 16–50 are locked until unlock.
- No purchase price/name hardcoded.

#### Suggested `/goal` Prompt

```text
/goal Build the SwiftUI level select flow. Start with tests or UI tests for 50 visible levels, free-level start, locked paid-level routing to paywall, and unlocked paid-level start. Then implement RootView and LevelSelectView with accessibility identifiers.
```

---

### Slice 11 — Build StoreKit Purchase Manager and Paywall Behaviour

#### Behaviour

Paywall uses product ID `full_game_unlock`, shows StoreKit localized price when available, allows purchase/restore, and unlocks levels 16–50. If product metadata is unavailable, UI remains functional with generic copy.

#### Why this slice exists

The monetisation boundary is core to v1: 15 free levels + one-time unlock.

#### Red

Write tests with a fake purchase service:

- Purchase manager requests product ID `full_game_unlock`.
- Successful purchase sets unlocked state.
- Restore sets unlocked state when entitlement exists.
- Product unavailable does not crash and paywall uses generic copy.
- Price is not hardcoded.

Suggested tests:

- `testPurchaseManagerRequestsFullGameUnlockProduct`
- `testSuccessfulPurchaseUnlocksPaidLevels`
- `testRestoreUnlocksWhenEntitlementExists`
- `testUnavailableProductKeepsPaywallUsable`
- `testPaywallDoesNotHardcodeFinalPrice`

#### Green

Implement `PurchaseManager` with StoreKit 2 and inject a protocol/fake for tests. Add `PaywallView`.

#### Refactor

Keep StoreKit-specific code isolated from views and app navigation.

#### Acceptance Criteria

- Product ID exactly `full_game_unlock`.
- Purchase and restore unlock paid levels.
- Unlock persists.
- No hardcoded final price.
- No subscriptions/ads.

#### Suggested `/goal` Prompt

```text
/goal Implement StoreKit paywall behaviour. Write tests with a fake purchase service for product ID full_game_unlock, successful purchase, restore, unavailable product fallback, and no hardcoded price. Then implement PurchaseManager and PaywallView using StoreKit 2.
```

---

### Slice 12 — Build SpriteKit Scene Rendering from Game State

#### Behaviour

The SpriteKit game scene renders the current level board, coordinate dice, and tray pieces using the game state. It reflects board size and visible labels.

#### Why this slice exists

SpriteKit is required for the gameplay board, pieces, drag, snapping, and animations.

#### Red

Write tests that verify observable scene state, not exact internal hierarchy:

- Scene configured with Level 1 exposes expected board dimensions.
- Dice labels are visible/accessibility-exposed.
- Tray exposes the expected number of pieces.
- Cell size is calculated within available space.

Suggested tests:

- `testGameSceneRepresentsLevelBoardDimensions`
- `testGameSceneExposesFixedDiceLabels`
- `testGameSceneExposesTrayPieceCount`
- `testCellSizeFitsAvailableBoardArea`

#### Green

Implement `GameScene`, `BoardNode`, `DiceNode`, `PieceNode`, and bridge view. Add accessibility labels/identifiers where possible.

#### Refactor

Move node creation into reusable nodes only after behaviour passes.

#### Acceptance Criteria

- SpriteKit scene appears inside SwiftUI game screen.
- Board dimensions match level.
- Dice labels are visible.
- Tray pieces are visible.
- Uses procedural shapes, no external assets.

#### Suggested `/goal` Prompt

```text
/goal Build the SpriteKit rendering layer from existing GameViewModel state. Start with tests for board dimensions, fixed dice labels, tray piece count, and dynamic cell sizing. Then implement GameScene and reusable nodes without adding drag logic yet.
```

---

### Slice 13 — Add Drag, Drop, Snap, and Invalid Placement Feedback

#### Behaviour

The player can drag a tray piece onto the board. Valid drops place the piece and snap it into cells. Invalid drops are rejected and leave game state unchanged.

#### Why this slice exists

This is the central interaction promised in the master prompt and user flow.

#### Red

Write integration tests around public scene/game actions:

- Dragging/dropping a piece on valid cells places it.
- Dropping outside board rejects it.
- Dropping over dice rejects it.
- Dropping over occupied cells rejects it.
- Invalid placement exposes rejection feedback state.

Suggested tests:

- `testValidDropPlacesPieceOnBoard`
- `testDropOutsideBoardIsRejected`
- `testDropOverDiceIsRejected`
- `testDropOverFilledCellsIsRejected`
- `testInvalidDropSetsRejectionFeedback`

#### Green

Wire touch/drag handling in `GameScene` to `GameViewModel.tryPlace`.

#### Refactor

Separate coordinate conversion from drag lifecycle. Keep conversion testable through public helpers if needed.

#### Acceptance Criteria

- Valid drag/drop places pieces.
- Invalid drag/drop does not change board.
- Rejection feedback is visible.
- Tests do not assert exact node internals.

#### Suggested `/goal` Prompt

```text
/goal Add SpriteKit drag/drop placement. Write failing behaviour tests for valid drop, outside-board rejection, dice-overlap rejection, filled-cell rejection, and rejection feedback state. Then implement touch handling and snapping through GameViewModel.
```

---

### Slice 14 — Add Placed Piece Removal

#### Behaviour

The player can tap a placed piece/cell to remove that piece from the board and return it to the tray.

#### Why this slice exists

The master prompt requires placed pieces to be removable and returned to the tray.

#### Red

Write tests:

- Tapping a filled cell removes the whole piece.
- Removed piece returns to tray.
- Dice remain fixed.
- Progress decreases after removal.

Suggested tests:

- `testTapFilledCellRemovesWholePiece`
- `testRemovedPieceReturnsToTray`
- `testRemovingPieceDoesNotRemoveDice`
- `testProgressDecreasesAfterRemoval`

#### Green

Wire board cell tap handling to `GameViewModel.removePiece`.

#### Refactor

Avoid duplicating piece lookup logic between SpriteKit and view model.

#### Acceptance Criteria

- Player can undo a placement by tapping.
- Board and tray return to consistent state.
- Fixed dice are untouched.

#### Suggested `/goal` Prompt

```text
/goal Add placed-piece removal. Start with tests that tapping/removing a filled cell clears the whole piece, returns it to the tray, preserves dice, and updates progress. Then wire SpriteKit tap handling to GameViewModel.removePiece.
```

---

### Slice 15 — Add Game Screen Chrome: Header, Progress, Reset, Back

#### Behaviour

Game screen shows level title/subtitle, progress count/bar, back action, reset action, and SpriteKit board/tray area.

#### Why this slice exists

The user needs context, progress, and basic controls around the SpriteKit scene.

#### Red

Write UI/view-model tests:

- Opening a level shows its title.
- Progress starts at 0/playable count.
- Progress updates after placement.
- Reset clears placements and restores tray.
- Back returns to level select.

Suggested tests:

- `testGameScreenShowsLevelTitle`
- `testProgressStartsAtZero`
- `testProgressUpdatesAfterPlacement`
- `testResetRestoresInitialLevelState`
- `testBackReturnsToLevelSelect`

#### Green

Implement `GameView` shell around SpriteKit scene.

#### Refactor

Extract reusable buttons only after behaviour passes.

#### Acceptance Criteria

- Header and progress are visible.
- Reset works.
- Back works.
- Game screen layout works on iPhone and iPad.

#### Suggested `/goal` Prompt

```text
/goal Build the SwiftUI GameView chrome around the SpriteKit scene. First write tests for visible level title, progress text/state, reset behaviour, and back navigation. Then implement header, progress strip, reset, and back controls.
```

---

### Slice 16 — Add Completion Flow and Next-Level Navigation

#### Behaviour

When the board is solved, the app shows completion state with elapsed time and lets the player continue to the next level. Completed level state is saved.

#### Why this slice exists

Completion is part of the happy path and required success criteria.

#### Red

Write tests:

- Solving a level routes to completion.
- Completion displays solved level ID and elapsed time.
- Completed level is persisted.
- Continue starts next level if available.
- Continue from Level 15 routes to paywall if not unlocked.

Suggested tests:

- `testSolvingLevelRoutesToCompletion`
- `testCompletionShowsElapsedTime`
- `testSolvedLevelIsPersisted`
- `testContinueStartsNextAvailableLevel`
- `testContinueAfterFreeBoundaryRoutesToPaywallWhenLocked`

#### Green

Implement completion state/view and next-level routing.

#### Refactor

Keep completion animation timing out of core tests.

#### Acceptance Criteria

- Completion appears after solving.
- Progress persists.
- Continue respects lock boundary.
- No final price/name hardcoded.

#### Suggested `/goal` Prompt

```text
/goal Add completion flow. Write failing tests for solve-to-completion routing, elapsed time display, completed-level persistence, continue-to-next-level, and Level 15 paywall boundary. Then implement CompletionView and routing.
```

---

### Slice 17 — Add Rotation Tutorial Copy and UI Behaviour

#### Behaviour

When the player reaches the first rotation-enabled level, the game communicates that tapping a piece rotates it. Tapping rotates tray pieces only where rotation is available.

#### Why this slice exists

Rotation must be introduced gently and visibly, not silently.

#### Red

Write tests:

- Rotation tutorial copy appears on first rotation-enabled level.
- Copy does not appear on no-rotation tutorial levels.
- Tapping tray piece rotates it when allowed.
- Tapping tray piece does not rotate when locked.

Suggested tests:

- `testRotationTutorialAppearsOnFirstRotationLevel`
- `testRotationTutorialHiddenInBeginnerLevels`
- `testTapTrayPieceRotatesWhenAllowed`
- `testTapTrayPieceDoesNotRotateWhenLocked`

#### Green

Add rotation copy and tray tap behaviour.

#### Refactor

Store tutorial visibility policy in level/progression metadata.

#### Acceptance Criteria

- Rotation is discoverable.
- Beginner flow remains simple.
- No hints system is introduced.

#### Suggested `/goal` Prompt

```text
/goal Add rotation tutorial and tray tap rotation behaviour. First write tests for tutorial copy visibility on the first rotation level, hidden copy in beginner levels, tray tap rotation when allowed, and no rotation when locked. Then implement the smallest UI and state changes.
```

---

### Slice 18 — Add Responsive iPhone/iPad Layout Behaviour

#### Behaviour

The app adapts to iPhone and iPad. Board uses dynamic cell sizing. iPad can use more space without breaking touch targets.

#### Why this slice exists

The master prompt requires iPhone and iPad compatibility and dynamic SpriteKit sizing.

#### Red

Write tests or UI tests:

- Board cell size fits a compact iPhone viewport.
- Board cell size fits an iPad viewport.
- Board does not exceed available area.
- Minimum practical touch target is preserved where possible.
- Tray remains accessible.

Suggested tests:

- `testBoardSizingFitsIPhoneAvailableArea`
- `testBoardSizingFitsIPadAvailableArea`
- `testCellSizeDoesNotExceedBoardBounds`
- `testTrayRemainsAccessibleInCompactLayout`

#### Green

Implement dynamic sizing in SwiftUI/SpriteKit bridge.

#### Refactor

Extract sizing calculator into a testable pure type.

#### Acceptance Criteria

- iPhone simulator layout is usable.
- iPad simulator layout is usable.
- Board/tray are not clipped.
- No hardcoded device-specific layout hacks.

#### Suggested `/goal` Prompt

```text
/goal Add responsive iPhone/iPad layout behaviour. Start with tests for board sizing in compact and iPad-sized containers, cell-size bounds, and tray accessibility. Then implement a pure sizing calculator and apply it to SwiftUI/SpriteKit layout.
```

---

### Slice 19 — Add Accessibility Labels and Reduced Motion Behaviour

#### Behaviour

Important UI/game elements expose useful accessibility labels. Reduced Motion avoids excessive animation.

#### Why this slice exists

The reference analysis explicitly calls out accessibility labels and reduced motion as native improvements.

#### Red

Write tests/UI checks:

- Dice cell exposes label like “Fixed dice, B2”.
- Empty board cell exposes row/column label.
- Tray piece exposes colour/shape/rotation availability.
- Locked level exposes locked state.
- Reduced Motion setting disables or simplifies non-essential animation hooks.

Suggested tests:

- `testDiceCellAccessibilityLabelIncludesCoordinate`
- `testEmptyCellAccessibilityLabelIncludesRowAndColumn`
- `testTrayPieceAccessibilityMentionsRotationWhenAvailable`
- `testLockedLevelAccessibilityLabelMentionsLocked`
- `testReducedMotionUsesSimplifiedAnimationPolicy`

#### Green

Add accessibility labels/identifiers and reduced-motion animation policy.

#### Refactor

Centralize accessibility label generation.

#### Acceptance Criteria

- Core flow is understandable with VoiceOver labels.
- Reduced Motion policy exists.
- Tests verify visible/accessibility-facing output.

#### Suggested `/goal` Prompt

```text
/goal Add accessibility and reduced-motion support. Write tests for dice, empty cell, tray piece, locked level labels, and reduced-motion animation policy. Then add accessibility labels/identifiers and a simple reduced-motion animation fallback.
```

---

### Slice 20 — Add Final Scope Guard Regression Tests

#### Behaviour

The final app does not include out-of-scope features and does not hardcode final app name or final unlock price.

#### Why this slice exists

The master prompt explicitly forbids accounts, backend, leaderboards, daily challenge, social sharing, ads, subscriptions, hints, final app name, and final price.

#### Red

Write regression tests/static checks:

- No subscription product IDs are present.
- No ad framework imports are present.
- No account/login UI strings are present.
- No leaderboard/daily challenge/hints UI strings are present.
- Paywall does not contain hardcoded price strings like `$`, `£`, `€` in fixed copy.
- App display name remains placeholder/configurable.

Suggested tests:

- `testNoSubscriptionProductIdentifiers`
- `testNoAdFrameworkImports`
- `testNoOutOfScopeFeatureCopy`
- `testPaywallDoesNotHardcodePrice`
- `testAppNameRemainsConfigurable`

#### Green

Remove or avoid forbidden imports/strings if any appear.

#### Refactor

Create a lightweight test fixture/static scanner for source files.

#### Acceptance Criteria

- Scope guard tests pass.
- No forbidden feature is implemented.
- Price comes from StoreKit or generic fallback.
- App name remains changeable.

#### Suggested `/goal` Prompt

```text
/goal Add final scope-guard regression tests. Write static or behavioural tests proving there are no ads, subscriptions, accounts, leaderboards, daily challenge, social sharing, hints, hardcoded final price, or hardcoded final app name. Fix only violations needed to pass.
```

---

## Final Verification Checklist

### Commands

Codex should discover exact scheme names, then run equivalents of:

```bash
xcodebuild -list
xcodebuild test -scheme <AppScheme> -destination 'platform=iOS Simulator,name=iPhone 15'
xcodebuild test -scheme <AppScheme> -destination 'platform=iOS Simulator,name=iPad (10th generation)'
xcodebuild build -scheme <AppScheme> -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Manual QA

- Launch app on iPhone simulator.
- Launch app on iPad simulator.
- Level select appears.
- Levels 1–15 are accessible.
- Level 16 opens paywall before purchase.
- Level 1 opens and shows fixed coordinate dice.
- Dice cannot be moved.
- Drag a valid piece into place.
- Try an invalid placement over dice/outside board; it is rejected.
- Remove a placed piece.
- Solve a level; completion appears.
- Continue to next level.
- Rotation is unavailable in early levels.
- Rotation is available in later levels.
- Paywall uses `full_game_unlock`.
- Restore button is present.
- Purchase unlock persists.
- No ads/subscriptions/accounts/hints/social/leaderboards/daily challenge exist.
- No hardcoded final price appears.
- No final app name is hardcoded.

### Regression checklist

- All 50 levels exist.
- Level IDs are 1...50.
- Every level is solvable.
- Dice labels match coordinates.
- Board sizes are only 4×4, 5×5, 6×6.
- Free/paid boundary remains after Level 15.
- Completed levels persist.
- Unlock persists.
- StoreKit unavailable fallback does not break paywall.

### Accessibility checklist

- Level buttons have meaningful labels.
- Locked levels announce locked state.
- Board cells announce row/column and state.
- Fixed dice announce coordinate.
- Tray pieces announce rotation availability.
- Important actions have labels.
- Reduced Motion avoids excessive bounce/pulse.

## Suggested Execution Order

1. Slice 1 — Create a Compilable iOS/iPadOS 17+ Xcode Project
2. Slice 2 — Add Theme Tokens from the Reference Pack
3. Slice 3 — Model Shapes, Pieces, Dice, Levels, and Board State
4. Slice 4 — Add Shape Rotation Behaviour
5. Slice 5 — Add a 50-Level Catalogue Contract
6. Slice 6 — Validate Level Solvability
7. Slice 7 — Add App State, Progress, and Local Persistence
8. Slice 8 — Add Game Session Behaviour
9. Slice 9 — Gate Rotation by Level
10. Slice 10 — Build SwiftUI Level Select Behaviour
11. Slice 11 — Build StoreKit Purchase Manager and Paywall Behaviour
12. Slice 12 — Build SpriteKit Scene Rendering from Game State
13. Slice 13 — Add Drag, Drop, Snap, and Invalid Placement Feedback
14. Slice 14 — Add Placed Piece Removal
15. Slice 15 — Add Game Screen Chrome: Header, Progress, Reset, Back
16. Slice 16 — Add Completion Flow and Next-Level Navigation
17. Slice 17 — Add Rotation Tutorial Copy and UI Behaviour
18. Slice 18 — Add Responsive iPhone/iPad Layout Behaviour
19. Slice 19 — Add Accessibility Labels and Reduced Motion Behaviour
20. Slice 20 — Add Final Scope Guard Regression Tests

## Notes for Codex

Stay behaviour-driven. Do not skip tests. Do not combine slices. Do not build the full UI before the model and view-model behaviours are protected. Keep SpriteKit tests focused on user/system-visible outcomes, not node internals. Inspect the repo before editing each slice. Prefer Apple frameworks only. Do not add out-of-scope features. Do not hardcode final app name or final unlock price.
