//
//  ChatMessagesView.swift
//  InterpreteAPP
//
//  Created by Jules on 7/7/24.
//

import SwiftUI

struct ChatMessagesView: View {
    @ObservedObject var viewModel: ChatViewModel // Usar ObservedObject si la vista no es dueña del VM
    // O @StateObject si esta vista fuera a crear y mantener su propio VM (no es el caso aquí)

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.mensajes) { mensaje in
                        BurbujaMensaje(mensaje: mensaje)
                            .id(mensaje.id)
                    }

                    if viewModel.isLoading {
                        IndicadorCarga()
                            .id("loadingIndicator")
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: viewModel.mensajes.count) { _ in
                scrollToBottom(proxy: proxy, isInitialLoad: false)
            }
            .onChange(of: viewModel.isLoading) { isLoading in
                if isLoading {
                    // Esperar un poco para que el ID "loadingIndicator" esté disponible en el DOM de SwiftUI
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                         scrollToBottom(proxy: proxy, isInitialLoad: false)
                    }
                } else {
                    // Si deja de cargar y hay mensajes, asegurar que el último mensaje es visible
                     scrollToBottom(proxy: proxy, isInitialLoad: false)
                }
            }
            .onAppear {
                 // Scroll inicial al último mensaje si ya hay mensajes al aparecer la vista
                 // Esto es útil si la vista se carga con mensajes preexistentes.
                 // El saludo inicial del ViewModel ya añade un mensaje, así que esto debería funcionar.
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Dar tiempo a que se renderice
                    scrollToBottom(proxy: proxy, isInitialLoad: true)
                 }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, isInitialLoad: Bool) {
        let targetID: AnyHashable? = viewModel.isLoading ? "loadingIndicator" : viewModel.mensajes.last?.id

        guard let idToScroll = targetID else { return }

        withAnimation(isInitialLoad ? .none : .spring()) { // Sin animación en carga inicial
            proxy.scrollTo(idToScroll, anchor: .bottom)
        }
    }
}

// Nota: `BurbujaMensaje` y `IndicadorCarga` se asumen definidas globalmente (ej. en ContentView o sus propios archivos).
// Si no lo están, necesitarían ser movidas o importadas aquí.
// El ViewModel (`ChatViewModel`) se pasa como un `ObservedObject`.
// Las animaciones y la lógica de scroll se mantienen similares a como estaban en `ContentView`.
// Se añadió un scroll inicial en `.onAppear` para manejar casos donde la vista carga con mensajes.
// La lógica de `scrollToBottom` se ha centralizado un poco.
// El `DispatchQueue.main.asyncAfter` en `onAppear` y para `isLoading` ayuda a asegurar que el `ScrollViewProxy`
// pueda encontrar el ID al que scrollear después de que la UI se haya actualizado.
// El delay de 0.05 o 0.1 es empírico; podría necesitar ajuste.
// Se ha simplificado la lógica de scroll en `isLoading` change: siempre intenta scrollear al fondo.
// `isInitialLoad` en `scrollToBottom` permite desactivar la animación para el primer scroll.
