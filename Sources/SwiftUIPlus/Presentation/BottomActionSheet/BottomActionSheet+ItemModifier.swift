import SwiftUI
import SwiftUIBackports

#if os(iOS)

@available(iOS 15, *)
extension BottomActionSheet {

    /// `item:` variant of the action-sheet modifier. Mirrors
    /// `IsPresentedModifier` but with `Item?` semantics; see its doc comment
    /// for the dismissal flow.
    ///
    /// Presentation is driven by `.fullScreenCover(isPresented:)` against a
    /// derived `coverItem != nil` bool rather than `.fullScreenCover(item:)`,
    /// so item identity changes while the cover is open update the rendered
    /// content in place without a system dismiss/re-present cycle.
    struct ItemModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
        @Binding var item: Item?
        let onDismiss: (() -> Void)?
        let sheetContent: (Item) -> SheetContent

        @State private var coverItem: Item? = nil
        @State private var presentationKey: Int = 0

        func body(content: Content) -> some View {
            content
                .fullScreenCover(isPresented: coverBridge, onDismiss: onDismiss) {
                    if let currentItem = coverItem {
                        Cover(
                            content: { sheetContent(currentItem) },
                            isPresented: itemPresented,
                            onCardExitComplete: dropCover
                        )
                        .id(presentationKey)
                    }
                }
                .backport.onChange(of: item?.id) { _, newId in
                    if newId == nil { return }
                    if coverItem == nil {
                        presentCover()
                    } else {
                        // Identity changed while the cover is already open.
                        // Cover is driven by `coverItem != nil` (not by item
                        // identity), so updating `coverItem` here re-renders
                        // the sheet content with the new item without the
                        // dismiss/re-present cycle .fullScreenCover(item:)
                        // would otherwise impose.
                        coverItem = item
                    }
                }
                .onAppear {
                    if item != nil, coverItem == nil { presentCover() }
                }
        }

        /// Bool binding handed to `.fullScreenCover`. The `get` reports
        /// whether we have a pending coverItem; any external set-to-false
        /// (e.g. `\.dismiss` from inside the cover content) is routed back
        /// through the consumer's `item` binding so the Cover's
        /// `.onChange(of: isPresented)` triggers the custom exit animation.
        private var coverBridge: Binding<Bool> {
            Binding(
                get: { coverItem != nil },
                set: { newValue in
                    if newValue == false { item = nil }
                }
            )
        }

        /// Bool binding handed into Cover so backdrop tap / drag / escape
        /// gestures can flip the consumer's `item` to nil, which then drives
        /// the exit animation through `Cover.onChange(of: isPresented)`.
        private var itemPresented: Binding<Bool> {
            Binding(
                get: { item != nil },
                set: { newValue in
                    if newValue == false { item = nil }
                }
            )
        }

        private func presentCover() {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { coverItem = item }
        }

        private func dropCover() {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            if item != nil {
                // Rapid-toggle: consumer re-set `item` to a non-nil value
                // while the exit animation was still running. Keep the
                // `.fullScreenCover` modal up and bump the Cover's identity
                // so SwiftUI replaces it with a fresh instance whose @State
                // is reset for the re-entry animation. Avoids the UIKit
                // dismiss/re-present cycle a `coverItem = nil` would
                // otherwise force.
                withTransaction(transaction) {
                    coverItem = item
                    presentationKey += 1
                }
            } else {
                // Normal case: consumer's `item` stayed nil; drop the modal.
                withTransaction(transaction) { coverItem = nil }
            }
        }
    }
}

#endif
