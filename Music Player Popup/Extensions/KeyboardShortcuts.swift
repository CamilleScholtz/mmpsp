//
//  KeyboardShortcuts.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 29/06/2021.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let playPause = Self("playPause", default: .init(.space, modifiers: [.control]))
	static let backTrack = Self("backTrack", default: .init(.upArrow, modifiers: [.control]))
	static let nextTrack = Self("nextTrack", default: .init(.downArrow, modifiers: [.control]))
	static let seekBackward = Self("seekBackward", default: .init(.leftArrow, modifiers: [.control]))
	static let seekForeward = Self("seekForeward", default: .init(.rightArrow, modifiers: [.control]))
}
