//
//  TopShelfConfiguration.swift
//  LumeShared
//
//  How the tvOS Top Shelf presents the snapshot: whether it shows at all, the
//  layout, which sections appear in what order, and how many items each holds.
//  The app owns the user's choice (`TopShelfSettings`) and writes it into the
//  snapshot; the Top Shelf extension only reads it.
//

import Foundation

nonisolated struct TopShelfConfiguration: Codable, Equatable {
    /// A Top Shelf section. The raw value is the stored key, so cases must not
    /// be renamed once shipped.
    nonisolated enum Section: String, Codable, CaseIterable {
        case continueWatching
        case onNow
        case favorites
    }

    /// `sectioned` is rows of posters under section titles; `carousel` is the
    /// full-width, auto-advancing backdrop carousel.
    nonisolated enum Style: String, Codable, CaseIterable {
        case sectioned
        case carousel
    }

    /// When off, the extension hands tvOS no content and it shows the app's
    /// static Top Shelf image.
    var isEnabled: Bool
    var style: Style
    /// The sections to show, top to bottom (left to right in the carousel).
    /// A section missing from the list is switched off.
    var sections: [Section]
    var itemsPerSection: Int

    /// The choices offered for `itemsPerSection`.
    static let itemCountChoices = [5, 10, 20]

    /// The most items the snapshot carries per section — the largest choice.
    static var maxItemsPerSection: Int {
        itemCountChoices.max() ?? 20
    }

    static let `default` = TopShelfConfiguration(
        isEnabled: true,
        style: .sectioned,
        sections: Section.allCases,
        itemsPerSection: 10
    )
}
