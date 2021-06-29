//
//  Player.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 13/01/2021.
//

import SwiftUI

class Player: ObservableObject {
	@Published var isPlaying: Bool = false
	@Published var currentTrack: Track?
	@Published var playerPosition: CGFloat?
	@Published var artwork: NSImage?
	
	private var isRunning: Bool {
		let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music")

		if apps.count >= 1 {
			return !apps[0].self.isTerminated
		}
		return false
	}
	
    init() {
		Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
			self.update()
		})
    }
	
	private func updateVar<T: Equatable>(_ variable: inout T, value: T) -> Bool {
		if variable != value {
			variable = value
			return true
		}
		return false
	}
	
	func update() {
		NSAppleScript.run(code: NSAppleScript.snippets.GetCurrentTrackProperties.rawValue) { (success, output, errors) in
			if success {
				if (self.updateVar(&self.currentTrack, value: Track(fromList: output!.listItems()))) {
					_ = self.updateVar(&self.playerPosition, value: CGFloat(0))
					
					AppDelegate.instance.setStatusItemTitle(self.currentTrack?.description)
					
					// TODO: Preferrably I'd run this only if the popover is show, however, this makes it so that album art only
					// gets fetched when the popover is open, could cause a slow user experience.
					NSAppleScript.run(code: NSAppleScript.snippets.GetCurrentArtwork.rawValue) { (success, output, errors) in
						if success {
							_ = self.updateVar(&self.artwork, value: NSImage(data: output!.data))
						} else {
							self.artwork = nil
						}
					}
				}
				
				if AppDelegate.instance.popover.isShown {
					NSAppleScript.run(code: NSAppleScript.snippets.GetCurrentPlayerState.rawValue) { (success, output, errors) in
						if success {
							_ = self.updateVar(&self.isPlaying, value: (output!.stringValue == "playing"))
						}
					}
					
					NSAppleScript.run(code: NSAppleScript.snippets.GetCurrentPlayerPosition.rawValue) { (success, output, errors) in
						if success {
							var newPosition = Double(output!.stringValue ?? "0") ?? 0
							newPosition.round(.down)
							
							_ = self.updateVar(&self.playerPosition, value: CGFloat(newPosition))
						}
					}
				}
			} else {
				if (self.currentTrack != nil) {
					self.currentTrack = nil
					self.artwork = nil
				
					AppDelegate.instance.setStatusItemTitle(nil)
				}
			}
		}
	}
	
	func pausePlay() {
		NSAppleScript.run(code: NSAppleScript.snippets.PausePlay.rawValue, completionHandler: {_,_,_ in })
		self.update()
	}
	
	func backTrack() {
		NSAppleScript.run(code: NSAppleScript.snippets.BackTrack.rawValue, completionHandler: {_,_,_ in })
		self.update()
	}

	func nextTrack() {
		NSAppleScript.run(code: NSAppleScript.snippets.NextTrack.rawValue, completionHandler: {_,_,_ in })
		self.update()
	}

	func Seek(_ to: CGFloat) {
		NSAppleScript.run(code: NSAppleScript.snippets.Seek(to), completionHandler: {_,_,_ in })
		self.update()
	}
}
