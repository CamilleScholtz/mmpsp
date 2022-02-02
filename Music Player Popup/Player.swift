//
//  Player.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 13/01/2021.
//

import SwiftUI
import ScriptingBridge

final class Player: ObservableObject {
	@Published var track: Track?
	@Published var isPlaying = false
	@Published var position: Double?
	@Published var isShuffle = false

    private var timer: Timer?
    private var bridge: MusicApplication? = SBApplication(bundleIdentifier: "com.apple.Music")
    private var isRunning: Bool {
        bridge?.isRunning ?? false
    }

	init() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(playerStateOrTrackDidChange),
            name: NSNotification.Name(rawValue: "com.apple.Music.playerInfo"),
            object: nil,
            suspensionBehavior: .deliverImmediately)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(popoverIsOpening),
            name: NSPopover.willShowNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(popoverIsClosing),
            name: NSPopover.didCloseNotification,
            object: nil)

        playerStateOrTrackDidChange(nil)
	}

    @objc func playerStateOrTrackDidChange(_ sender: NSNotification?) {
        guard isRunning, sender?.userInfo?["Player State"] as? String != "Stopped" else {
            resetProperties()

            // TODO: SHould I do this in DispatchQueue.main.async?
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TrackChanged"), object: track)
            
            return
        }

        // TODO: .artworks causes some albums to crash.
        let newTrack = Track(
            artist: bridge?.currentTrack?.artist,
            name: bridge?.currentTrack?.name,
            duration: bridge?.currentTrack?.duration ?? Double(0),
            isLoved: bridge?.currentTrack?.loved ?? false,
            artwork: (bridge?.currentTrack?.artworks?()[0] as! MusicArtwork).data)

        updateProperty(&track, value: newTrack)
        updateProperty(&isPlaying, value: bridge?.playerState == .playing)
 
        // TODO: SHould I do this in DispatchQueue.main.async?
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TrackChanged"), object: track)
    }

    @objc func popoverIsOpening(_ sender: NSNotification?) {
        position = bridge?.playerPosition

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.position = self.bridge?.playerPosition
        }
    }

    @objc func popoverIsClosing(_ sender: NSNotification?) {
        timer?.invalidate()
    }

	func playPause() {
        bridge?.playpause?()
	}

	func backTrack() {
        bridge?.backTrack?()
	}

	func nextTrack() {
        bridge?.nextTrack?()
	}

	func setPosition(_ to: Double) {
        bridge?.setPlayerPosition?(to)

        position = bridge?.playerPosition
	}

	func addToPosition(_ amount: Double) {
        bridge?.setPlayerPosition?(bridge?.playerPosition ?? 0 + amount)

        position = bridge?.playerPosition
	}

	func setShuffle(_ to: Bool) {
        bridge?.setShuffleEnabled?(to)

        isShuffle = to
	}

	func setLoved(_ to: Bool) {
        bridge?.currentTrack?.setLoved?(to)

        track?.isLoved = to
	}

	private func updateProperty<T: Equatable>(_ variable: inout T, value: T) {
		if variable != value { variable = value }
	}

	private func resetProperties() {
        track = nil
        isPlaying = false
        position = 0
    }
}
