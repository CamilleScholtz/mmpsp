//
//  AppDelegate.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 10/01/2021.
//

import KeyboardShortcuts
import SwiftUI

@main struct MusicPlayerPopupApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	var body: some Scene {
		Settings {
			EmptyView()
		}
	}
}

class AppDelegate: NSObject, NSApplicationDelegate {
	private(set) static var instance: AppDelegate!

	private var player = Player()

	private var statusItem: NSStatusItem!
	var popover = NSPopover()

	func applicationDidFinishLaunching(_ notification: Notification) {
		AppDelegate.instance = self

		KeyboardShortcuts.onKeyDown(for: .pausePlay) { [self] in player.pausePlay() }
		KeyboardShortcuts.onKeyDown(for: .backTrack) { [self] in player.backTrack() }
		KeyboardShortcuts.onKeyDown(for: .nextTrack) { [self] in player.nextTrack() }
		KeyboardShortcuts.onKeyDown(for: .rewind) { [self] in player.addToPosition(-5) }
		KeyboardShortcuts.onKeyDown(for: .fastForward) { [self] in player.addToPosition(5) }

		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
		statusItem.button?.action = #selector(buttonAction(_:))
		// TODO: `case .scrollWheel` doesn't work.
		statusItem.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])

		setStatusItemTitle(player.track?.description)

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
			player.updateProperties(all: true)

			// TODO: Always spawn on the right.
			popover.show(
				relativeTo: sender!.bounds,
				of: sender!,
				preferredEdge: .minY
			)
			popover.contentViewController?.view.window?.makeKey()
		}
	}
}
