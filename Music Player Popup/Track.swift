//
//  Track.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 02/06/2021.
//

import SwiftUI

struct Track: CustomStringConvertible, Equatable {
	var artist: String?
	var name: String?
	var duration: Double
	var isLoved: Bool
	var artwork: NSImage?

	var description: String { return "\(artist ?? "Unknown artist") - \(name ?? "Unknown title")" }

	static func == (lhs: Track, rhs: Track) -> Bool {
		return lhs.description == rhs.description
	}
}
