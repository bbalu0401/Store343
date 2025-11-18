// InfoSelectionView.swift
// Selection screen for info types (Napi, Heti, Azonnali)

import SwiftUI

struct InfoSelectionView: View {
    @Binding var selectedInfoType: String?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Válaszd ki az információ típusát")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top)
            
            // Napi Infó
            InfoTypeCard(
                icon: "calendar",
                title: "Napi Infó",
                subtitle: "Mai feladatok és tennivalók",
                color: .orange
            )
            .onTapGesture {
                selectedInfoType = "napi"
            }
            
            // Heti Infó
            InfoTypeCard(
                icon: "calendar.badge.clock",
                title: "Heti Infó",
                subtitle: "Heti információk és közlemények",
                color: .purple
            )
            
            // Azonnali Infó
            InfoTypeCard(
                icon: "bolt.fill",
                title: "Azonnali Infó",
                subtitle: "Sürgős és azonnali közlemények",
                color: .lidlRed
            )
            
            Spacer()
        }
        .padding()
        .background(Color.adaptiveBackground(colorScheme: colorScheme))
        .navigationTitle("Infók")
    }
}

// MARK: - Info Type Card Component
struct InfoTypeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(color)
                .cornerRadius(16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(16)
    }
}
