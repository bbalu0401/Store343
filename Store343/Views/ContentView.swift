// ContentView.swift
// Main tab bar container

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Főképernyő", systemImage: "house.fill")
                }
                .tag(0)
            
            InfoHubView()
                .tabItem {
                    Label("Infók", systemImage: "info.circle.fill")
                }
                .tag(1)
            
            BeosztasView()
                .tabItem {
                    Label("Beosztás", systemImage: "person.3.fill")
                }
                .tag(2)
            
            TermekekView()
                .tabItem {
                    Label("Termékek", systemImage: "shippingbox.fill")
                }
                .tag(3)
        }
        .accentColor(.lidlBlue)
    }
}
