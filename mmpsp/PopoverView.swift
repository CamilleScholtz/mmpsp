//
//  PopoverView.swift
//  mmpsp
//
//  Created by Camille Scholtz on 10/01/2021.
//

import SwiftUI

struct PopoverView: View {
    @Environment(Player.self) private var player

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
                .position(x: 15, y: 15)

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
            .offset(x: 20)
            .scaleEffect(x: 1.5)
        )
        .frame(width: 250, height: height)
        .onChange(of: player.popoverIsOpen) {
            guard player.popoverIsOpen else {
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
        .onChange(of: player.status.isPlaying ?? false) {
            showInfo = !(player.status.isPlaying ?? false) || isHovering
        }
        .onChange(of: player.song.location) {
            guard player.popoverIsOpen else {
                player.song.artwork = nil

                return
            }

            player.song.setArtwork()
        }
        .onChange(of: player.song.artwork) {
            guard player.song.artwork != nil else {
                return
            }

            updateHeight()
        }
        .onHover { value in
            if !value {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !isHovering {
                        showInfo = false || !(player.status.isPlaying ?? false)
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
    @Environment(Player.self) private var player

    var body: some View {
        Image(nsImage: player.song.artwork ?? NSImage())
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 250)
    }
}

struct Footer: View {
    @Environment(Player.self) private var player

    var body: some View {
        ZStack(alignment: .top) {
            Progress()

            VStack(spacing: 0) {
                Spacer()

                HStack(alignment: .center) {
                    Repeat()
                        .offset(x: 10)

                    Spacer()

                    HStack {
                        Previous()
                        Pause()
                        Next()
                    }

                    Spacer()

                    Random()
                        .offset(x: -10)
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
    @Environment(Player.self) private var player

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
    @Environment(Player.self) private var player

    @State private var hover = false
    @State private var transparency: Double = 0.0

    var body: some View {
        Image(systemName: (player.status.isPlaying ?? false ? "pause" : "play") + ".circle.fill")
            .font(.system(size: 35))
            .blendMode(.overlay)
            .scaleEffect(hover ? 1.2 : 1)
            .animation(.interactiveSpring(), value: hover)
            .onHover(perform: { value in
                hover = value
            })
            .onTapGesture(perform: {
                player.pause(player.status.isPlaying ?? false)
            })
    }
}

struct Previous: View {
    @Environment(Player.self) private var player

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
    @Environment(Player.self) private var player

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
    @Environment(Player.self) private var player

    @State private var hover = false

    var body: some View {
        Image(systemName: "shuffle")
            .foregroundColor(Color(player.status.isRandom ?? false ? .textBackgroundColor : .textColor))
            .blendMode(.overlay)
            .animation(.interactiveSpring(), value: player.status.isRandom ?? false)
            .padding(10)
            .scaleEffect(hover ? 1.2 : 1)
            .animation(.interactiveSpring(), value: hover)
            .onHover(perform: { value in
                hover = value
            })
            .onTapGesture(perform: {
                player.setRandom(!(player.status.isRandom ?? false))
            })
    }
}

struct Repeat: View {
    @Environment(Player.self) private var player

    @State private var hover = false

    var body: some View {
        Image(systemName: "repeat")
            .foregroundColor(Color(player.status.isRepeat ?? false ? .textBackgroundColor : .textColor))
            .blendMode(.overlay)
            .animation(.interactiveSpring(), value: player.status.isRepeat ?? false)
            .padding(10)
            .scaleEffect(hover ? 1.2 : 1)
            .animation(.interactiveSpring(), value: hover)
            .onHover(perform: { value in
                hover = value
            })
            .onTapGesture(perform: {
                player.setRepeat(!(player.status.isRepeat ?? false))
            })
    }
}

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
                NSApp.keyWindow?.contentViewController?.presentAsSheet(NSHostingController(rootView: SettingsView()))
            })
    }
}
