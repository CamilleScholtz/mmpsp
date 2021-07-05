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
			guard player.track?.artwork != nil else { return height = 250 }
			height = (player.track!.artwork!.size.height / player.track!.artwork!.size.width * 250).rounded(.down)
		})
		.onChange(of: player.track?.artwork, perform: { value in
			guard value != nil else { return height = 250 }
			height = (value!.size.height / value!.size.width * 250).rounded(.down)
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
				timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
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
		if player.track?.artwork != nil {
			Image(nsImage: player.track!.artwork!)
				.resizable()
				.aspectRatio(contentMode: .fill)
				.frame(width: 250)
		} else {
			Image(systemName: "questionmark.app.dashed")
				.font(.system(size: 50))
				.frame(width: 250, height: 250)
		}
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
					Shuffle()
						.offset(x: 10)

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
			.offset(y: 1)
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
						width: (player.playerPosition ?? 0) / (player.track?.duration ?? 100) * 250,
						height: hover ? 8 : 4
					)
					.blendMode(.softLight)

				Rectangle()
					.fill(Color(.textBackgroundColor))
					.frame(
						width: CGFloat.maximum(0, 250 - ((player.playerPosition ?? 0) / (player.track?.duration ?? 100) * 250)),
						height: hover ? 8 : 4
					)
					.blendMode(.softLight)
			}
			.gesture(DragGesture(minimumDistance: 0).onChanged { value in
				player.setPosition((value.location.x / 250) * (player.track?.duration ?? 100))
			})

			HStack(alignment: .center) {
				Text(player.playerPosition?.timeString ?? "-:--")
					.font(.system(size: 10))
					.blendMode(.overlay)
					.offset(x: 5, y: 3)

				Spacer()

				Text(player.track?.duration.timeString ?? "-:--")
					.font(.system(size: 10))
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

struct Shuffle: View {
	@EnvironmentObject var player: Player

	@State private var hover = false

	var body: some View {
		Image(systemName: "shuffle")
			.foregroundColor(Color(player.isShuffle ? .systemRed : .textColor))
			.blendMode(player.isShuffle ? .multiply : .overlay)
			.animation(Animation.interactiveSpring(), value: player.isShuffle)
			.padding(10)
			.scaleEffect(hover ? 1.2 : 1)
			.animation(.interactiveSpring(), value: hover)
			.onHover(perform: { value in
				hover = value
			})
			.onTapGesture(perform: {
				print(player.isShuffle)
			})
	}
}

struct Loved: View {
	@EnvironmentObject var player: Player

	@State private var hover = false

	var body: some View {
		Image(systemName: player.track?.isLoved ?? false ? "heart.fill" : "heart")
			.foregroundColor(Color(player.track?.isLoved ?? false ? .systemRed : .textColor))
			.blendMode(player.track?.isLoved ?? false ? .multiply : .overlay)
			.animation(Animation.interactiveSpring(), value: player.track?.isLoved)
			.padding(10)
			.scaleEffect(player.track?.isLoved ?? false ? 1.1 : 1)
			.scaleEffect(hover ? 1.2 : 1)
			.animation(Animation.interactiveSpring(), value: hover)
			.animation(Animation.easeInOut(duration: 0.2).delay(0.1).repeat(while: player.track?.isLoved ?? false), value: player.track?.isLoved)
			.onHover(perform: { value in
				hover = value
			})
			.onTapGesture(perform: {
				player.setLoved(!(player.track?.isLoved ?? false))
			})
	}
}

struct Wrench: View {
	@State private var hover = false

	var body: some View {
		Image(systemName: "wrench")
			.blendMode(.overlay)
			.padding(10)
			.scaleEffect(hover ? 1.2 : 1)
			.animation(.interactiveSpring(), value: hover)
			.onHover(perform: { value in
				hover = value
			})
			.onTapGesture(perform: {
				print("A")
			})
	}
}
