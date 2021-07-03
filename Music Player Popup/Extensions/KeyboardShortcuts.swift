//
//  KeyboardShortcuts.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 29/06/2021.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let pausePlay = Self("pausePlay", default: .init(.space, modifiers: [.control]))
	static let backTrack = Self("backTrack", default: .init(.upArrow, modifiers: [.control]))
	static let nextTrack = Self("nextTrack", default: .init(.downArrow, modifiers: [.control]))
	static let rewind = Self("rewind", default: .init(.leftArrow, modifiers: [.control]))
	static let fastForward = Self("fastForward", default: .init(.rightArrow, modifiers: [.control]))
}
