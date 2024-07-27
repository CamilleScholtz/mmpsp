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

    func applicationDidFinishLaunching(_: Notification) {
        configureStatusItem()
        configurePopover()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleIsPlayingDidChange),
            name: Notification.Name("IsPlayingDidChangeNotification"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocationDidChange),
            name: Notification.Name("LocationDidChangeNotification"),
            object: nil
        )
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

        setPopoverAnchorImage()
        setStatusItemTitle()
    }

    private func configurePopover() {
        popover.behavior = .semitransient
        popover.contentViewController = NSViewController()
        popover.contentViewController!.view = NSHostingView(
            rootView: PopoverView()
                .environment(player)
        )
    }

    private func setPopoverAnchorImage(_: Notification? = nil) {
        if player.status.isPlaying ?? false {
            popoverAnchor.button!.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "mmpsp")
        } else {
            popoverAnchor.button!.image = NSImage(systemSymbolName: "pause.fill", accessibilityDescription: "mmpsp")
        }
    }

    private func setStatusItemTitle(_: Notification? = nil) {
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

    @objc private func handleIsPlayingDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.setPopoverAnchorImage(notification)
        }
    }

    @objc private func handleLocationDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.setStatusItemTitle(notification)
        }
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
