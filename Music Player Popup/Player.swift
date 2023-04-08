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
    @Published var popoverIsOpen = false
    
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
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TrackChanged"), object: self.track)
            }
            
            return
        }
        
        guard let currentTrack = bridge?.currentTrack else { return }
        updateProperty(&track, value: Track(
            artist: currentTrack.artist,
            name: currentTrack.name,
            duration: currentTrack.duration ?? Double(0),
            isLoved: currentTrack.loved ?? false,
            artwork: (currentTrack.artworks?().firstObject as? MusicArtwork)?.data))
        updateProperty(&isPlaying, value: bridge?.playerState == .playing)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TrackChanged"), object: self.track)
        }
    }
    
    @objc func popoverIsOpening(_ sender: NSNotification?) {
        position = bridge?.playerPosition
        popoverIsOpen = true
        
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
