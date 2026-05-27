import SwiftUI

#if os(iOS)

/// Namespace for the bottom-action-sheet module.
///
/// The public API lives on `View` (see ``SwiftUI/View/bottomActionSheet(isPresented:onDismiss:content:)``
/// and ``SwiftUI/View/bottomActionSheet(item:onDismiss:content:)``); this enum
/// only holds the visual / interaction tunables shared between the two
/// modifiers and the cover view.
public enum BottomActionSheet {
    /// Default dim opacity behind the action-sheet card.
    public static let defaultBackdropOpacity: Double = 0.4
    /// Default horizontal/vertical padding around the action-sheet card.
    public static let defaultOuterPadding: CGFloat = 12
    /// Default present-animation curve.
    public static let defaultPresentAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.85)
    /// Default dismiss-animation curve.
    public static let defaultDismissAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.9)
    /// Reduce-motion fallback animation curve.
    public static let reduceMotionAnimation: Animation = .easeInOut(duration: 0.2)
    /// Drag distance (in points) at which a release dismisses the sheet.
    public static let defaultDragDismissThreshold: CGFloat = 100
    /// Minimum drag distance before the gesture begins, so taps still hit
    /// underlying buttons reliably.
    public static let defaultDragMinimumDistance: CGFloat = 20
}

#endif
