import SwiftUI
import SwiftUIBackports

#if os(iOS)

@available(iOS 15, *)
extension BottomActionSheet {

    /// `isPresented:` variant of the action-sheet modifier.
    ///
    /// The `.fullScreenCover` is driven by an internal `coverPresented`
    /// @State that is decoupled from the consumer's binding. When the
    /// consumer's binding flips to `false` (from any source: their own code,
    /// `\.dismiss`, backdrop tap, drag, VoiceOver escape), the Cover
    /// observes it via `.onChange`, plays the card-exit animation, and only
    /// then drops `coverPresented` so the system slide-down is suppressed
    /// against an already-empty cover.
    struct IsPresentedModifier<SheetContent: View>: ViewModifier {
        @Binding var isPresented: Bool
        let onDismiss: (() -> Void)?
        let sheetContent: () -> SheetContent

        @State private var coverPresented: Bool = false
        @State private var presentationKey: Int = 0

        func body(content: Content) -> some View {
            content
                .fullScreenCover(isPresented: coverBridge, onDismiss: onDismiss) {
                    Cover(
                        content: sheetContent,
                        isPresented: $isPresented,
                        onCardExitComplete: dropCover
                    )
                    .id(presentationKey)
                }
                .backport.onChange(of: isPresented) { _, newValue in
                    if newValue && !coverPresented { presentCover() }
                }
                .onAppear {
                    if isPresented && !coverPresented { presentCover() }
                }
        }

        /// Binding handed to `.fullScreenCover`. The `get` reports our
        /// internal `coverPresented`; any external set-to-false (e.g.
        /// `\.dismiss` from inside the cover content) is routed back
        /// through the consumer's binding so the Cover's `.onChange`
        /// triggers the custom exit animation.
        private var coverBridge: Binding<Bool> {
            Binding(
                get: { coverPresented },
                set: { newValue in
                    if newValue == false { isPresented = false }
                }
            )
        }

        private func presentCover() {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { coverPresented = true }
        }

        private func dropCover() {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            if isPresented {
                // Rapid-toggle: consumer flipped `isPresented` back to true
                // while the exit animation was still running. Keep the
                // `.fullScreenCover` modal up (no UIKit dismiss/re-present
                // cycle) and bump the Cover's identity so SwiftUI replaces
                // it with a fresh instance whose @State (isVisible,
                // isAnimatingExit, dragTranslation) is reset for the
                // re-entry animation.
                withTransaction(transaction) { presentationKey += 1 }
            } else {
                // Normal case: consumer's binding stayed false; drop the
                // modal. `coverPresented` going false tears down the
                // Cover; the next `presentCover()` call (if any) will
                // instantiate a fresh one without needing the id bump.
                withTransaction(transaction) { coverPresented = false }
            }
        }
    }
}

#endif
