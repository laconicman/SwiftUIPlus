# Tech debt

Open architectural questions and known limitations. New entries go at the top of the relevant section; resolved entries get a short "Resolved in #PR" line and stay for one release before being removed.

## Presentation additions

### `BottomActionSheet`: `.fullScreenCover`-based vs. `UIWindow`-overlay implementation

**Current state.** `View.bottomActionSheet(...)` is implemented on top of `.fullScreenCover`. The system slide-up animation of the cover is suppressed by routing the presentation `Binding` through a wrapper that commits mutations inside `Transaction(disablesAnimations: true)`. The card's own slide-up / fade is driven by an internal `@State` flag plus `withAnimation`. The cover's outer view applies `.backport.presentationBackground(.clear)` so the host's background does not show through.

**Soft spots in the current implementation.**

- `Transaction.disablesAnimations` on a binding-mutation site is undocumented behaviour. SwiftUI honours it today on iOS 15–18, but Apple has never contractually promised it. If a future iOS release stops honouring it, the cover will gain back the default slide-up animation underneath the custom card animation. Failure mode is cosmetic, not functional.
- The `.backport.presentationBackground(.clear)` fallback on iOS 15–16.3 walks the responder chain via `SwiftUIBackports` to find the enclosing `UIHostingController` and clears its background. Robust in practice but a UIKit-level monkey-patch.
- The card-dismiss sequencing uses `CATransaction.setCompletionBlock` to drop the cover only after `withAnimation` settles. Widely used pattern, not strictly contractual; an obvious safety-net would be a `Task.sleep` deadline that re-introduces the magic-number problem we set out to avoid.

**Alternative implementation: own a `UIWindow` at `UIWindow.Level.alert`.**

Considered and not adopted in PR #1. The shape would be:

- Add a `UIWindow` on the active `UIWindowScene` with `windowLevel = .alert`.
- Install a `UIHostingController` whose `view.backgroundColor = .clear` from the start.
- Manage layout / safe-area / rotation / multi-window manually.

What we gain if we ever revisit:

- No `Transaction.disablesAnimations` trick at all — there is no system modal animation to suppress.
- No SwiftUIBackports `presentationBackground` dependency for the cover itself — the host's background is clear from construction. This would also let `SwiftUIPlus`'s `Package.swift` flip away from the temporary fork pin without waiting on the upstream `presentationBackground` backport.
- Deployment floor for this modifier could drop to iOS 13 (the current floor is constrained by `.fullScreenCover` + the binding-wrapper trick).
- Works above other modals (`.sheet` / `.fullScreenCover` opened by the same screen) because the overlay is on its own window.

What it costs:

- ~40 LOC of pure scaffolding plus rotation and iPad multi-window edge cases.
- A second presentation backend in the library that has to be maintained alongside the existing `.fullScreenCover`-based path (or migrated wholesale, which is its own project).
- The current `.fullScreenCover`-based path is good enough for the iOS-15 floor this lib targets, so the cost has not paid for itself yet.

**Triggers to revisit.**

- The library opens a "robust modal additions" track (overlays that need to escape sheet contexts, in-app toasts that survive across navigation, etc.) and ends up needing a UIWindow overlay anyway — fold `bottomActionSheet` into that backend so we delete both SwiftUI tricks above.
- Apple changes the behaviour of `Transaction.disablesAnimations` at the binding-mutation site in a future iOS release.
- `CATransaction.setCompletionBlock` stops firing reliably under `withAnimation` for any reason.
- The temporary `laconicman/SwiftUIBackports` fork pin in `Package.swift` becomes hard to retire — at that point a `UIWindow`-overlay implementation removes the underlying `presentationBackground` dependency entirely.

**References.**

- PR [#1](https://github.com/laconicman/SwiftUIPlus/pull/1) — `feat/bottom-action-sheet`. Original SwiftUIPlus implementation, ported from `laconicman/SwiftUIBackports#3`.
- Devin Review on PR #1: `ANALYSIS_..._0001` flagged the `CATransaction.setCompletionBlock` pattern as relying on undocumented SwiftUI behaviour and noted the `TECH_DEBT.md` reference in the doc comment had no corresponding file — this entry is that file.
