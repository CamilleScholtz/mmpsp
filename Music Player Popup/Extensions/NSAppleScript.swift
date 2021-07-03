//
//  NSAppleScript+MusicPlayerPopup.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 02/06/2021.
//

import SwiftUI

extension NSAppleScript {
	static func run(code: String, completionHandler: (Bool, NSAppleEventDescriptor?, NSDictionary?) -> Void) {
		var error: NSDictionary?
		let script = NSAppleScript(source: code)
		let output = script?.executeAndReturnError(&error)

		if let ou = output {
			completionHandler(true, ou, nil)
		}
		else {
			completionHandler(false, nil, error)
		}
	}
}

extension NSAppleScript {
	enum snippets: String {
		case GetCurrentPlayerState = """
		tell application "Music"
			if it is running then
				get player state as text
			end if
		end tell
		"""

		case GetCurrentPlayerPosition = """
		tell application "Music"
			if it is running then
				get player position
			end if
		end tell
		"""

		case GetCurrentTrackProperties = """
		tell application "Music"
			if it is running then
				get {artist, name, duration} of current track
			end if
		end tell
		"""

		case GetCurrentArtwork = """
		tell application "Music"
			get raw data of artwork 1 of current track
		end tell
		"""

		case GetIfCurrentTrackIsLoved = """
		tell application "Music"
			if it is running then
				get loved of current track
			end if
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
			if it is running then
				back track
			end if
		end tell
		"""

		case NextTrack = """
		tell application "Music"
			if it is running then
				next track
			end if
		end tell
		"""

		static func AddToPosition(_ amount: CGFloat) -> String {
			return """
			tell application "Music"
				if it is running then
					set player position to player position + \(amount)
				end if
			end tell
			"""
		}

		static func SetPosition(_ position: CGFloat) -> String {
			return """
			tell application "Music"
				if it is running then
					set player position to \(position)
				end if
			end tell
			"""
		}
		
		static func SetLoved(_ loved: Bool) -> String {
			return """
			tell application "Music"
				if it is running then
					set loved of current track to \(loved ? "true" : "false")
				end if
			end tell
			"""
		}
	}
}
