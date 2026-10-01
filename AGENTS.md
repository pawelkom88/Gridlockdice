# GridlockDice

## Source layout

- Active source: `GridlockDice/GridlockDice/` (Xcode project source root).
- Root-level `.swift` files (e.g. `AppTheme.swift`, `Models.swift`) are **old/duplicates** — NOT in the Xcode project. Do not edit them.
- Landing page: `landing-page/` (static HTML, Netlify-deployed).

## Dev commands (Xcode only, no JS toolchain)

```bash
# Build (iOS Simulator)
xcodebuild build -scheme GridlockDice -destination 'platform=iOS Simulator,name=iPhone 15'

# Run all tests
xcodebuild test -scheme GridlockDice -destination 'platform=iOS Simulator,name=iPhone 15'

# Run a single test class
xcodebuild test -scheme GridlockDice -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:GridlockDiceTests/BoardStateTests

# Run a single test method
xcodebuild test -scheme GridlockDice -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:GridlockDiceTests/BoardStateTests/testDicePlacement
```

No linter, formatter, CI, or package manager (zero third-party deps — only Apple frameworks).

## App facts

- **Entrypoint:** `GridlockDiceApp.swift` → `RootView()` → switch-on-enum nav (no `NavigationStack`).
- **Min OS:** iOS 17.0 (uses `@Observable` macro, no `ObservableObject`).
- **Dark mode locked:** `.preferredColorScheme(.dark)`, no light mode support.
- **No Dynamic Type:** font sizes hardcoded via `Font.system(size:)`, no `@ScaledMetric`.
- **IAP:** `gridlockdice.lifetime.unlock` (NonConsumable, $2.99) in `GridlockDice.storekit`.
- **Views:** `LevelSelectView` → `GameView` → `PaywallView` / `CompletionView`.
- **Levels:** 50 levels, procedural generation (seeded RNG) for levels 6–50.
- **Rotation gating:** `allowsRotation` at `id >= 21` but level section label says "Rotation" for 16–30 (known misalignment).
- `find_strict.swift` — standalone solver test script, not in Xcode project.

## Test quirks

- **Hardcoded path:** `ScopeGuardTests.swift` line 8 has `let root = "/Users/paw/WebstormProjects/BLOCK-GAME/GridlockDice/GridlockDice"` — fails on other machines. Update for CI or other devs.
- All tests are XCTest unit tests (no UI tests). No async test framework.
- Test doubles (`InMemoryStore`, `FakePurchaseService`) defined inline in test files.
- Some test classes annotated `@MainActor`.

## Architecture notes

- **No backend, no accounts, no subscriptions, no ads, no social.** Single-player offline puzzle game.
- `AppViewModel` owns navigation + persistence + purchase state (one instance, app-wide).
- `GameViewModel` created per game session (board + tray + drag state + timer).
- `BoardState` is a value type (`CellState` enum: `empty`, `dice(label:)`, `filled(pieceID:color:)`).
- `PuzzleSolver`: backtracking solver with 500k node cap.
- `CellSizingCalculator` lives in `SpriteKit/` but imports CoreGraphics, not SpriteKit. The SpriteKit rendering layer is planned but not yet implemented.
- `PaywallView` calls `appVM.priceText` (delegates to `PurchaseService`).

## Landing page

- Static site in `landing-page/`, deployed to Netlify (`gridlockdice.netlify.app`) and Cloudflare Pages (`gridlockdice.pages.dev`).
- No build step — just `index.html`, `privacy.html`, `terms.html`.
