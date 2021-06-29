//
//  AppDelegate.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 10/01/2021.
//

import Foundation
import KeyboardShortcuts
import SwiftUI

extension KeyboardShortcuts.Name {
	static let pausePlay = Self("pausePlay", default: .init(.space, modifiers: [.control]))
	static let backTrack = Self("backTrack", default: .init(.upArrow, modifiers: [.control]))
	static let nextTrack = Self("nextTrack", default: .init(.downArrow, modifiers: [.control]))
	static let rewind = Self("rewind", default: .init(.leftArrow, modifiers: [.control]))
	static let fastForward = Self("fastForward", default: .init(.rightArrow, modifiers: [.control]))
}

@main struct MusicPlayerPopupApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
		Settings {
			EmptyView()
		}
    }
}
    
class AppDelegate: NSObject, NSApplicationDelegate {
	static private(set) var instance: AppDelegate! = nil
	
	private var player = Player()

    private var statusItem: NSStatusItem!
	var popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
		AppDelegate.instance = self

		KeyboardShortcuts.onKeyDown(for: .pausePlay) { [self] in player.pausePlay()}
		KeyboardShortcuts.onKeyDown(for: .backTrack) { [self] in player.backTrack()}
		KeyboardShortcuts.onKeyDown(for: .nextTrack) { [self] in player.nextTrack()}
		KeyboardShortcuts.onKeyDown(for: .rewind) { [self] in player.Seek(-5)}
		KeyboardShortcuts.onKeyDown(for: .fastForward) { [self] in player.Seek(5)}
		
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.action = #selector(buttonAction(_:))
        statusItem.button?.sendAction(on: [.leftMouseDown, .rightMouseDown, .scrollWheel])
        // XXX: Image is not really aligned with the text.
        //statusItem.button?.imagePosition = .imageLeading

		setStatusItemTitle(player.currentTrack?.description)
		
        popover.contentViewController = NSViewController()
        popover.contentViewController!.view = NSHostingView(
			rootView: PopoverView()
				.environmentObject(player)
		)
 		popover.behavior = .transient
    }

	func setStatusItemTitle(_ title: String?) {
		statusItem?.button?.title = title ?? "…"
	}
	
    @objc func buttonAction(_ sender: NSStatusBarButton?) {
        guard let event = NSApp.currentEvent else {
            return
        }

		// TODO: `case .scrollWheel` doesn't work.
        switch event.type {
        case .rightMouseDown:
            player.pausePlay()
        default:
            togglePopover(sender)
        }
    }

    func togglePopover(_ sender: NSStatusBarButton?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(
                relativeTo: sender!.bounds,
                of: sender!,
                preferredEdge: .minY
            )
			popover.contentViewController?.view.window?.makeKey()
        }
	}
}
