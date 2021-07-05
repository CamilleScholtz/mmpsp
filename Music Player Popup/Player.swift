//
//  Player.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 13/01/2021.
//

import SwiftUI

final class Player: ObservableObject {
	// TODO: Defaults here?
	@Published var isPlaying = false
	@Published var playerPosition: CGFloat?
	@Published var isShuffle = false
	@Published var track: Track?

	init() {
		// Start a timer that repeats every second, updating our values.
		Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
			self.updateProperties(all: AppDelegate.instance.popover.isShown)
		})
	}

	private func isRunning() -> Bool {
		let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music")

		if apps.count >= 1 {
			return !apps[0].self.isTerminated
		}
		return false
	}

	private func updateProperty<T: Equatable>(_ variable: inout T, value: T) {
		if variable != value { variable = value }
	}
	
	private func resetProperties() {
		self.isPlaying = false
		self.track = nil
		self.playerPosition = 0
		
		AppDelegate.instance.setStatusItemTitle(nil)
	}

	func updateIsPlaying() {
		NSAppleScript.run(code: NSAppleScript.snippets.GetPlayerState.rawValue) { success, output, _ in
			guard success else { return }

			self.updateProperty(&self.isPlaying, value: output!.stringValue == "playing")
		}
	}
	
	func updatePlayerPosition() {
		NSAppleScript.run(code: NSAppleScript.snippets.GetPlayerPosition.rawValue) { success, output, _ in
			guard success else { return }
				
			var newPosition = Double(output!.stringValue ?? "0") ?? 0
			newPosition.round(.down)
			self.updateProperty(&self.playerPosition, value: CGFloat(newPosition))
		}
	}
	
	func updateIsShuffle() {
		NSAppleScript.run(code: NSAppleScript.snippets.GetIfShuffleIsEnabled.rawValue) { success, output, _ in
			guard success else { return }
				
			self.updateProperty(&self.isShuffle, value: output!.stringValue == "true")
		}
	}

	// TODO: Could probably be a little bit more elegant.
	func updateTrack(withArtwork: Bool) {
		NSAppleScript.run(code: NSAppleScript.snippets.GetTrackProperties.rawValue) { success, output, _ in
			guard success else { return }
			
			let newTrack = Track(fromList: output!.listItems())
			let isDifferent = self.track != newTrack

			if withArtwork {
				// TODO: Possible never ending loop with artworkless tracks.
				if isDifferent || self.track?.artwork == nil {
					NSAppleScript.run(code: NSAppleScript.snippets.GetArtwork.rawValue) { success, output, _ in
						guard success else {
							if isDifferent {
								self.track = newTrack
								AppDelegate.instance.setStatusItemTitle(self.track?.description)
							}
							
							return
						}
			
						let image = NSImage(data: output!.data)
						
						if isDifferent {
							newTrack?.artwork = image

							self.track = newTrack
							self.updateProperty(&self.playerPosition, value: 0)
							AppDelegate.instance.setStatusItemTitle(self.track?.description)
						} else {
							self.track?.artwork = image
						}
					}
				}
			} else {
				if isDifferent {
					self.track = newTrack
					AppDelegate.instance.setStatusItemTitle(self.track?.description)
				}
			}
		}
	}
	
	func updateIsLoved() {
		NSAppleScript.run(code: NSAppleScript.snippets.GetIfTrackIsLoved.rawValue) { success, output, _ in
			guard success && self.track != nil else { return }
				
			self.updateProperty(&self.track!.isLoved, value: output!.stringValue == "true")
		}
	}
	
	func updateProperties(all: Bool) {
		guard self.isRunning() else { return self.resetProperties() }
		
		if all {
			self.updateTrack(withArtwork: true)
			self.updateIsPlaying()
			self.updatePlayerPosition()
			self.updateIsShuffle()
			self.updateIsLoved()
		} else {
			self.updateTrack(withArtwork: false)
		}
	}

	func pausePlay() {
		NSAppleScript.run(code: NSAppleScript.snippets.PausePlay.rawValue, handler: { _, _, _ in })
		
		if AppDelegate.instance.popover.isShown {
			self.updateIsPlaying()
		}
	}

	func backTrack() {
		NSAppleScript.run(code: NSAppleScript.snippets.BackTrack.rawValue, handler: { _, _, _ in })
		
		if AppDelegate.instance.popover.isShown {
			self.updateTrack(withArtwork: true)
		} else {
			self.updateTrack(withArtwork: false)
		}
	}

	func nextTrack() {
		NSAppleScript.run(code: NSAppleScript.snippets.NextTrack.rawValue, handler: { _, _, _ in })
		
		if AppDelegate.instance.popover.isShown {
			self.updateTrack(withArtwork: true)
		} else {
			self.updateTrack(withArtwork: false)
		}
	}

	func setPosition(_ position: CGFloat) {
		NSAppleScript.run(code: NSAppleScript.snippets.SetPosition(position), handler: { _, _, _ in })
		
		if AppDelegate.instance.popover.isShown {
			self.updatePlayerPosition()
		}
	}

	func addToPosition(_ amount: CGFloat) {
		NSAppleScript.run(code: NSAppleScript.snippets.AddToPosition(amount), handler: { _, _, _ in })
		
		if AppDelegate.instance.popover.isShown {
			self.updatePlayerPosition()
		}
	}

	func setLoved(_ loved: Bool) {
		NSAppleScript.run(code: NSAppleScript.snippets.SetLoved(loved), handler: { _, _, _ in })
	
		if AppDelegate.instance.popover.isShown {
			self.updateIsLoved()
		}
	}
}
