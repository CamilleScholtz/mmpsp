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

    private var statusItemStub: NSStatusItem!
    private var statusItem: NSStatusItem!
    var popover = NSPopover()

    func applicationDidFinishLaunching(_: Notification) {
        configureStatusItem()
        configurePopover()
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button!.action = #selector(buttonAction(_:))
        statusItem.button!.sendAction(on: [.leftMouseDown, .rightMouseDown])

        statusItem.button!.postsFrameChangedNotifications = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayerDidChange(_:)),
            name: Notification.Name("PlayerDidChangeNotification"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFrameChanged(_:)),
            name: NSView.frameDidChangeNotification,
            object: statusItem.button
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTerminate(_:)),
            name: NSApplication.willTerminateNotification,
            object: nil
        )

        setStatusItemTitle()
    }

    private func configurePopover() {
        popover.contentViewController = NSViewController()
        popover.contentViewController!.view = NSHostingView(
            rootView: PopoverView()
                .environmentObject(player)
        )
        popover.behavior = .semitransient
    }

    private func setStatusItemTitle() {
        statusItem?.button?.title = player.song.description
    }

    private func togglePopover(_ sender: NSStatusBarButton?) {
        guard let sender = sender else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover(sender)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func showPopover(_ sender: NSStatusBarButton?, iteration: Int? = nil) {
        guard let sender = sender else {
            return
        }

        popover.show(
            relativeTo: NSRect(
                origin: NSPoint(x: sender.frame.origin.x + (sender.frame.width - 75), y: sender.frame.origin.y),
                size: sender.frame.size
            ),
            of: sender,
            preferredEdge: .maxY
        )

        // XXX: Little hack to make sure the popover is in the right position.
        if popover.isShown && iteration != nil && iteration! < 3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.showPopover(sender, iteration: iteration! + 1)
            }
        }
    }

    @objc private func handlePlayerDidChange(_: Notification) {
        setStatusItemTitle()
    }

    @objc func handleFrameChanged(_ notfication: Notification) {
        guard popover.isShown, let sender = notfication.object as? NSStatusBarButton else {
            return
        }

        showPopover(sender, iteration: 0)
    }

    @objc func handleTerminate(_: Notification) {
        popover.close()
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
