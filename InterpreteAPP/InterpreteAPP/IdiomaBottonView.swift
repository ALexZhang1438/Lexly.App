//
//  IdiomaBottonView.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 6/7/25.
//
import SwiftUI

struct IdiomaBotonView: View {
    let idioma: String
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            onTap()
        }) {
            HStack(spacing: 6) {
                Text(banderaEmoji)
                    .font(.system(size: 20))
                Text(idioma.uppercased())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color.accentBlue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: idioma)
    }

    private var banderaEmoji: String {
        switch idioma {
        case "es": return "🇪🇸"
        case "zh": return "🇨🇳"
        default: return "🌐"
        }
    }
}

