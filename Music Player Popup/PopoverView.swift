//
//  PopoverView.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 10/01/2021.
//

import SwiftUI
import VisualEffects // TODO: Replace in next Swift version

// https://fivestars.blog/swiftui/swiftui-share-layout-information.html
struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue = CGFloat.infinity
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

struct PopoverView: View {
	@EnvironmentObject var player: Player

	@State private var height: CGFloat = 250
	@State private var hover = false
	@State private var timer: Timer?
	@State private var angle = false
	
    var body: some View {
		ZStack(alignment: .bottom) {
			Artwork()
				.background(
					GeometryReader { value in
						Color.clear
							.preference(
								key:   HeightPreferenceKey.self,
								value: value.size.height
							)
					}
				)
			
			Artwork()
				.cornerRadius(10)
				.rotationEffect(Angle(degrees: hover ? (angle ? -4 : 4) : 0))
				.animation(Animation.interpolatingSpring(stiffness: 5, damping: 1).repeat(while: hover))
				.scaleEffect(hover ? 0.7 : 1)
				.offset(y: hover ? -7 : 0)
				.animation(Animation.easeInOut(duration: 0.5), value: hover)
				.shadow(color: .black.opacity(0.2), radius: 10)
				.background(
					VisualEffectBlur(
						material: .hudWindow,
						blendingMode: .withinWindow,
						state: .active
					)
				)
			
			Footer(visible: $hover)
				.frame(height: 80)
				.offset(y: hover ? 0 : 80)
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
		.frame(maxWidth: 250, maxHeight: height)
		.animation(.interactiveSpring())
		.onPreferenceChange(HeightPreferenceKey.self, perform: { value in
            height = value
        })
		.onHover(perform: { value in
			if value {
				timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
					angle.toggle()
				}
				
				hover = true
				return
			} else {
				timer?.invalidate()
			}
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
				if !hover {
					return
				}
				hover = false
			}
		})
    }
}

struct Artwork: View {
	@EnvironmentObject var player: Player
	
    var body: some View {
		Image(nsImage: player.artwork ?? NSImage()) // TODO: placeholder
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 250)
    }
}

struct Footer: View {
	@EnvironmentObject var player: Player
	
	@Binding var visible: Bool
	
	var body: some View {
		VStack(spacing: 0) {
			Progress()
			
			HStack(alignment: .center) {
				Text(player.playerPosition?.timeString ?? "-:--")
					.font(.system(size: 10))
					.foregroundColor(Color(.textColor))
					.blendMode(.overlay)
					.offset(x: 5, y: 3)
				
				Spacer()
				
				Text(player.currentTrack?.duration.timeString ?? "-:--")
					.font(.system(size: 10))
					.foregroundColor(Color(.textColor))
					.blendMode(.overlay)
					.offset(x: -5, y: 3)
			}
			
			Spacer()
			
			HStack(alignment: .center) {
				Spacer()
				
				Back()
				PausePlay()
				Next()
				
				Spacer()
			}
			.offset(y: -7)
			
			Spacer()
		}
		.frame(height: 80)
		.background(
			VisualEffectBlur(
				material: .hudWindow,
				blendingMode: .withinWindow,
				state: .active
			)
		)
	}
}

struct Progress: View {
	@EnvironmentObject var player: Player

	@State private var hover = false
	
	var body: some View {
		HStack(spacing: 0) {
			Rectangle()
				.fill(Color(.textColor))
				.frame(
					width: (player.playerPosition ?? 0) / (player.currentTrack?.duration ?? 100) * 250,
					height: hover ? 8 : 4
				)
				.blendMode(.softLight)
			
			Rectangle()
				.fill(Color(.textBackgroundColor))
				.frame(
					width: CGFloat.maximum(0, (250 - ((player.playerPosition ?? 0) / (player.currentTrack?.duration ?? 100) * 250))),
					height: hover ? 8 : 4
				)
				.blendMode(.softLight)
		}
		.onHover(perform: { value in
			hover = value
		})
		.gesture(DragGesture(minimumDistance: 0).onChanged({ value in
			player.Seek((value.location.x / 250) * (player.currentTrack?.duration ?? 100))
		}))
	}
}

struct PausePlay: View {
	@EnvironmentObject var player: Player
	
	@State private var hover = false
	@State private var visible = false

    var body: some View {
		Image(systemName: (player.isPlaying ? "pause" : "play") + ".circle.fill")
			.font(.system(size: 35))
			.foregroundColor(Color( .textColor))
			.blendMode(.overlay)
			.scaleEffect(hover ? 1.2 : 1)
			.animation(.interactiveSpring())
			.onHover(perform: { value in
				hover = value
			})
			.onReceive(player.$isPlaying, perform: { value in
				if !value {
					visible = true
					return
				}

				DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
					if !player.isPlaying {
						return
					}
					visible = false
				}
			})
			.onTapGesture(perform: {
				player.pausePlay()
			})
		}
    }


struct Back: View {
	@EnvironmentObject var player: Player

	@State private var hover = false

	var body: some View {
		Image(systemName: "backward.fill")
			.foregroundColor(Color(.textColor))
			.blendMode(.overlay)
			.padding(10)
			.scaleEffect(hover ? 1.2 : 1)
			.animation(.interactiveSpring())
			.onHover(perform: { value in
				hover = value
			})
			.onTapGesture(perform: {
				player.backTrack()
			})
	}
}

struct Next: View {
	@EnvironmentObject var player: Player

	@State private var hover = false

	var body: some View {
		Image(systemName: "forward.fill")
			.foregroundColor(Color(.textColor))
			.blendMode(.overlay)
			.padding(10)
			.scaleEffect(hover ? 1.2 : 1)
			.animation(.interactiveSpring())
			.onHover(perform: { value in
				hover = value
			})
			.onTapGesture(perform: {
				player.nextTrack()
			})
	}
}
