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
    
    private var statusItem: NSStatusItem!
    var popover = NSPopover()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setStatusItemTitle),
            name: NSNotification.Name("TrackChanged"),
            object: nil)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.action = #selector(buttonAction(_:))
        // TODO: `case .scrollWheel` doesn't work.
        statusItem.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])
        
        self.setStatusItemTitle()
        
        popover.contentViewController = NSViewController()
        popover.contentViewController!.view = NSHostingView(
            rootView: PopoverView()
                .environmentObject(player)
        )
        popover.behavior = .transient
    }
    
    @objc func setStatusItemTitle() {
        statusItem?.button?.title = player.track?.description ?? "…"
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
    
    func togglePopover(_ sender: NSStatusBarButton?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            // TODO: Always spawn on the right.
            // https://github.com/Jaysce/Jukebox/issues/6
            popover.show(
                relativeTo: sender!.bounds,
                of: sender!,
                preferredEdge: .minY
            )
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
