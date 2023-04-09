//
//  AppDelegate.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 10/01/2021.
//

import SwiftUI
import LaunchAtLogin

@main struct MusicPlayerPopupApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    // TODO: Move this?
    private var player = Player()
    
    private var statusItemStub: NSStatusItem!
    private var statusItem: NSStatusItem!
    var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTrackChanged),
            name: NSNotification.Name("TrackChanged"),
            object: nil)
        
        configureStatusItem()
        configurePopover()
    }
    
    private func configureStatusItem() {
        statusItemStub = NSStatusBar.system.statusItem(withLength: 1)
        statusItemStub.button?.action = #selector(buttonAction(_:))
        statusItemStub.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.action = #selector(buttonAction(_:))
        statusItem.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])
        
        statusItem.button?.postsFrameChangedNotifications = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFrameChanged(_:)),
            name: NSView.frameDidChangeNotification,
            object: statusItem.button)
        
        setStatusItemTitle()
    }
    
    private func configurePopover() {
        popover.contentViewController = NSViewController()
        popover.contentViewController!.view = NSHostingView(
            rootView: PopoverView()
                .environmentObject(player)
        )
        popover.behavior = .transient
        popover.behavior = .transient
    }
    
    private func setStatusItemTitle() {
        statusItem?.button?.title = player.track?.description ?? "…"
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
    
    private func showPopover(_ sender: NSStatusBarButton?) {
        guard let sender = sender else {
            return
        }
        
        let positioningRect = NSRect(
            origin: NSPoint(x: sender.frame.origin.x + (sender.frame.width - 75), y: sender.frame.origin.y),
            size: sender.frame.size
        )
        
        if popover.isShown {
            popover.positioningRect = positioningRect
        } else {
            popover.show(
                relativeTo: positioningRect,
                of: sender,
                preferredEdge: .maxY
            )
        }
    }
    
    @objc func handleTrackChanged() {
        setStatusItemTitle()
    }
    
    @objc func handleFrameChanged(_ notfication: Notification) {
        guard popover.isShown, let sender = notfication.object as? NSStatusBarButton else {
            return
        }
        
        showPopover(sender)
    }
    
    @objc func buttonAction(_ sender: NSStatusBarButton?) {
        guard let event = NSApp.currentEvent else {
            return
        }
        
        // TODO: `case .scrollWheel` doesn't work.
        switch event.type {
        case .rightMouseDown:
            player.playPause()
        default:
            togglePopover(sender)
        }
    }
}
