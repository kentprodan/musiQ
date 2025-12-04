//
//  musiQApp.swift
//  musiQ
//
//  Created by Cristian Prodan on 04.12.25.
//

import SwiftUI

@main
struct musiQApp: App {
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showSettings = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !settingsManager.hasCompletedInitialSetup {
                    InitialSetupView()
                } else {
                    ContentView()
                        .frame(minWidth: 1000, minHeight: 600)
                        .edgesIgnoringSafeArea(.top)
                }
            }
            .onAppear {
                // Configure window for full content area with no titlebar
                if let window = NSApplication.shared.windows.first {
                    window.standardWindowButton(.closeButton)?.isHidden = true
                    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                    window.standardWindowButton(.zoomButton)?.isHidden = true
                    window.titlebarAppearsTransparent = true
                    window.titleVisibility = .hidden
                    window.styleMask.insert(.fullSizeContentView)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
                showSettings = true
            }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .sidebar) {
                Button(action: {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }) {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
            }
            
            // Settings in app menu
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let toggleSidebar = Notification.Name("toggleSidebar")
    static let openSettings = Notification.Name("openSettings")
}
