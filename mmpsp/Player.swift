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
    @ObservationIgnored let status = Status()
    @ObservationIgnored let song = Song()

    // TODO: Move popover specific logic to a superclass.
    var popoverIsOpen = false

    private let idleManager = ConnectionManager(idle: true)
    private let commandManager = ConnectionManager()

    private var isRunning = true
    private let retryConnectionInterval: UInt32 = 5

    init() {
        status.idleManager = idleManager
        status.commandManager = commandManager
        song.idleManager = idleManager
        song.commandManager = commandManager

        startUpdateLoop()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(popoverIsOpening),
            name: NSPopover.willShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(popoverIsClosing),
            name: NSPopover.didCloseNotification,
            object: nil
        )
    }

    deinit {
        isRunning = false
    }

    private func startUpdateLoop() {
        DispatchQueue(label: "MPDIdleQueue").async { [weak self] in
            guard let self else {
                return
            }

            while isRunning {
                if !idleManager.isConnected {
                    idleManager.connect()
                    if !idleManager.isConnected {
                        sleep(retryConnectionInterval)
                    }
                }

                DispatchQueue.main.sync {
                    self.status.set()
                    self.song.set()
                }

                if mpd_run_idle_mask(idleManager.connection, mpd_idle(MPD_IDLE_PLAYER.rawValue | MPD_IDLE_OPTIONS.rawValue)) == mpd_idle(0) {
                    idleManager.disconnect()
                }
            }
        }
    }

    @objc func popoverIsOpening(_: NSNotification?) {
        popoverIsOpen = true
        status.trackElapsed()
    }

    @objc func popoverIsClosing(_: NSNotification?) {
        popoverIsOpen = false
        status.timer?.invalidate()
    }

    func pause(_ value: Bool) {
        commandManager.execute { connection in
            mpd_run_pause(connection, value)
        }
    }

    func previous() {
        commandManager.execute { connection in
            mpd_run_previous(connection)
        }
    }

    func next() {
        commandManager.execute { connection in
            mpd_run_next(connection)
        }
    }

    func seek(_ value: Double) {
        commandManager.execute { connection in
            mpd_run_seek_current(connection, Float(value), false)
        }
    }

    func setRandom(_ value: Bool) {
        commandManager.execute { connection in
            mpd_run_random(connection, value)
        }
    }

    func setRepeat(_ value: Bool) {
        commandManager.execute { connection in
            mpd_run_repeat(connection, value)
        }
    }
}

class ConnectionManager {
    @AppStorage(Setting.host) var host = "localhost"
    @AppStorage(Setting.port) var port = 6600

    var connection: OpaquePointer?
    var isConnected: Bool = false

    private var idle: Bool

    init(idle: Bool = false) {
        self.idle = idle
    }

    deinit {
        disconnect()
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
        guard connection != nil else {
            return
        }

        mpd_connection_free(connection)
        connection = nil

        isConnected = false
    }

    func execute(_ action: (OpaquePointer) -> Void) {
        connect()
        action(connection!)
        disconnect()
    }
}

class PlayerResponse {
    // TODO: Is @ObservationIgnored needed here?
    @ObservationIgnored var idleManager: ConnectionManager?
    @ObservationIgnored var commandManager: ConnectionManager?

    func update<T: Equatable>(_ variable: inout T?, value: T?) {
        guard variable != value else {
            return
        }

        variable = value
    }
}

@Observable class Status: PlayerResponse {
    var elapsed: Double?
    var isPlaying: Bool?
    var isRandom: Bool?
    var isRepeat: Bool?

    @ObservationIgnored var timer: Timer?

    func set() {
        guard let recv = mpd_run_status(idleManager!.connection) else {
            return
        }

        update(&elapsed, value: Double(mpd_status_get_elapsed_time(recv)))
        update(&isPlaying, value: mpd_status_get_state(recv) == MPD_STATE_PLAY)
        update(&isRandom, value: mpd_status_get_random(recv))
        update(&isRepeat, value: mpd_status_get_repeat(recv))

        mpd_status_free(recv)
    }

    func trackElapsed() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.commandManager!.execute { connection in
                guard let recv = mpd_run_status(connection) else {
                    return
                }

                self.update(&self.elapsed, value: Double(mpd_status_get_elapsed_time(recv)))

                mpd_status_free(recv)
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

    func set() {
        guard let recv = mpd_run_current_song(idleManager!.connection) else {
            return
        }

        if let tag = mpd_song_get_tag(recv, MPD_TAG_ARTIST, 0) {
            update(&artist, value: String(cString: tag))
        } else {
            update(&artist, value: nil)
        }
        if let tag = mpd_song_get_tag(recv, MPD_TAG_TITLE, 0) {
            update(&title, value: String(cString: tag))
        } else {
            update(&title, value: nil)
        }
        update(&duration, value: Double(mpd_song_get_duration(recv)))
        update(&location, value: String(cString: mpd_song_get_uri(recv)))

        mpd_song_free(recv)
    }

    func setArtwork() {
        guard location != nil else {
            return
        }

        var imageData = Data()
        var offset: UInt32 = 0
        let bufferSize = 1024 * 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        commandManager!.execute { connection in
            while true {
                let recv = mpd_run_readpicture(connection, location!, offset, &buffer, bufferSize)
                if recv < 1 {
                    break
                }

                imageData.append(contentsOf: buffer[..<Int(recv)])
                offset += UInt32(recv)
            }
        }

        update(&artwork, value: NSImage(data: imageData))
    }
}
