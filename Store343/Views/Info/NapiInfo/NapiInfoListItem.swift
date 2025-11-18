// NapiInfoListItem.swift
// List item component for napi_info documents

import SwiftUI
import CoreData

struct NapiInfoListItem: View {
    let info: NapiInfo
    let onAddPhoto: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(info.feldolgozva ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: info.feldolgozva ? "doc.text.fill" : "doc.text")
                    .font(.title3)
                    .foregroundColor(info.feldolgozva ? .blue : .secondary)

                if info.feldolgozva {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .offset(x: 18, y: -18)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(info.fajlnev ?? "napi_info")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.adaptiveText(colorScheme: colorScheme))

                Text(info.feldolgozva ? "Feldolgozva" : "Még nincs feltöltve")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Plus button for adding new photo
            Button(action: {
                onAddPhoto()
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.lidlBlue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.adaptiveCardBackground(colorScheme: colorScheme))
        .cornerRadius(12)
    }
}
