//
//  Player.swift
//  mmpsp
//
//  Created by Camille Scholtz on 13/01/2021.
//

import libmpdclient
import SwiftUI

@Observable final class Player {
    // TODO: Is @ObservationIgnored needed here?
    let status = Status()
    let song = Song()

    private let idleManager = ConnectionManager(idle: true)
    private let commandManager = ConnectionManager()

    private var updateLoopTask: Task<Void, Never>?

    @MainActor
    init() {
        status.idleManager = idleManager
        status.commandManager = commandManager
        song.idleManager = idleManager
        song.commandManager = commandManager

        updateLoopTask = Task { [weak self] in
            await self?.updateLoop()
        }
    }

    deinit {
        updateLoopTask?.cancel()
    }

    @MainActor
    private func updateLoop() async {
        while !Task.isCancelled {
            if await (!idleManager.isConnected) {
                await idleManager.connect()
                if await (!idleManager.isConnected) {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    continue
                }
            }

            await status.set()
            await song.set()

            let idleResult = await idleManager.runIdleMask(
                mask: mpd_idle(MPD_IDLE_PLAYER.rawValue | MPD_IDLE_OPTIONS.rawValue)
            )

            if idleResult == mpd_idle(0) {
                await idleManager.disconnect()
            }
        }
    }

    @MainActor
    func pause(_ value: Bool) async {
        await commandManager.runPause(value)
    }

    @MainActor
    func previous() async {
        await commandManager.runPrevious()
    }

    @MainActor
    func next() async {
        await commandManager.runNext()
    }

    @MainActor
    func seek(_ value: Double) async {
        await commandManager.runSeekCurrent(value)
        status.elapsed = value
    }

    @MainActor
    func setRandom(_ value: Bool) async {
        await commandManager.runRandom(value)
    }

    @MainActor
    func setRepeat(_ value: Bool) async {
        await commandManager.runRepeat(value)
    }
}

actor ConnectionManager {
    @AppStorage(Setting.host) var host = "localhost"
    @AppStorage(Setting.port) var port = 6600

    private var connection: OpaquePointer?
    private(set) var isConnected: Bool = false

    private var idle: Bool

    init(idle: Bool = false) {
        self.idle = idle
    }

    private func run(_ action: (OpaquePointer) -> Void) {
        connect()
        defer { disconnect() }

        guard let connection else {
            return
        }

        action(connection)
    }

    func connect() {
        disconnect()

        connection = mpd_connection_new(host, UInt32(port), 0)
        guard mpd_connection_get_error(connection) == MPD_ERROR_SUCCESS else {
            return
        }

        isConnected = true

        if idle {
            mpd_connection_set_keepalive(connection, true)
        }
    }

    func disconnect() {
        guard let connection else {
            return
        }

        mpd_connection_free(connection)
        self.connection = nil

        isConnected = false
    }

    func runPause(_ value: Bool) {
        run { connection in
            mpd_run_pause(connection, value)
        }
    }

    func runPrevious() {
        run { connection in
            mpd_run_previous(connection)
        }
    }

    func runNext() {
        run { connection in
            mpd_run_next(connection)
        }
    }

    func runSeekCurrent(_ value: Double) {
        run { connection in
            mpd_run_seek_current(connection, Float(value), false)
        }
    }

    func runRandom(_ value: Bool) {
        run { connection in
            mpd_run_random(connection, value)
        }
    }

    func runRepeat(_ value: Bool) {
        run { connection in
            mpd_run_repeat(connection, value)
        }
    }

    func runIdleMask(mask: mpd_idle) -> mpd_idle {
        guard let connection else {
            return mpd_idle(0)
        }
        return mpd_run_idle_mask(connection, mask)
    }

    func getStatusData() -> (playState: mpd_state?, isRandom: Bool?, isRepeat: Bool?, elapsed: Double?) {
        guard let connection, let recv = mpd_run_status(connection) else {
            return (nil, nil, nil, nil)
        }

        let playState = mpd_status_get_state(recv)
        let isRandom = mpd_status_get_random(recv)
        let isRepeat = mpd_status_get_repeat(recv)
        let elapsed = Double(mpd_status_get_elapsed_time(recv))

        mpd_status_free(recv)

        return (playState, isRandom, isRepeat, elapsed)
    }

    func getSongData() -> (artist: String?, title: String?, location: String?, duration: Double?) {
        guard let connection, let recv = mpd_run_current_song(connection) else {
            return (nil, nil, nil, nil)
        }

        var artist: String?
        if let tag = mpd_song_get_tag(recv, MPD_TAG_ARTIST, 0) {
            artist = String(cString: tag)
        }

        var title: String?
        if let tag = mpd_song_get_tag(recv, MPD_TAG_TITLE, 0) {
            title = String(cString: tag)
        }

        let duration = Double(mpd_song_get_duration(recv))
        let location = String(cString: mpd_song_get_uri(recv))

        mpd_song_free(recv)

        return (artist, title, location, duration)
    }

    func getElapsedData() -> Double? {
        connect()
        defer { disconnect() }

        guard let connection, let recv = mpd_run_status(connection) else {
            return nil
        }

        return Double(mpd_status_get_elapsed_time(recv))
    }

    func getArtworkData(location: String?) -> Data? {
        guard let location else {
            return nil
        }

        var imageData = Data()
        var offset: UInt32 = 0
        let bufferSize = 1024 * 1024
        var buffer = Data(count: bufferSize)

        connect()
        defer { disconnect() }

        while true {
            let recv = buffer.withUnsafeMutableBytes { bufferPtr in
                mpd_run_readpicture(connection, location, offset, bufferPtr.baseAddress, bufferSize)
            }
            guard recv > 0 else {
                break
            }

            imageData.append(buffer.prefix(Int(recv)))
            offset += UInt32(recv)
        }

        return imageData
    }
}

class PlayerResponse {
    @ObservationIgnored var idleManager: ConnectionManager?
    @ObservationIgnored var commandManager: ConnectionManager?

    // TODO: Is this actually an optimization or not?
    func update<T: Equatable>(_ variable: inout T?, value: T?) -> Bool {
        guard variable != value else {
            return false
        }

        variable = value
        return true
    }
}

@Observable class Status: PlayerResponse {
    var elapsed: Double?

    var playState: mpd_state?
    var isPlaying: Bool {
        playState == MPD_STATE_PLAY
    }

    var isRandom: Bool?
    var isRepeat: Bool?

    @ObservationIgnored var trackingTask: Task<Void, Never>?

    @MainActor
    func set() async {
        guard let data = await idleManager?.getStatusData() else {
            return
        }

        if update(&isPlaying, value: data.isPlaying) {
            AppDelegate.shared.setPopoverAnchorImage(changed: data.isPlaying ?? false ? "play" : "pause")
            AppDelegate.shared.setStatusItemTitle()
        }
        if update(&isRandom, value: data.isRandom) {
            AppDelegate.shared.setPopoverAnchorImage(changed: data.isRandom ?? false ? "random" : "sequential")
        }
        if update(&isRepeat, value: data.isRepeat) {
            AppDelegate.shared.setPopoverAnchorImage(changed: data.isRepeat ?? false ? "repeat" : "single")
        }
        elapsed = data.elapsed
    }

    @MainActor
    func trackElapsed() async {
        trackingTask?.cancel()

        trackingTask = Task { [weak self] in
            while !Task.isCancelled {
                if let elapsedData = await self?.commandManager?.getElapsedData() {
                    self?.elapsed = elapsedData
                }

                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
}

@Observable class Song: PlayerResponse {
    var artist: String?
    var title: String?
    var location: String?
    var duration: Double?
    var artwork: NSImage?

    var description: String { "\(artist ?? "Unknown artist") - \(title ?? "Unknown title")" }

    @MainActor
    func set() async {
        guard let data = await idleManager?.getSongData() else {
            return
        }

        _ = update(&artist, value: data.artist)
        _ = update(&title, value: data.title)
        _ = update(&duration, value: data.duration)
        if update(&location, value: data.location) {
            AppDelegate.shared.setStatusItemTitle()
        }
    }

    @MainActor
    func setArtwork() async {
        guard let data = await commandManager?.getArtworkData(location: location) else {
            return
        }

        // TODO: iS there is a more efficient way of doing this?
        // if new?.tiffRepresentation == artwork?.tiffRepresentation {
        //     return
        // }

        artwork = NSImage(data: data)
    }
}
