//
//  SettingsView.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 31/01/2022.
//

import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

struct SettingsView: View {    
    var body: some View {
        TabView {
            Form {
                LaunchAtLogin.Toggle()
            }
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            Form {
                Text("Toggle playback")
                KeyboardShortcuts.Recorder(for: .playPause)
                Text("Previous track")
                KeyboardShortcuts.Recorder(for: .backTrack)
                Text("Next track")
                KeyboardShortcuts.Recorder(for: .nextTrack)
                Text("Seek backward")
                KeyboardShortcuts.Recorder(for: .seekBackward)
                Text("Seek foreward")
                KeyboardShortcuts.Recorder(for: .seekForeward)
            }
            .tabItem {
                Label("Shortcuts", systemImage: "keyboard")
            }
        }
        .padding(20)
        .frame(width: 350, height: 400)
    }
}
