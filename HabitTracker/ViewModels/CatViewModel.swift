//
//  CatViewModel.swift
//  HabitTracker
//

import Foundation
import SwiftUI

class CatViewModel: ObservableObject {
    @Published var profile: CatProfile
    @Published private(set) var effectiveStreak: Int = 0
    @Published var animationState: CatAnimationState = .idle
    @Published var catPositionX: Double = 0.5   // normalized 0–1, for ball-following
    @Published var showSparkles: Bool = false

    private let profileKey = "catProfile"
    private var idleTimer: Timer?
    private var previousWasComplete: Bool = false

    init() {
        self.profile = Self.loadProfile()
    }

    // MARK: - Refresh (called from HabitGridView on appear / history change)

    func refresh(streak: Int) {
        effectiveStreak = streak
        enforceItemLoss()
    }

    // MARK: - Computed

    var catState: CatState { CatState(streak: effectiveStreak) }

    var unlockedMilestones: [CatMilestone] {
        CatMilestone.allCases.filter { effectiveStreak >= $0.requiredStreak }
    }

    var needsName: Bool { profile.name.isEmpty }

    // MARK: - Name

    func setName(_ name: String) {
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        saveProfile()
    }

    // MARK: - Item Management

    func isPlaced(_ milestone: CatMilestone) -> Bool {
        profile.placedItems.contains { $0.milestone == milestone }
    }

    /// Tap-to-toggle: places at default position if not placed, removes if already placed.
    func toggleItem(_ milestone: CatMilestone) {
        if isPlaced(milestone) {
            removePlaced(milestone)
        } else {
            let pos = milestone.defaultPosition
            placeItem(milestone, normalizedX: pos.x, normalizedY: pos.y)
        }
    }

    func placeItem(_ milestone: CatMilestone, normalizedX: Double, normalizedY: Double) {
        profile.placedItems.removeAll { $0.milestone == milestone }
        profile.placedItems.append(
            PlacedItem(id: UUID(), milestone: milestone,
                       normalizedX: clamp(normalizedX), normalizedY: clamp(normalizedY))
        )
        saveProfile()
    }

    func removePlaced(_ milestone: CatMilestone) {
        profile.placedItems.removeAll { $0.milestone == milestone }
        saveProfile()
    }

    func moveItem(id: UUID, normalizedX: Double, normalizedY: Double) {
        guard let idx = profile.placedItems.firstIndex(where: { $0.id == id }) else { return }
        profile.placedItems[idx].normalizedX = clamp(normalizedX)
        profile.placedItems[idx].normalizedY = clamp(normalizedY)
        saveProfile()
    }

    // MARK: - Ball Throw (cat reacts)

    func ballThrown(toNormalizedX x: Double) {
        withAnimation(.spring(response: 1.2, dampingFraction: 0.75)) {
            catPositionX = max(0.15, min(0.85, x))
        }
    }

    // MARK: - Micro-reward

    func checkAllHabitsComplete(completed: Int, total: Int) {
        let isNowComplete = total > 0 && completed == total
        if isNowComplete && !previousWasComplete {
            triggerHappyAnimation()
        }
        previousWasComplete = isNowComplete
    }

    func triggerHappyAnimation() {
        guard animationState != .happy else { return }
        animationState = .happy
        showSparkles = true
        HabitTheme.Haptics.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.animationState = .idle
            self?.showSparkles = false
        }
    }

    // MARK: - Idle Timer

    func startIdleAnimations() {
        scheduleNextIdle()
    }

    func stopIdleAnimations() {
        idleTimer?.invalidate()
        idleTimer = nil
    }

    private func scheduleNextIdle() {
        idleTimer?.invalidate()
        let delay = Double.random(in: 4...9)
        idleTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { self?.triggerRandomIdle() }
        }
    }

    private func triggerRandomIdle() {
        guard animationState == .idle else { scheduleNextIdle(); return }
        // Sleeping is less common (2 in 10 chance)
        let choices: [CatAnimationState] = [
            .blinking, .waggingTail, .lookingLeft, .lookingRight,
            .blinking, .waggingTail, .lookingLeft, .lookingRight,
            .sleeping, .sleeping
        ]
        animationState = choices.randomElement()!
        let duration: Double = animationState == .sleeping ? 3.2 : 1.3
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.animationState = .idle
            self?.scheduleNextIdle()
        }
    }

    // MARK: - Failure Logic

    private func enforceItemLoss() {
        let lostKeys = Set(
            CatMilestone.allCases
                .filter { effectiveStreak < $0.requiredStreak }
                .map { $0.rawValue }
        )
        let before = profile.placedItems.count
        profile.placedItems.removeAll { lostKeys.contains($0.milestone.rawValue) }
        if profile.placedItems.count != before { saveProfile() }
    }

    // MARK: - Persistence

    private func saveProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    private static func loadProfile() -> CatProfile {
        guard let data = UserDefaults.standard.data(forKey: "catProfile"),
              let decoded = try? JSONDecoder().decode(CatProfile.self, from: data)
        else { return CatProfile() }
        return decoded
    }

    private func clamp(_ value: Double) -> Double {
        max(0.05, min(0.95, value))
    }
}
