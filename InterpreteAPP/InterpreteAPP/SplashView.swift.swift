//
//  SplashView.swift.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 5/7/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false

    var body: some View {
        Group {
            if isActive {
                // Aquí va tu vista principal
                ContentView()
            } else {
                VStack {
                    ZStack {

                        Image("LaunchImage")
                            .resizable()
                            .scaledToFit()
                            .ignoresSafeArea()
                    }
                    }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.launchBackground) // o el color que prefieras
                .ignoresSafeArea()
                .onAppear{
                    // Cambia a ContentView después de 2 segundos
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }
}
