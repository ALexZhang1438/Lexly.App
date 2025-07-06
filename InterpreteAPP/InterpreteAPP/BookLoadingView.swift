//
//  BookLoadingView.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 6/7/25.
//
import SwiftUI

struct BookLoadingView: View {
    @State private var isOpen = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "book")
                .resizable()
                .frame(width: 60, height: 60)
                .rotation3DEffect(
                    .degrees(isOpen ? 0 : -90),
                    axis: (x: 0, y: 1, z: 0)
                )
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isOpen)
                .onAppear {
                    isOpen.toggle()
                }

            Text("Cambiando idioma...")
                .foregroundColor(.white)
                .font(.headline)
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(16)
    }
}

