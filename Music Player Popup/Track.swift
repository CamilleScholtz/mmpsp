//
//  Track.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 02/06/2021.
//

import SwiftUI

class Track: CustomStringConvertible, Equatable {
	let artist: String
	let name: String
	let duration: CGFloat

	var isLoved: Bool
	var artwork: NSImage?

	var description: String { return "\(artist) - \(name)" }

	init(artist: String, name: String, duration: CGFloat, isLoved: Bool, artwork: NSImage?) {
		self.artist = artist
		self.name = name
		self.duration = duration
		self.isLoved = isLoved
		self.artwork = nil
	}

	convenience init?(fromList list: [Int: String]) {
		self.init(
			artist: list[1] ?? "-",
			name: list[2] ?? "-",
			duration: CGFloat(Double(list[3] ?? "0") ?? 0),
			isLoved: list[4] == "true",
			artwork: nil
		)
	}

	static func == (lhs: Track, rhs: Track) -> Bool {
		return lhs.description == rhs.description
	}
}
