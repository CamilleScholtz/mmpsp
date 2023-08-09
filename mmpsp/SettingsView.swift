//
//  SettingsView.swift
//  mmpsp
//
//  Created by Camille Scholtz on 31/01/2022.
//

import LaunchAtLogin
import SwiftUI

enum Setting {
    static let host = "host"
    static let port = "port"
    static let directory = "directory"
}

struct SettingsView: View {
    @AppStorage(Setting.host) var host = "localhost"
    @AppStorage(Setting.port) var port = 6600

    var body: some View {
        ZStack {
            Form {
                LaunchAtLogin.Toggle()

                HStack {
                    TextField("MPD host", text: $host)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("MPD port", value: $port, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
        .padding(20)
        .frame(width: 400, height: 400)
    }
}
