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
        HStack {
            Form {
                Spacer()

                LaunchAtLogin.Toggle()
                    .padding(.bottom, 10)

                TextField("MPD host", text: $host)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("MPD port", value: $port, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Spacer()

                HStack {
                    Button("Close") {
                        NSApp.keyWindow?.close()
                    }

                    Button("Exit app") {
                        NSApp.keyWindow?.close()
                        NotificationCenter.default.post(
                            name: NSApplication.willTerminateNotification,
                            object: nil
                        )
                    }
                    .background(.red.opacity(0.2))
                    .cornerRadius(5)
                }
            }
        }
        .padding(20)
        .frame(width: 250, height: 250)
    }
}
