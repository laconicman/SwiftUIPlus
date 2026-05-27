import SwiftUI

@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
public extension View {

    /// Presents a bottom-anchored action-sheet card that always slides up from
    /// the bottom of the screen and sizes to its content, on every iOS device
    /// and size class.
    ///
    /// Apple has no equivalent built-in modifier; the closest replacements are
    /// `.confirmationDialog` (which renders as a popover on iPad regular size
    /// class) and `.sheet` + `.presentationDetents([.height(...)])`
    /// (iOS 16+, similarly popover-on-iPad). When `bottomActionSheet` matters
    /// to you, it's typically because those replacements don't.
    ///
    /// On iOS 16.4+, the underlying `.fullScreenCover` uses the native
    /// `.presentationBackground(.clear)` to drop its system background. On
    /// iOS 15-16.3, it goes through the SwiftUIBackports
    /// `Backport.presentationBackground(_:)` fallback.
    ///
    /// Dismissal: any of the following flips the `isPresented` binding to
    /// `false`, which triggers the custom card-exit animation before the
    /// underlying `.fullScreenCover` drops:
    ///
    /// - Setting the binding to `false` directly from consumer code.
    /// - Reading `@Environment(\.dismiss)` (iOS 15+) inside `content` and
    ///   calling it from a button.
    /// - Tapping the dim backdrop.
    /// - Swiping the card downwards.
    /// - Performing the VoiceOver Escape gesture (two-finger Z).
    /// - Pressing Escape on a hardware keyboard.
    ///
    /// The action sheet does not vend a system "Cancel" button — the consumer
    /// is responsible for providing one (or any other dismissal affordance) in
    /// `content`.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     to present the action sheet.
    ///   - onDismiss: The closure to execute when dismissing the action sheet.
    ///   - content: A view builder that defines the action sheet's content.
    @ViewBuilder
    @available(iOS, introduced: 15)
    func bottomActionSheet<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(iOS)
        modifier(BottomActionSheet.IsPresentedModifier(
            isPresented: isPresented,
            onDismiss: onDismiss,
            sheetContent: content
        ))
        #else
        self
        #endif
    }

    /// Presents a bottom-anchored action-sheet card using the given item as
    /// the source of truth, mirroring `View.sheet(item:onDismiss:content:)`.
    ///
    /// See ``bottomActionSheet(isPresented:onDismiss:content:)`` for details
    /// on visual presentation, accessibility, and dismissal model.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional source of truth for the action sheet.
    ///   - onDismiss: The closure to execute when dismissing the action sheet.
    ///   - content: A closure returning the content of the action sheet.
    @ViewBuilder
    @available(iOS, introduced: 15)
    func bottomActionSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        modifier(BottomActionSheet.ItemModifier(
            item: item,
            onDismiss: onDismiss,
            sheetContent: content
        ))
        #else
        self
        #endif
    }
}
