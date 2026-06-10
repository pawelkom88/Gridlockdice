# App Store Audit: GridlockDice

---

## Executive Summary

**Overall Risk Level: MEDIUM**

GridlockDice is a legitimate, well-engineered polyomino puzzle game with zero data collection, no third-party SDKs, a clean single-IAP model, and 127 passing tests. The codebase shows genuine craft. However, the app has three areas that could trigger rejection or delay: **(1)** locked dark mode with no light mode support, **(2)** zero Dynamic Type / font scaling, **(3)** custom navigation that ignores standard iOS back-swipe and nav bar conventions. Apple's accessibility bar has risen every year. An app targeting iOS 17+ that hardcodes every font size and forces dark mode is a real risk. The IAP implementation is best-in-class and privacy is flawless.

---

## Risk Report

### 🔴 HIGH

#### 1. No Dynamic Type / Font Scaling Support

- **Why it matters:** All 40+ font sizes are hardcoded (`Font.system(size: 11)` through `Font.system(size: 38)`). Zero use of `@ScaledMetric`, `.dynamicTypeSize`, or `UIFontMetrics`. Users who set larger text in Settings get zero benefit. Apple's WWDC sessions and HIG have repeatedly emphasized Dynamic Type as a requirement, not a suggestion. The app targets iOS 17+ where Dynamic Type is mature. This is the most likely trigger for a "2.1 - Performance: App Completeness" or 4.2 (Design) rejection.
- **Evidence from code:** `AppTheme.swift:72-79` — every font function returns hardcoded sizes. `LevelSelectView.swift:53`, `PaywallView.swift:31,84,104,108`, `GameView.swift:52,119`, `OnboardingOverlayView.swift:27,69,120,123,128,144,147,169,178,188,194,207,228,257,273,283,293` — all use `Font.system(size: X)`.
- **What exactly to fix:**
  - Replace all `Font.system(size: X)` with `Font.system(size: X).dynamicTypeSize(...)` or define a scalable font enum that uses `@ScaledMetric` or `UIFontMetrics.scaledFont(for:)`.
  - Run the app with Accessibility Inspector at AX sizes and verify nothing clips.
  - Add `.dynamicTypeSize(...)` constraints only where layout truly cannot stretch (e.g., cell labels).
  - Test at every Dynamic Type step.
- **Blocker:** Yes
- **Confidence:** High

#### 2. Dark Mode Only — No Light Mode Support

- **Why it matters:** `.preferredColorScheme(.dark)` in `GridlockDiceApp.swift:8` locks the app to dark mode permanently. Apple's HIG states: "Support both light and dark appearances." Users with astigmatism or those using their device in bright environments may need light mode. Dark-only is tolerated for games with strong aesthetic justification, but this app has no technical reason — it's a design choice. Apple can reject under 4.2 (Design) or accessibility guidelines.
- **Evidence from code:** `GridlockDiceApp.swift:8` — `.preferredColorScheme(.dark)`. `AppTheme.swift:3-36` — `bg0` is `#000000` (black), `bg1` is `#1c1c1e` (dark gray). No light mode color definitions exist anywhere. Not a single `colorScheme` conditional.
- **What exactly to fix:**
  - Define a full light mode color palette (white backgrounds, dark text, softer piece colors).
  - Remove `.preferredColorScheme(.dark)` or conditionally apply it only when needed.
  - Test every screen in both appearances. Pay special attention to dice cells (white on white in light mode) and piece borders.
  - Alternatively: if keeping dark-only, add a strong justification in App Store Review Notes and prepare to defend the decision.
- **Blocker:** Yes (can be waived with justification for games, but risky)
- **Confidence:** Medium

#### 3. Custom Navigation Without Standard Back Gesture / Nav Bar

- **Why it matters:** The app uses a manual `switch`-on-enum navigation system (`RootView.swift:13-43`) instead of `NavigationStack`. The back button in PaywallView is a `< Back` text button (`PaywallView.swift:19`). There is no swipe-back gesture on any screen. GameView uses a custom circle chevron button (`GameView.swift:41-47`) instead of a standard navigation bar. Apple's HIG says: "Users expect consistent navigation." Custom navigation can be rejected under 4.2 if it feels broken or non-standard. The Paywall `< Back` button is especially likely to feel "off" to an Apple reviewer.
- **Evidence from code:** `RootView.swift:13-43` — manual `switch appVM.screen`. `PaywallView.swift:19` — `Button("< Back")`. `GameView.swift:41-47` — custom circle button with `Image(systemName: "chevron.left")`. No `NavigationStack`, no `navigationBarBackButtonHidden()` with proper gesture handling.
- **What exactly to fix:**
  - Migrate to `NavigationStack` with path-based navigation where possible.
  - At minimum: add `UIScreenEdgePanGestureRecognizer` or equivalent swipe-back for the Paywall and Completion screens.
  - Replace `< Back` text button with a proper SF Symbol chevron or standard nav bar.
  - Ensure all back actions are reachable via VoiceOver gestures.
- **Blocker:** Possibly
- **Confidence:** Medium

---

### 🟠 MEDIUM

#### 4. Level Section Label Misalignment: "Rotation" Section Includes Non-Rotation Levels (16–20)

- **Why it matters:** The level picker groups levels 16–30 under the label "Rotation" and subtitle "Unlock required" (`LevelSelectView.swift:10`). But rotation is only enabled for levels 21+ (`Models.swift:65`: `var allowsRotation: Bool { id >= 21 }`). A user who pays $2.99 expecting rotation from level 16 will find levels 16–20 have no rotation. This is misleading at best, and could be interpreted as deceptive monetization under 3.1 or 4.2.
- **Evidence from code:** `LevelSelectView.swift:10` — `("Rotation", "Unlock required", 16...30)`. `Models.swift:65` — `var allowsRotation: Bool { id >= 21 }`.
- **What to fix:**
  - Split the "Rotation" section to start at 21: `("Rotation", "Unlock required", 21...30)`.
  - Or rename sections to "Intermediate" (16–20) and "Rotation" (21–30). Or add "(rotation from level 21)" to the subtitle.
  - Do NOT mislead users about what they're buying.
- **Blocker:** Possibly
- **Confidence:** High

#### 5. Title Mismatch: "Block Game" vs Actual App Name "GridlockDice"

- **Why it matters:** `LevelSelectView.swift:17` displays `Text("Block Game")` as the app title. The app's actual name (from Xcode project, bundle, Springboard) is "GridlockDice". The onboarding view correctly uses `CFBundleDisplayName` (`OnboardingOverlayView.swift:119`), creating inconsistency. This could confuse users and Apple review may flag it under 2.3.7 (misleading metadata) or 4.2 (inconsistent UI).
- **Evidence from code:** `LevelSelectView.swift:17` — `Text("Block Game")`. `OnboardingOverlayView.swift:119` — reads from `Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")`.
- **What to fix:**
  - Use dynamic bundle name in LevelSelectView, same as onboarding: `Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName")`.
  - Or set `CFBundleDisplayName` to "Block Game" in build settings and rename the project.
  - Match the App Store listing name exactly.
- **Blocker:** Possibly
- **Confidence:** High

#### 6. Auto-Solve Button Prominently Displayed in Header

- **Why it matters:** The magic wand button (`GameView.swift:74-83`) provides full auto-solve for every puzzle. It is always visible in the game header — not hidden in a menu or gated behind a hint system. Apple reviewers may consider this a "thin" game if the player never has to solve anything. Not a common rejection reason for puzzle games (Sudoku apps have auto-solve), but combined with procedurally generated pieces (levels 6–50), it raises the question: "Is this a game or a simulation?"
- **Evidence from code:** `GameView.swift:76` — `vm.autoSolve()`. `AppViewModel.swift:184-199` — calls `PuzzleSolver.findSolution()` and animates the solution. Always available, no usage limit.
- **What to fix:**
  - Move auto-solve behind a confirmation alert ("This will solve the puzzle for you. Are you sure?").
  - Add a cooldown or limit per level.
  - At minimum, add a usage counter for internal review to show it's not the primary interaction.
- **Blocker:** No (but reduces perceived value)
- **Confidence:** Low

#### 7. Procedural Piece Generation for Levels 6–50

- **Why it matters:** Levels 6–50 use `makePieces()` (`Models.swift:156-233`) which procedurally generates polyomino pieces by greedily filling the grid. While the dice positions are hand-crafted per level, the pieces are not. Apple has rejected apps for being "automatically generated content" or lacking hand-crafted quality. The solver verification (`PuzzleSolver.isSolvable`) ensures solvability but the resulting puzzles may feel samey.
- **Evidence from code:** `Models.swift:156-233` — `makePieces()` uses random walks with seeded RNG. `Models.swift:263-277` — `L()` helper calls `makePieces()` for levels 6-50.
- **What to fix:**
  - Hand-craft at least the first 5 levels of each section (16-20, 21-25, etc.) to show genuine content curation.
  - Add variety to the piece generation algorithm (different shapes, sizes, branching factors).
  - Document the level design process in App Store Review Notes.
- **Blocker:** No
- **Confidence:** Low

#### 8. No Support for Accessibility Features Beyond Basic Labels

- **Why it matters:** The app has accessibility labels (`Accessibility.swift`) and reduced motion support (`ReducedMotionPolicy`). But it lacks: `.accessibilityAddTraits(.isButton)` on interactive cells, `.accessibilitySortPriority()` for logical VoiceOver navigation, Dynamic Type (already flagged separately), Bold Text support, `accessibilityIgnoresInvertColors`, and `UIAccessibility.isOnOffSwitchLabelsEnabled`. For a game targeting iOS 17+, VoiceOver users may find navigation confusing.
- **Evidence from code:** `BoardCellView.swift:31-36` — no `.accessibilityAddTraits(.isButton)` on tappable cells. No `.accessibilitySortPriority()` anywhere. No `@ScaledMetric`.
- **What to fix:**
  - Add `.accessibilityAddTraits(.isButton)` to `BoardCellView`, `LevelCell`, all tappable elements.
  - Add `.accessibilitySortPriority()` to define logical VoiceOver order (top-left to bottom-right for the board).
  - Test with VoiceOver turned on and fix any navigation dead-ends.
  - Add `accessibilityIgnoresInvertColors` to rich visual elements.
- **Blocker:** Possibly
- **Confidence:** Medium

---

### 🟢 LOW

#### 9. No Localization / English Only

- **Why it matters:** Not a blocker, but Apple encourages internationalization. 50+ hardcoded strings with no `.xcstrings` or `.strings` files.
- **Suggested improvement:** Extract all strings to a String Catalog. Start with at least German, French, Spanish, Japanese, Chinese for puzzle game markets.
- **Blocker:** No
- **Confidence:** High

#### 10. `CellSizingCalculator.swift` Lives in `SpriteKit/` Directory but Uses Only CoreGraphics

- **Why it matters:** Cosmetic code organization issue. The `SpriteKit/` folder imports `CoreGraphics`, not `SpriteKit`. Misleading structure.
- **Suggested improvement:** Move `CellSizingCalculator.swift` to a `Utility/` or `Layout/` directory, or rename `SpriteKit/` to `Layout/`.
- **Blocker:** No
- **Confidence:** High

#### 11. Dice Cells Use Pure White — Hard to Distinguish in Dark Mode on Some Displays

- **Why it matters:** Dice cells are `Color.white` (`BoardCellView.swift:48`). On OLED displays in dark mode, pure white (255,255,255) is very bright compared to the black background and could cause eye strain.
- **Suggested improvement:** Use `Color.white.opacity(0.85)` or a light cream (#f0f0f0) for dice cells. Keep the "white dice" visual metaphor but reduce OLED brightness.
- **Blocker:** No
- **Confidence:** Low

#### 12. Timer Starts on `init` — Runs Even If View Never Appears

- **Why it matters:** `GameViewModel.init()` calls `startTimer()` which immediately begins counting. If the level is created but the user navigates away, the timer ticks unused. Minor.
- **Suggested improvement:** Move `startTimer()` to `onAppear` of `GameView`, or `viewDidAppear` equivalent.
- **Blocker:** No
- **Confidence:** Medium

#### 13. Paywall Price Shows "Unlock" as Fallback When Product Unavailable

- **Why it matters:** `PurchaseService.swift:20` — `product?.displayPrice ?? "Unlock"`. If StoreKit fails to load the product (no network, etc.), the price text becomes "Unlock" which could be misleading — users might think it's free.
- **Suggested improvement:** Show a loading indicator while the product loads. Only show the CTA when `productAvailable` is true. If unavailable after a timeout, show "Unable to connect" instead of "Unlock".
- **Blocker:** No
- **Confidence:** Medium

#### 14. `GridlockDice.storekit` Uses `en_US` Locale Only

- **Why it matters:** StoreKit testing config is locked to `en_US`. Won't affect production StoreKit, but could miss locale-related bugs during testing.
- **Suggested improvement:** Add at least one alternative locale (e.g., `de_DE`, `ja_JP`) to the .storekit config for testing.
- **Blocker:** No
- **Confidence:** Low

#### 15. No Invert Colors / Accessibility Accommodations for Piece Colors

- **Why it matters:** Piece colors are defined as specific hex values (`#ff453a`, `#30d158`, etc.). Under Smart Invert Colors, these may invert unpredictably, making pieces blend into the board.
- **Suggested improvement:** Test with Settings > Accessibility > Display & Text Size > Smart Invert. Add `accessibilityIgnoresInvertColors()` to piece rendering if needed.
- **Blocker:** No
- **Confidence:** Low

---

## Priority Fix Plan

1. **Dynamic Type support** — highest rejection risk. Fix font scaling across all views.
2. **Light mode color palette** — define light mode colors, remove dark mode lock.
3. **Navigation overhaul** — migrate to NavigationStack or add proper swipe-back gestures.
4. **Fix level section labels** — split Rotation section to start at 21.
5. **Fix title mismatch** — use dynamic bundle name in LevelSelectView.
6. **Add `.accessibilityAddTraits(.isButton)`** — improve VoiceOver navigation.
7. **Move auto-solve behind confirmation** — reduce "thin app" perception.
8. **Hand-craft more levels** — improve content quality argument.
9. **Localization** — start with String Catalog.
10. **Polish: dice brightness, timer init, paywall fallback** — low priority.

---

## Submission Verdict

**⚠️ Close, but needs fixes — do NOT submit as-is.**

The app is fundamentally solid: zero data collection, zero tracking, proper StoreKit IAP, 127 passing tests, clean architecture. Apple will not reject for spam, low quality, or technical issues.

However, **Dynamic Type (fix #1)** and **dark mode lock (fix #2)** are genuine rejection risks under current App Store accessibility enforcement. The **navigation (fix #3)** and **level label misalignment (fix #4)** are medium risks that could delay review.

Fix items 1–5 from the priority plan, then submit. Expect 2–3 days review turnaround.

**Verdict: Not ready. Needs ~1 week of focused accessibility and polish work.**

---

## Missing Info / Assumptions

- App Store screenshots not reviewed — assume they match actual UI.
- Landing page / privacy policy URL not reviewed (user will create separately).
- Actual App Store Connect metadata (keywords, description, category) not reviewed.
- Actual app icon visual quality not reviewed (PNGs exist but cannot inspect aesthetics).
- No macOS or visionOS targets — this audit covers iOS/iPadOS only.
- No TestFlight beta feedback available — assume first submission.
- No age rating or content rating configuration verified.
- Actual production App Store Connect IAP record not reviewed (only local .storekit config).
