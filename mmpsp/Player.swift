//
//  Player.swift
//  mmpsp
//
//  Created by Camille Scholtz on 13/01/2021.
//

import Combine
import libmpdclient
import SwiftUI

@Observable final class Player {
    let status = Status()
    let song = Song()

    // TODO: Move popover specific logic to a superclass.
    var popoverIsOpen = false

    private let idleManager = ConnectionManager(idle: true)
    private let commandManager = ConnectionManager()

    private var isRunning = true
    private let retryConnectionInterval: UInt64 = 5 * 1_000_000_000

    private var cancellables = Set<AnyCancellable>()

    init() {
        status.idleManager = idleManager
        status.commandManager = commandManager
        song.idleManager = idleManager
        song.commandManager = commandManager

        startUpdateLoop()

        NotificationCenter.default.publisher(for: NSPopover.willShowNotification)
            .sink { [weak self] _ in self?.popoverIsOpening() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSPopover.didCloseNotification)
            .sink { [weak self] _ in self?.popoverIsClosing() }
            .store(in: &cancellables)
    }

    deinit {
        isRunning = false
    }

    private func startUpdateLoop() {
        Task {
            while isRunning {
                if !idleManager.isConnected {
                    if await idleManager.connect() {
                        try? await Task.sleep(nanoseconds: retryConnectionInterval)
                        continue
                    }
                }

                await MainActor.run {
                    self.status.set()
                    self.song.set()
                }

                if await idleManager.waitForIdle() {
                    await idleManager.disconnect()
                }
            }
        }
    }

    private func popoverIsOpening() {
        popoverIsOpen = true
        status.trackElapsed()
    }

    private func popoverIsClosing() {
        popoverIsOpen = false
        status.timer?.invalidate()
    }

    private func executeCommand(_ action: @Sendable @escaping (OpaquePointer) -> Void) {
        Task {
            await commandManager.execute(action)
        }
    }

    func pause(_ value: Bool) {
        executeCommand { connection in
            mpd_run_pause(connection, value)
        }
    }

    func previous() {
        executeCommand { connection in
            mpd_run_previous(connection)
        }
    }

    func next() {
        executeCommand { connection in
            mpd_run_next(connection)
        }
    }

    func seek(_ value: Double) {
        executeCommand { connection in
            mpd_run_seek_current(connection, Float(value), false)
        }
    }

    func setRandom(_ value: Bool) {
        executeCommand { connection in
            mpd_run_random(connection, value)
        }
    }

    func setRepeat(_ value: Bool) {
        executeCommand { connection in
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
    private let connectionQueue = DispatchQueue(label: "connection")

    init(idle: Bool = false) {
        self.idle = idle
    }

    deinit {
        Task.detached {
            await self.disconnect()
        }
    }

    func connect() async -> Bool {
        await disconnect()

        print("connect")

        return await withCheckedContinuation { continuation in
            connectionQueue.async {
                self.connection = mpd_connection_new(self.host, UInt32(self.port), 0)
                if mpd_connection_get_error(self.connection) != MPD_ERROR_SUCCESS {
                    self.connection = nil

                    continuation.resume(returning: false)
                } else {
                    self.isConnected = true
                    if self.idle {
                        mpd_connection_set_keepalive(self.connection, true)
                    }

                    continuation.resume(returning: true)
                }
            }
        }
    }

    func disconnect() async {
        print("disconnect")

        await withCheckedContinuation { continuation in
            connectionQueue.async {
                if let connection = self.connection {
                    mpd_connection_free(connection)

                    self.connection = nil
                    self.isConnected = false
                }

                continuation.resume()
            }
        }
    }

    func waitForIdle() async -> Bool {
        return await withCheckedContinuation { continuation in
            connectionQueue.async {
                guard let connection = self.connection else {
                    continuation.resume(returning: false)
                    return
                }

                let result = mpd_run_idle_mask(connection, mpd_idle(MPD_IDLE_PLAYER.rawValue | MPD_IDLE_OPTIONS.rawValue))

                continuation.resume(returning: result == mpd_idle(0))
            }
        }
    }

    func execute(_ action: @Sendable @escaping (OpaquePointer) -> Void) async {
        guard await connect() else {
            return
        }

        await withCheckedContinuation { continuation in
            connectionQueue.async {
                if let connection = self.connection {
                    action(connection)
                }

                continuation.resume()
            }
        }

        await disconnect()
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
            Task {
                await self.commandManager?.execute { connection in
                    guard let recv = mpd_run_status(connection) else {
                        return
                    }

                    self.update(&self.elapsed, value: Double(mpd_status_get_elapsed_time(recv)))

                    mpd_status_free(recv)
                }
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

        Task {
            await commandManager!.execute { connection in
                var imageData = Data()
                var offset: UInt32 = 0
                let bufferSize = 1024 * 1024
                var buffer = [UInt8](repeating: 0, count: bufferSize)

                while true {
                    let recv = mpd_run_readpicture(connection, self.location!, offset, &buffer, bufferSize)
                    if recv < 1 {
                        break
                    }

                    imageData.append(contentsOf: buffer[..<Int(recv)])
                    offset += UInt32(recv)
                }

                self.update(&self.artwork, value: NSImage(data: imageData))
            }
        }
    }
}
