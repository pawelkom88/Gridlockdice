# Gridlock Dice — Swift Refactor Analysis

## 1. UI Analysis

### Screens
| Screen | React component | Purpose |
|---|---|---|
| Level Select | `LevelSelect` | 4 sections × 5-column level grid, locked sections |
| Game | `GameScreen` | Board + tray + progress bar, drag-to-place interaction |
| Paywall | `Paywall` | One-time purchase, feature list, mini board preview |
| Completion | `Completion` | Phased animated result screen |

### Layout structure
- All screens are full-height column stacks (VStack in SwiftUI terms)
- Game screen: Header (64pt) → Progress (32pt) → Board (flex) → Tray (122pt)
- Tray: horizontal ScrollView, `flexShrink:0` pieces → `ScrollView(.horizontal)`
- Board cells sized dynamically from available space (GeometryReader)

### Reusable components
- `PieceGrid` — renders any Shape as a grid of coloured cells (used in tray, ghosts, paywall preview)
- `BoardCellView` — single board cell with dice/filled/hover states
- `LevelCell` — level select button with done/next/locked states
- `StatCard` — completion screen stat badge
- Button styles: `PrimaryButtonStyle`, `SecondaryButtonStyle`, `AccentButtonStyle`
- `CircleButton` — icon circle button for header

### Key JS interactions
| Interaction | React | SwiftUI |
|---|---|---|
| Drag piece to board | `onMouseMove`/`onMouseUp` on container | `DragGesture` on `BoardGridView` |
| Tap to rotate | `onClick` + `trayTouchStart/End` scroll disambiguation | `.onTapGesture` on `TrayPieceView` |
| Tap placed cell to lift | `onClick` on cell | `.onTapGesture` on `BoardCellView` |
| Scroll tray horizontally | `overflow-x: scroll`, `touch-action: pan-x` | `ScrollView(.horizontal)` |
| Phased completion reveal | `setTimeout` chain | `DispatchQueue.main.asyncAfter` chain |

---

## 2. Refactor Plan

### State mapping
| React useState | Swift equivalent |
|---|---|
| `grid` (2D array of pieceIDs) | `BoardState` value type with `CellState` enum |
| `tray` (piece array) | `[TrayPiece]` on `GameViewModel` — `TrayPiece.shape` is mutable for rotation |
| `placed` (array of placed pieces) | `placedIDs: [String]` — original shapes retrieved from `LevelDef` |
| `drag` | `dragState: DragState?` on `GameViewModel` |
| `hover` (row/col) | `hoverRow`, `hoverCol` on `GameViewModel` |
| `shake`, `snap`, `rotAnim` | `shakingPieceID`, `snappingPieceID`, `rotatingPieceID` |
| `screen` string | `AppScreen` enum on `AppViewModel` |
| `completed` array | `completedIDs: Set<Int>` on `AppViewModel` |
| `startT` / timer | `startDate: Date` + async `Task` loop in `GameViewModel` |

### Architecture decisions
- `@Observable` macro (iOS 17+) replaces `ObservableObject`/`@Published`
- `@Environment` injection instead of prop-drilling
- `BoardState` is a value type — safe to copy, diff, and undo
- `Shape` is `[[Bool]]` — rotation is a pure function, no mutation needed until the user rotates
- `GameViewModel` owns one level session; discarded and recreated on level start
- No third-party libraries — all SF Symbols, native gestures, native animations

### CSS → SwiftUI mapping
| CSS rule | SwiftUI equivalent |
|---|---|
| `background: #000` | `.background(Color.bg0)` |
| `border: 0.5px solid rgba(...)` | `.overlay(RoundedRectangle().strokeBorder(..., lineWidth: 0.5))` |
| `box-shadow: 0 3px 0 color` | `.shadow(color:, radius:0, x:0, y:3)` |
| `border-radius: 14px` | `.clipShape(RoundedRectangle(cornerRadius:14, style:.continuous))` |
| `overflow-x: auto` | `ScrollView(.horizontal)` |
| `flex: 1` | `.frame(maxWidth:.infinity, maxHeight:.infinity)` |
| `gap: 4px` (grid) | `spacing: 4` in HStack/VStack |
| `transition: width 0.4s cubic-bezier(...)` | `.animation(.spring(response:0.4,...), value:)` |
| CSS `@keyframes snapPop` | `.scaleEffect` + `.spring` animation |
| CSS `@keyframes shakePiece` | `.offset(x:)` + `.easeInOut.repeatCount(4, autoreverses:true)` |
| CSS `@keyframes glowPulse` | `.shadow` animated with `.easeInOut.repeatForever` |

---

## 3. File Structure

```
GridlockDice/
  App/
    GridlockDiceApp.swift       — @main entry point

  Models/
    Models.swift                — Shape, PieceDef, TrayPiece, DiceMarker,
                                  LevelDef, BoardState, CellState, LevelCatalogue

  ViewModels/
    AppViewModel.swift          — AppScreen enum, AppViewModel, GameViewModel, DragState

  Views/
    RootView.swift              — Navigation switch + transition
    LevelSelectView.swift       — Level grid + section headers
    GameView.swift              — Board, tray, header, progress
                                  (also contains BoardGridView, BoardCellView,
                                   TrayPieceView, GhostPieceView, PieceGrid)
    CompletionView.swift        — Phased animated result + StatCard
    PaywallView.swift           — Purchase screen + feature list

  Theme/
    AppTheme.swift              — Color extensions, PieceColorName, Spacing,
                                  AppFont, Radius
```

---

## 4. Behaviour Mapping

| Web behaviour | Swift equivalent |
|---|---|
| `onMouseDown` on tray piece starts drag | `LongPressGesture.sequenced(before: DragGesture)` |
| `onMouseMove` on container updates hover | `DragGesture.onChanged` on `BoardGridView` |
| `onMouseUp` drops piece | `DragGesture.onEnded` on `BoardGridView` |
| `onClick` on tray piece rotates it | `.onTapGesture` on `TrayPieceView` → `vm.rotatePiece(id:)` |
| Touch scroll disambiguation (trayTouchMove) | Native `ScrollView(.horizontal)` handles it — no disambiguation needed |
| `onClick` on placed board cell lifts it | `.onTapGesture` on `BoardCellView` |
| `onClick` on ghost thumbnail lifts piece | `.onTapGesture` on `GhostPieceView` |
| `isSolved` check after every placement | Called in `GameViewModel.tryPlace()` after `board.place()` |
| `setTimeout(onComplete, 650)` | `Task { try? await Task.sleep(...); onSolved(elapsed) }` |
| Phased completion reveal (setTimeout × 3) | `DispatchQueue.main.asyncAfter` × 3 in `.onAppear` |
| React `key={lvlId}` re-mounts GameScreen | `GameViewModel` recreated in `AppViewModel.startLevel()` |
| `rotateCW()` pure function | `Shape.rotatedCW()` extension method |

---

## 5. Design Token Mapping

| React token | Swift |
|---|---|
| `T.bg0` `#000000` | `Color.bg0` |
| `T.bg1` `#1c1c1e` | `Color.bg1` |
| `T.bg2` `#2c2c2e` | `Color.bg2` |
| `T.l1` `#ffffff` | `Color.label1` |
| `T.l3` `rgba(255,255,255,0.75)` | `Color.label3` |
| `T.sep` `rgba(255,255,255,0.12)` | `Color.sep` |
| `T.accent` `#0a84ff` | `Color.accentBlue` |
| `T.accentG` `#30d158` | `Color.accentGreen` |
| `T.accentY` `#ffd60a` | `Color.accentYellow` |
| `PC.red.bg` `#ff453a` | `PieceColorName.red.style.fill` |
| `padding: "16px 20px"` | `Spacing.lg` / `Spacing.xl` |
| `gap: 4` (grid cells) | `spacing: 4` |
| `border-radius: 14px` | `Radius.lg` / `cornerRadius: 14` |
| `font-weight: 700` | `.weight(.bold)` |
| `font-weight: 600` | `.weight(.semibold)` |
| `letter-spacing: -0.025em` | `.tracking(-0.4)` (approximate pt) |

---

## 6. Native Improvement Suggestions

1. **Haptic feedback** — Add `UIImpactFeedbackGenerator(style: .light)` on snap, `.medium` on invalid placement. No equivalent in the web prototype.

2. **Dynamic Type** — Replace fixed `fontSize:` values with `AppFont.*` enum which wraps `.system(size:weight:)`. For full Dynamic Type support, switch to semantic styles like `.headline`, `.body` and let the OS scale them.

3. **Accessibility labels** — Board cells need `.accessibilityLabel("Row A, Column 1, empty")` etc. Tray pieces need `.accessibilityLabel("Red L-piece, tap to rotate")`. Dice blockers need `.accessibilityLabel("Fixed dice, B1")`.

4. **Reduced Motion** — Wrap spring animations in `@Environment(\.accessibilityReduceMotion)` check; fall back to instant `.easeInOut(duration:0.1)` substitutes.

5. **iPad layout** — On iPad, the board can be wider. The `GeometryReader`-based cell size calculation already handles this. Consider a side-by-side layout (board left, tray right in a `HStack`) for landscape iPad, matching Layout Option C from earlier exploration.

6. **StoreKit 2** — `PaywallView` has a clear hook-in point. Replace the `appVM.unlock()` stub with `StoreKit.Product.purchase()` and observe `Transaction.updates` for restore.

7. **Persistence** — `AppViewModel.completedIDs` should be `@AppStorage` or written to `UserDefaults` so progress survives app launches.

8. **Undo gesture** — SwiftUI supports `.onShake` (via `UIDevice.orientationDidChangeNotification`) or a two-finger tap for undo — natural mobile pattern for "lift last placed piece".

---

## 7. Assumptions

- Target: **iOS 17+, iPadOS 17+**. Uses `@Observable` macro — not backport-compatible with iOS 16.
- Drag-to-place uses `DragGesture` on the board, not on individual pieces. The piece begins dragging from the tray via `LongPressGesture.sequenced(before: DragGesture)`, which SwiftUI requires to separate a tap (rotate) from a drag (place). This replaces the React `touchstart/touchmove scroll disambiguation` pattern.
- `ScrollView(.horizontal)` in SwiftUI natively handles touch-scroll vs drag disambiguation — the React manual `trayTouchRef` hack is not needed.
- In-app purchase is stubbed (`appVM.unlock()`). StoreKit 2 integration requires a real product ID and entitlement check.
- The `Shape` type is `[[Bool]]` rather than the React `[[0|1]]` array — this is idiomatic Swift and eliminates integer-to-bool coercion.
- `isSolved` is called inside `GameViewModel` after every `tryPlace`. No need for `useEffect` equivalent since it's synchronous state inspection.
