//
//  SettingsView.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 31/01/2022.
//

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
        }
        .padding(20)
        .frame(width: 350, height: 400)
    }
}
