//
//  HapticManager.swift
//  CallyFS
//

import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Haptic Types
    
    /// Light haptic for subtle feedback (button taps, navigation)
    func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Medium haptic for important actions (logging meals, FAB)
    func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Heavy haptic for significant actions (delete, confirmation)
    func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    /// Success haptic for completed actions
    func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Warning haptic for caution states
    func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    /// Error haptic for failed actions
    func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    /// Selection changed haptic for pickers, switches
    func selectionChanged() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    /// Custom haptic with intensity and sharpness
    func custom(intensity: CGFloat, sharpness: CGFloat) {
        if #available(iOS 13.0, *) {
            let impactFeedback = UIImpactFeedbackGenerator()
            impactFeedback.impactOccurred(intensity: intensity)
        } else {
            // Fallback to medium for older iOS versions
            medium()
        }
    }
}

// MARK: - Convenience Extensions

extension HapticManager {
    /// Haptic for FAB button tap
    func fabTap() {
        selectionChanged()
    }
    
    /// Haptic for meal logging
    func logMeal() {
        success()
    }
    
    /// Haptic for delete action
    func deleteItem() {
        heavy()
    }
    
    /// Haptic for settings navigation
    func settingsTap() {
        light()
    }
    
    /// Haptic for meal category selection
    func categorySelection() {
        selectionChanged()
    }
    
    /// Haptic for card appearance
    func cardAppear() {
        custom(intensity: 0.5, sharpness: 0.3)
    }
    
    /// Haptic for card dismissal
    func cardDismiss() {
        custom(intensity: 0.3, sharpness: 0.5)
    }
}
