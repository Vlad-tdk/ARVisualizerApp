//
//  ARVisualizerAppApp.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 5. 6. 2025..
//

import SwiftUI

@main
struct ARVisualizerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    setupApp()
                }
                .onDisappear {
                    cleanupApp()
                }
        }
    }
    
    private func setupApp() {
        UIApplication.shared.isIdleTimerDisabled = true
        setupAppearance()
    }
    
    private func cleanupApp() {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
