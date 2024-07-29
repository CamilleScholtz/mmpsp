//
//  AppDelegate.swift
//  mmpsp
//
//  Created by Camille Scholtz on 10/01/2021.
//

import SwiftUI

@main struct MusicPlayerPopupApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var player = Player()

    private var popoverAnchor: NSStatusItem!
    private var statusItem: NSStatusItem!
    var popover = NSPopover()

    private var changeImageWorkItem: DispatchWorkItem?

    func applicationDidFinishLaunching(_: Notification) {
        configureStatusItem()
        configurePopover()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    private func configureStatusItem() {
        popoverAnchor = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popoverAnchor.button!.action = #selector(buttonAction)
        popoverAnchor.button!.sendAction(on: [.leftMouseDown, .rightMouseDown, .scrollWheel])

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button!.action = #selector(buttonAction)
        statusItem.button!.sendAction(on: [.leftMouseDown, .rightMouseDown, .scrollWheel])

        withContinuousObservationTracking(of: self.player.song.location) { _ in
            self.setStatusItemTitle()
        }
    }

    private func configurePopover() {
        popover.behavior = .semitransient
        popover.contentViewController = NSViewController()
        popover.contentViewController!.view = NSHostingView(
            rootView: PopoverView()
                .environment(player)
        )

        withContinuousObservationTracking(of: self.player.status.isPlaying) { value in
            self.setPopoverAnchorImage(changed: (value ?? false) ? "play" : "pause")
        }
        withContinuousObservationTracking(of: self.player.status.isRandom) { value in
            self.setPopoverAnchorImage(changed: (value ?? false) ? "random" : "sequential")
        }
        withContinuousObservationTracking(of: self.player.status.isRepeat) { value in
            self.setPopoverAnchorImage(changed: (value ?? false) ? "repeat" : nil)
        }
    }

    private func setPopoverAnchorImage(changed: String? = nil) {
        switch changed {
        case "play":
            popoverAnchor.button!.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "play")
        case "pause":
            popoverAnchor.button!.image = NSImage(systemSymbolName: "pause.fill", accessibilityDescription: "pause")
        case "random":
            popoverAnchor.button!.image = NSImage(systemSymbolName: "shuffle", accessibilityDescription: "random")
        case "sequential":
            popoverAnchor.button!.image = NSImage(systemSymbolName: "arrow.up.arrow.down", accessibilityDescription: "sequential")
        case "repeat":
            popoverAnchor.button!.image = NSImage(systemSymbolName: "repeat", accessibilityDescription: "repeat")
        default:
            return popoverAnchor.button!.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "mmpsp")
        }

        changeImageWorkItem?.cancel()
        changeImageWorkItem = DispatchWorkItem {
            self.popoverAnchor.button!.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "mmpsp")
        }

        if let workItem = changeImageWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: workItem)
        }
    }

    private func setStatusItemTitle() {
        var description = player.song.description
        if description.count > 80 {
            description = String(description.prefix(80)) + "…"
        }

        statusItem!.button!.title = description
    }

    private func togglePopover(_ sender: NSStatusBarButton?) {
        guard let sender else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()

            // https://stackoverflow.com/a/73322639/14351818
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func showPopover() {
        popover.show(
            relativeTo: popoverAnchor.button!.bounds,
            of: popoverAnchor.button!,
            preferredEdge: .maxY
        )
    }

    @objc func handleTerminate(_: Notification) {
        popover.performClose(nil)
        NSApplication.shared.terminate(self)
    }

    @objc func buttonAction(_ sender: NSStatusBarButton?) {
        guard let event = NSApp.currentEvent else {
            return
        }

        // TODO: `case .scrollWheel` doesn't work.
        switch event.type {
        case .rightMouseDown:
            player.pause(player.status.isPlaying!)
        default:
            togglePopover(sender)
        }
    }
}
