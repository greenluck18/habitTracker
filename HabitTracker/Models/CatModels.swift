//
//  CatModels.swift
//  HabitTracker
//

import Foundation

// MARK: - Cat State (derived from streak, never stored)

enum CatState: Equatable {
    case inBox      // streak 0: only ears visible above a box
    case peeking    // streak 1–2: head peeks above box
    case outOfBox   // streak 3–6: full cat body, box nearby
    case idle       // streak 7+: full cat, happy and settled

    init(streak: Int) {
        switch streak {
        case 0:     self = .inBox
        case 1..<3: self = .peeking
        case 3..<7: self = .outOfBox
        default:    self = .idle
        }
    }

    var label: String {
        switch self {
        case .inBox:    return "Peeking..."
        case .peeking:  return "Getting curious!"
        case .outOfBox: return "Out and about!"
        case .idle:     return "Living the life!"
        }
    }

    /// Whether the cat body (vs just ears) should be visible
    var showsBody: Bool {
        switch self {
        case .inBox, .peeking: return false
        case .outOfBox, .idle: return true
        }
    }
}

// MARK: - Cat Animation State

enum CatAnimationState: Equatable {
    case idle           // neutral resting
    case blinking       // eyes close briefly
    case waggingTail    // tail swings side to side
    case lookingLeft    // eyes/head shift left
    case lookingRight   // eyes/head shift right
    case happy          // jump + sparkles (all habits complete)
    case sleeping       // X eyes + zzz float (occasional)
}

// MARK: - Unlockable Milestones

enum CatMilestone: String, Codable, CaseIterable, Identifiable {
    case bowl   // day 7
    case ball   // day 14
    case bow    // day 21

    var id: String { rawValue }

    var requiredStreak: Int {
        switch self {
        case .bowl: return 7
        case .ball: return 14
        case .bow:  return 21
        }
    }

    var emoji: String {
        switch self {
        case .bowl: return "🍜"
        case .ball: return "⚽"
        case .bow:  return "🎀"
        }
    }

    var displayName: String {
        switch self {
        case .bowl: return "Food Bowl"
        case .ball: return "Toy Ball"
        case .bow:  return "Bow"
        }
    }

    /// Default normalized scene position (x: 0–1, y: 0–1) when tapped from inventory
    var defaultPosition: (x: Double, y: Double) {
        switch self {
        case .bowl: return (x: 0.22, y: 0.80)
        case .ball: return (x: 0.68, y: 0.74)
        case .bow:  return (x: 0.80, y: 0.28)
        }
    }
}

// MARK: - Placed Item

struct PlacedItem: Codable, Identifiable {
    let id: UUID
    let milestone: CatMilestone
    var normalizedX: Double   // 0–1 relative to scene width
    var normalizedY: Double   // 0–1 relative to scene height
}

// MARK: - Cat Profile (persisted)

struct CatProfile: Codable {
    var name: String = ""
    var placedItems: [PlacedItem] = []
}
