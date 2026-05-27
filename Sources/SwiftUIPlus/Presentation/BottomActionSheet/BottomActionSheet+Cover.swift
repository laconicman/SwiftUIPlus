import SwiftUI
import SwiftUIBackports

#if os(iOS)

@available(iOS 15, *)
extension BottomActionSheet {

    /// Shared cover content: dim backdrop + bottom-anchored card with
    /// spring-driven entry, drag-to-dismiss, and reduce-motion fallback.
    struct Cover<SheetContent: View>: View {
        let content: () -> SheetContent
        @Binding var isPresented: Bool
        let onCardExitComplete: () -> Void

        @State private var isVisible: Bool = false
        @State private var dragTranslation: CGFloat = 0
        @State private var isAnimatingExit: Bool = false
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    backdrop
                    card
                        .offset(y: cardOffset(within: proxy))
                }
            }
            .backport.presentationBackground(.clear)
            .task {
                withAnimation(presentAnimation) { isVisible = true }
            }
            .backport.onChange(of: isPresented) { _, newValue in
                // The consumer's binding became false — from any path:
                // their own code, `\.dismiss`, backdrop tap, drag-to-dismiss,
                // VoiceOver escape, hardware Escape. Play the exit animation
                // and let the outer modifier drop the cover when it settles.
                if newValue == false { animateExit() }
            }
        }

        private var backdrop: some View {
            // The card below carries .accessibilityAddTraits(.isModal), which
            // restricts VoiceOver to card content only — so any backdrop-level
            // accessibility traits / actions would be unreachable. VoiceOver
            // dismissal goes through .accessibilityAction(.escape) on the card.
            Color.black
                .opacity(isVisible ? BottomActionSheet.defaultBackdropOpacity : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }
        }

        private var card: some View {
            content()
                .padding(.horizontal, BottomActionSheet.defaultOuterPadding)
                .padding(.bottom, BottomActionSheet.defaultOuterPadding)
                .opacity(reduceMotion ? (isVisible ? 1 : 0) : 1)
                .accessibilityAddTraits(.isModal)
                .accessibilityAction(.escape) { dismiss() }
                .simultaneousGesture(
                    DragGesture(minimumDistance: BottomActionSheet.defaultDragMinimumDistance)
                        .onChanged { value in
                            // Track downward drag only; upward drags don't
                            // make a card-dismiss gesture meaningful here.
                            dragTranslation = max(0, value.translation.height)
                        }
                        .onEnded { value in
                            let translation = value.translation.height
                            let predicted = value.predictedEndTranslation.height
                            let threshold = BottomActionSheet.defaultDragDismissThreshold
                            if translation > threshold || predicted > threshold * 2 {
                                dismiss()
                            } else {
                                // Snap back to the resting position with an
                                // animation so the card doesn't jump.
                                withAnimation(presentAnimation) {
                                    dragTranslation = 0
                                }
                            }
                        }
                )
        }

        /// Computes the card's vertical offset for the current state.
        ///
        /// - Reduce Motion: card stays at its resting position; entry/exit is
        ///   conveyed by an opacity cross-fade instead.
        /// - Default: when hidden, the card sits just below the cover's bottom
        ///   edge (using the GeometryReader-supplied height) so the spring has
        ///   a meaningful starting point that adapts to the device size. When
        ///   visible, the offset tracks any in-progress drag.
        private func cardOffset(within proxy: GeometryProxy) -> CGFloat {
            if reduceMotion {
                return 0
            }
            if isVisible == false {
                return proxy.size.height
            }
            return max(0, dragTranslation)
        }

        private var presentAnimation: Animation {
            reduceMotion ? BottomActionSheet.reduceMotionAnimation : BottomActionSheet.defaultPresentAnimation
        }

        private var dismissAnimation: Animation {
            reduceMotion ? BottomActionSheet.reduceMotionAnimation : BottomActionSheet.defaultDismissAnimation
        }

        /// Single user-initiated dismiss path. Flips the consumer's binding to
        /// `false`; `.onChange(of: isPresented)` above sees the change and
        /// drives the exit animation. Funnelling through the same binding
        /// means every dismissal source (consumer code, `\.dismiss`, backdrop
        /// tap, drag, escape gestures) gets the same animation treatment.
        private func dismiss() {
            guard !isAnimatingExit else { return }
            isPresented = false
        }

        /// Animate the card off-screen, then ask the outer modifier to drop
        /// the cover.
        ///
        /// SwiftUI's `withAnimation` commits its driving state changes into a
        /// CATransaction, so the `setCompletionBlock` fires once the animation
        /// actually settles — which avoids the need for a magic-number
        /// `asyncAfter` that has to be kept in sync with the spring response.
        /// This sequencing relies on an undocumented SwiftUI behaviour; see
        /// the BottomActionSheet entry in `TECH_DEBT.md`.
        private func animateExit() {
            guard !isAnimatingExit else { return }
            isAnimatingExit = true
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                onCardExitComplete()
            }
            withAnimation(dismissAnimation) {
                isVisible = false
                // Reset any in-progress drag so the card animates from its
                // current visual position to off-screen rather than jumping
                // back to the drag offset before sliding out.
                dragTranslation = 0
            }
            CATransaction.commit()
        }
    }
}

#endif
