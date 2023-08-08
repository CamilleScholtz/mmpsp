//
//  Player.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 13/01/2021.
//

import libmpdclient
import SwiftUI

class Player: ObservableObject {
    @NestedObservableObject var status = Status()
    @NestedObservableObject var song = Song()

    @Published var popoverIsOpen = false

    private var isRunning = true

    private var idle = ConnectionManager(idle: true)
    private var command = ConnectionManager()

    init() {
        status.idle = idle
        status.command = command
        song.idle = idle
        song.command = command

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

    private func startUpdateLoop() {
        DispatchQueue(label: "MPDUpdateQueue").async { [weak self] in
            guard let self = self else {
                return
            }

            while self.isRunning {
                DispatchQueue.main.sync {
                    self.status.set()
                    self.song.set()
                }

                if mpd_run_idle_mask(self.idle.connection, MPD_IDLE_PLAYER) == mpd_idle(0) {
                    self.idle.connect()
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
        command.execute { connection in
            mpd_run_pause(connection, value)
        }
    }

    func previous() {
        command.execute { connection in
            mpd_run_previous(connection)
        }
    }

    func next() {
        command.execute { connection in
            mpd_run_next(connection)
        }
    }

    func seek(_ value: Double) {
        command.execute { connection in
            mpd_run_seek_current(connection, Float(value), false)
        }
    }

    func random(_ value: Bool) {
        command.execute { connection in
            mpd_run_random(connection, value)
        }
    }

    func stop() {
        isRunning = false

        mpd_connection_free(idle.connection)
        mpd_connection_free(command.connection)
    }
}

class ConnectionManager {
    @AppStorage(Setting.host) var host = "localhost"
    @AppStorage(Setting.port) var port = 6600

    var connection: OpaquePointer?

    private var idle: Bool

    init(idle: Bool = false) {
        self.idle = idle

        if idle {
            connect()
        }
    }

    func connect() {
        if connection != nil {
            mpd_connection_free(connection)
        }

        connection = mpd_connection_new(host, UInt32(port), 0)
        if idle {
            mpd_connection_set_keepalive(connection, true)
        }
    }

    func execute(_ action: (OpaquePointer) -> Void) {
        connect()
        action(connection!)

        mpd_connection_free(connection)
        connection = nil
    }
}

class PlayerResponse: ObservableObject {
    var idle: ConnectionManager?
    var command: ConnectionManager?

    func update<T: Equatable>(_ variable: inout T, value: T?, notification: Notification.Name? = nil) {
        guard let value = value, variable != value else {
            return
        }

        variable = value

        if let notification = notification {
            NotificationCenter.default.post(
                name: notification,
                object: nil
            )
        }
    }
}

class Status: PlayerResponse {
    @Published var state: String?
    @Published var elapsed: Double?
    @Published var random: Bool?

    var timer: Timer?

    func set() {
        guard let recv = mpd_run_status(idle!.connection) else {
            return
        }

        update(&state, value: mpd_status_get_state(recv) == MPD_STATE_PLAY ? "play" : "pause")
        update(&elapsed, value: Double(mpd_status_get_elapsed_time(recv)))
        update(&random, value: mpd_status_get_random(recv))

        mpd_status_free(recv)
    }

    func trackElapsed() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.command!.execute { connection in
                guard let recv = mpd_run_status(connection) else {
                    return
                }

                self.update(&self.elapsed, value: Double(mpd_status_get_elapsed_time(recv)))

                mpd_status_free(recv)
            }
        }
    }
}

class Song: PlayerResponse {
    @Published var artist: String?
    @Published var title: String?
    @Published var location: String?
    @Published var duration: Double?
    @Published var artwork: NSImage?

    var description: String { return "\(artist ?? "Unknown artist") - \(title ?? "Unknown title")" }

    func set() {
        guard let recv = mpd_run_current_song(idle!.connection) else {
            return
        }

        update(&artist, value: String(cString: mpd_song_get_tag(recv, MPD_TAG_ARTIST, 0)))
        update(&title, value: String(cString: mpd_song_get_tag(recv, MPD_TAG_TITLE, 0)))
        update(&duration, value: Double(mpd_song_get_duration(recv)))
        update(&location, value: String(cString: mpd_song_get_uri(recv)), notification: Notification.Name("PlayerDidChangeNotification"))

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

        command!.execute { _ in
            while true {
                let recv = mpd_run_readpicture(command!.connection, location!, offset, &buffer, bufferSize)
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
