//
//  llama_chatApp.swift
//  llama chat
//
//  Created by Leonardo Mosimann conti on 12/12/24.
//

import SwiftUI

@main
struct llama_chatApp: App {
    @StateObject private var userSettings = UserSettings()

    var body: some Scene {
        WindowGroup {
            if userSettings.isLoggedIn {
                ContentView(username: userSettings.username)
                    .environmentObject(userSettings)
            } else {
                WelcomeView()
                    .environmentObject(userSettings)
            }
        }
    }
}
