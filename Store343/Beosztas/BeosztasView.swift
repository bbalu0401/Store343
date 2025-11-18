// BeosztasView.swift
// Placeholder for future schedule feature

import SwiftUI

struct BeosztasView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.secondary)
                
                Text("Beosztás")
                    .font(.title2)
                    .fontWeight(.light)
                    .padding()
                
                Text("Hamarosan...")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.adaptiveBackground(colorScheme: colorScheme))
            .navigationTitle("Beosztás")
        }
    }
}
