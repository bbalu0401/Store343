// InfoHubView.swift
// Info hub with navigation to different info types

import SwiftUI

struct InfoHubView: View {
    @State private var selectedInfoType: String? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            Group {
                if selectedInfoType == nil {
                    InfoSelectionView(selectedInfoType: $selectedInfoType)
                } else if selectedInfoType == "napi" {
                    NapiInfoMainView(selectedInfoType: $selectedInfoType)
                }
                // Add other info types later
            }
        }
    }
}
