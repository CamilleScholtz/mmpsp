//
//  PopoverView.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 10/01/2021.
//

import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var player: Player

    @State private var height = Double(250)
    @State private var isHovering = false
    @State private var showInfo = false
    @State private var cursorPosition: CGPoint = .zero
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Artwork()

            Artwork()
                .cornerRadius(10)
                .rotation3DEffect(
                    Angle(degrees: rotationX),
                    axis: (x: 1.0, y: 0.0, z: 0.0)
                )
                .rotation3DEffect(
                    Angle(degrees: rotationY),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
                .animation(.spring(), value: rotationX)
                .animation(.spring(), value: rotationY)
                .scaleEffect(showInfo ? 0.7 : 1)
                .offset(y: showInfo ? -7 : 0)
                .animation(.spring(response: 0.7, dampingFraction: 1, blendDuration: 0.7), value: showInfo)
                .shadow(color: .black.opacity(0.2), radius: 16)
                .background(.ultraThinMaterial)

            Gear()
                .scaleEffect(showInfo ? 1 : 0.7)
                .opacity(showInfo ? 1 : 0)
                .animation(.spring(), value: showInfo)
                .position(x: 235, y: 15)

            Footer()
                .frame(height: 80)
                .offset(y: showInfo ? 0 : 80)
                .animation(.spring(), value: showInfo)
        }
        .mask(
            RadialGradient(
                gradient: Gradient(colors: [.clear, .white]),
                center: .top,
                startRadius: 5,
                endRadius: 55
            )
            .scaleEffect(x: 1.5)
        )
        .frame(width: 250, height: height)
        .onChange(of: player.popoverIsOpen) { value in
            guard value else {
                return
            }

            player.song.setArtwork()

            var lastFireTime: DispatchTime = .now()
            let debounceInterval: TimeInterval = 0.2

            NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in
                let now = DispatchTime.now()

                guard now > lastFireTime + debounceInterval, isHovering else {
                    return event
                }

                var location = event.locationInWindow

                if event.window == nil {
                    guard let frame = NSApp.keyWindow?.frame else {
                        return event
                    }

                    location = CGPoint(
                        x: location.x - frame.origin.x,
                        y: location.y - frame.origin.y
                    )
                }

                let xPercentage = Double(location.x / 250)
                let yPercentage = Double(location.y / height)

                rotationX = (yPercentage - 0.5) * -16
                rotationY = (xPercentage - 0.5) * 16

                lastFireTime = now

                return event
            }
        }
        .onChange(of: player.status.state) { value in
            showInfo = value != "play" || isHovering
        }
        .onChange(of: player.song.location) { _ in
            guard player.popoverIsOpen else {
                return
            }

            player.song.setArtwork()
        }
        .onChange(of: player.song.artwork) { value in
            guard value != nil else {
                return
            }

            updateHeight()

            debugPrint("Updated height")
        }
        .onHover { value in
            if !value {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !isHovering {
                        showInfo = false || player.status.state != "play"
                    }
                }
            } else {
                showInfo = true
            }

            isHovering = value

            if !value {
                rotationX = 0
                rotationY = 0
            }
        }
    }

    private func updateHeight() {
        guard let artwork = player.song.artwork else {
            height = 250
            return
        }
        height = (Double(artwork.size.height) / Double(artwork.size.width) * 250).rounded(.down)
    }
}

struct Artwork: View {
    @EnvironmentObject var player: Player

    var body: some View {
        Image(nsImage: player.song.artwork ?? NSImage())
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 250)
    }
}

struct Footer: View {
    @EnvironmentObject var player: Player

    var body: some View {
        ZStack(alignment: .top) {
            Progress()

            VStack(spacing: 0) {
                Spacer()

                HStack(alignment: .center) {
                    Random()
                        .offset(x: 10)

                    Spacer()

                    HStack {
                        Previous()
                        Pause()
                        Next()
                    }

                    Spacer()

//                    Loved()
//                        .offset(x: -10)
                }

                Spacer()
            }
            .offset(y: 2)
        }
        .frame(height: 80)
        .background(.ultraThinMaterial)
    }
}

struct Progress: View {
    @EnvironmentObject var player: Player

    @State private var hover = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color(.textColor))
                    .frame(
                        width: (player.status.elapsed ?? 0) / (player.song.duration ?? 100) * 250,
                        height: hover ? 8 : 4
                    )
                    .blendMode(.softLight)
                    .animation(.spring(), value: player.status.elapsed)

                Rectangle()
                    .fill(Color(.textBackgroundColor))
                    .frame(
                        width: Double.maximum(0, 250 - ((player.status.elapsed ?? 0) / (player.song.duration ?? 100) * 250)),
                        height: hover ? 8 : 4
                    )
                    .blendMode(.softLight)
                    .animation(.spring(), value: player.status.elapsed)
            }
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                player.seek((value.location.x / 250) * (player.song.duration ?? 100))
            })

            HStack(alignment: .center) {
                Text(player.status.elapsed?.timeString ?? "-:--")
                    .font(.system(size: 10))
                    .blendMode(.overlay)
                    .offset(x: 5, y: 3)

                Spacer()

                Text(player.song.duration?.timeString ?? "-:--")
                    .font(.system(size: 10))
                    .blendMode(.overlay)
                    .offset(x: -5, y: 3)
            }
        }
        .animation(.interactiveSpring(), value: hover)
        .onHover(perform: { value in
            hover = value
        })
    }
}

struct Pause: View {
    @EnvironmentObject var player: Player

    @State private var hover = false
    @State private var transparency: Double = 0.0

    var body: some View {
        Image(systemName: (player.status.state ?? "pause") + ".circle.fill")
            .font(.system(size: 35))
            .blendMode(.overlay)
            .scaleEffect(hover ? 1.2 : 1)
            .animation(.interactiveSpring(), value: hover)
            .onHover(perform: { value in
                hover = value
            })
            .onTapGesture(perform: {
                player.pause(player.status.state == "play")
            })
    }
}

struct Previous: View {
    @EnvironmentObject var player: Player

    @State private var hover = false

    var body: some View {
        Image(systemName: "backward.fill")
            .blendMode(.overlay)
            .padding(10)
            .scaleEffect(hover ? 1.2 : 1)
            .animation(.interactiveSpring(), value: hover)
            .onHover(perform: { value in
                hover = value
            })
            .onTapGesture(perform: {
                player.previous()
            })
    }
}

struct Next: View {
    @EnvironmentObject var player: Player

    @State private var hover = false

    var body: some View {
        Image(systemName: "forward.fill")
            .blendMode(.overlay)
            .padding(10)
            .scaleEffect(hover ? 1.2 : 1)
            .animation(.interactiveSpring(), value: hover)
            .onHover(perform: { value in
                hover = value
            })
            .onTapGesture(perform: {
                player.next()
            })
    }
}

struct Random: View {
    @EnvironmentObject var player: Player

    @State private var hover = false

    var body: some View {
        Image(systemName: "shuffle")
            .foregroundColor(Color(player.status.random ?? false ? .textBackgroundColor : .textColor))
            .blendMode(.overlay)
            .animation(.interactiveSpring(), value: player.status.random ?? false)
            .padding(10)
            .scaleEffect(hover ? 1.2 : 1)
            .animation(.interactiveSpring(), value: hover)
            .onHover(perform: { value in
                hover = value
            })
            .onTapGesture(perform: {
                player.random(!(player.status.random ?? false))
            })
    }
}

// struct Loved: View {
//    @EnvironmentObject var player: Player
//
//    @State private var hover = false
//
//    var body: some View {
//        Image(systemName: player.track?.isLoved ?? false ? "heart.fill" : "heart")
//            .foregroundColor(Color(player.track?.isLoved ?? false ? .systemRed : .textColor))
//            .blendMode(player.track?.isLoved ?? false ? .multiply : .overlay)
//            .animation(.interactiveSpring(), value: player.track?.isLoved)
//            .padding(10)
//            .scaleEffect(player.track?.isLoved ?? false ? 1.1 : 1)
//            .scaleEffect(hover ? 1.2 : 1)
//            .animation(.interactiveSpring(), value: hover)
//            .animation(.easeInOut(duration: 0.2).delay(0.1).repeat(while: player.track?.isLoved ?? false), value: player.track?.isLoved)
//            .onHover(perform: { value in
//                hover = value
//            })
//            .onTapGesture(perform: {
//                player.setLoved(!(player.track?.isLoved ?? false))
//            })
//    }
// }

struct Gear: View {
    @State private var hover = false

    var body: some View {
        Image(systemName: "gear")
            .blendMode(.overlay)
            .padding(10)
            .scaleEffect(hover ? 1.2 : 1)
            .animation(.interactiveSpring(), value: hover)
            .onHover(perform: { value in
                hover = value
            })
            .onTapGesture(perform: {
                let settingsWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 250, height: 250),
                    styleMask: [.titled, .closable],
                    backing: .buffered, defer: false
                )

                let hostingController = NSHostingController(rootView: SettingsView())

                settingsWindow.contentViewController = hostingController
                settingsWindow.makeKeyAndOrderFront(nil)
                settingsWindow.center()
                settingsWindow.title = "Settings"
                NSApp.activate(ignoringOtherApps: true)
                NSApplication.shared.runModal(for: settingsWindow)
            })
    }
}
