//
//  PopoverView.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 10/01/2021.
//

import SwiftUI

struct PopoverView: View {
	@EnvironmentObject var player: Player

	@State private var height = CGFloat(250)
	@State private var hover = false
	@State private var info = false
	@State private var infoDelay = false
	@State private var angle = CGFloat(-4)
	@State private var timer: Timer?
	
	var body: some View {
		ZStack(alignment: .bottom) {
			Artwork()

			Artwork()
				.cornerRadius(10)
				.rotationEffect(Angle(degrees: info ? angle : 0))
				.animation(Animation.easeInOut(duration: 4), value: infoDelay)
				.animation(Animation.easeInOut(duration: 4), value: angle)
				.scaleEffect(info ? 0.7 : 1)
				.offset(y: info ? -7 : 0)
				.animation(Animation.easeInOut(duration: 0.5), value: info)
				.shadow(color: .black.opacity(0.2), radius: 10)
				.background(.ultraThinMaterial)

			Footer()
				.frame(height: 80)
				.offset(y: infoDelay ? 0 : 80)
				.animation(Animation.interactiveSpring(), value: infoDelay)
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
		.onAppear(perform: {
			// TODO: Can I merge this with the onChange call below?
			// TODO: maybe I should round to nearest?
			height = (player.artwork!.size.height / player.artwork!.size.width * 250).rounded(.down)
		})
		.onChange(of: player.artwork!, perform: { value in
			// TODO: maybe I should round to nearest?
			height = (value.size.height / value.size.width * 250).rounded(.down)
		})
		.onChange(of: player.isPlaying, perform: { value in
			if hover {
				return
			}
			
			info = !value

			if !value {
				infoDelay = true
			} else {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					if !info {
						infoDelay = false
					}
				}
			}
		})
		.onHover(perform: { value in
			hover = value

			if !player.isPlaying {
				return
			}
			
			info = value
			
			if value {
				infoDelay = true
			} else {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					if !info {
						infoDelay = false
					}
				}
			}
		})
		.onChange(of: infoDelay, perform: { value in
			if value {
				timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { timer in
					angle = -angle
				}
			} else {
				timer?.invalidate()
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

	var body: some View {
		ZStack(alignment: .top) {
			Progress()

			VStack(spacing: 0) {
				Spacer()

				HStack(alignment: .center) {
					Spacer()
					Spacer()
					Spacer()

					HStack {
						Back()
						PausePlay()
						Next()
					}
					
					Spacer()
					
					Loved()
						.offset(x: -10)
				}

				Spacer()
			}
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
						width: (player.playerPosition ?? 0) / (player.currentTrack?.duration ?? 100) * 250,
						height: hover ? 8 : 4
					)
					.blendMode(.softLight)

				Rectangle()
					.fill(Color(.textBackgroundColor))
					.frame(
						width: CGFloat.maximum(0, 250 - ((player.playerPosition ?? 0) / (player.currentTrack?.duration ?? 100) * 250)),
						height: hover ? 8 : 4
					)
					.blendMode(.softLight)
			}
			.gesture(DragGesture(minimumDistance: 0).onChanged { value in
				player.setPosition((value.location.x / 250) * (player.currentTrack?.duration ?? 100))
			})
			
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
		}
		.animation(Animation.interactiveSpring(), value: hover)
		.onHover(perform: { value in
			hover = value
		})
	}
}

struct PausePlay: View {
	@EnvironmentObject var player: Player

	@State private var hover = false
	@State private var visible = false

	var body: some View {
		Image(systemName: (player.isPlaying ? "pause" : "play") + ".circle.fill")
			.font(.system(size: 35))
			.foregroundColor(Color(.textColor))
			.blendMode(.overlay)
			.scaleEffect(hover ? 1.2 : 1)
			.animation(.interactiveSpring(), value: hover)
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
			.animation(.interactiveSpring(), value: hover)
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
			.animation(.interactiveSpring(), value: hover)
			.onHover(perform: { value in
				hover = value
			})
			.onTapGesture(perform: {
				player.nextTrack()
			})
	}
}

struct Loved: View {
	@EnvironmentObject var player: Player

	@State private var hover = false

	var body: some View {
		Image(systemName: player.loved ? "heart.fill" : "heart")
			.foregroundColor(Color(player.loved ? .systemRed : .textColor))
			.blendMode(player.loved ? .multiply : .overlay)
			.animation(Animation.interactiveSpring(), value: player.loved)
			.padding(10)
			.scaleEffect(player.loved ? 1.1 : 1)
			.scaleEffect(hover ? 1.2 : 1)
			.animation(Animation.interactiveSpring(), value: hover)
			.animation(Animation.easeInOut(duration: 0.2).delay(0.1).repeat(while: player.loved), value: player.loved)
			.onHover(perform: { value in
				hover = value
			})
			.onTapGesture(perform: {
				player.setLoved(!player.loved)
			})
	}
}
