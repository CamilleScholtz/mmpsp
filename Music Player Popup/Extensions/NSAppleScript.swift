//
//  NSAppleScript+MusicPlayerPopup.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 02/06/2021.
//

import SwiftUI

extension NSAppleScript {
	static func run(code: String, handler: (Bool, NSAppleEventDescriptor?, NSDictionary?) -> Void) {
		var error: NSDictionary?
		let script = NSAppleScript(source: code)
		let output = script?.executeAndReturnError(&error)

		guard output != nil else {
			return handler(false, nil, error)
		}
		return handler(true, output, nil)
	}
}

extension NSAppleScript {
	enum snippets: String {
		case GetPlayerState = """
		tell application "Music"
			get player state as text
		end tell
		"""

		case GetPlayerPosition = """
		tell application "Music"
			get player position
		end tell
		"""

		case GetTrackProperties = """
		tell application "Music"
			get {artist, name, duration, loved} of current track
		end tell
		"""

		case GetIfTrackIsLoved = """
		tell application "Music"
			get loved of current track
		end tell
		"""

		case GetArtwork = """
		tell application "Music"
			get raw data of artwork 1 of current track
		end tell
		"""

		case GetShuffleInformation = """
		tell application "Music"
			get shuffle {mode, enabled}
		end tell
		"""

		case GetIfShuffleIsEnabled = """
		tell application "Music"
			get shuffle enabled
		end tell
		"""

		case PausePlay = """
		tell application "Music"
			if it is running then
				playpause
			else
				tell application "Music" to activate
			end if
		end tell
		"""

		case BackTrack = """
		tell application "Music"
			back track
		end tell
		"""

		case NextTrack = """
		tell application "Music"
			next track
		end tell
		"""

		static func SetPosition(_ position: CGFloat) -> String {
			return """
			tell application "Music"
				set player position to \(position)
			end tell
			"""
		}

		static func AddToPosition(_ amount: CGFloat) -> String {
			return """
			tell application "Music"
				set player position to player position + \(amount)
			end tell
			"""
		}

		static func SetLoved(_ loved: Bool) -> String {
			return """
			tell application "Music"
				set loved of current track to \(loved ? "true" : "false")
			end tell
			"""
		}
	}
}
