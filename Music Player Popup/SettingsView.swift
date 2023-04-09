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
        ZStack {
            Form {
                LaunchAtLogin.Toggle()
            }
        }
        .padding(20)
        .frame(width: 250, height: 250)
    }
}
