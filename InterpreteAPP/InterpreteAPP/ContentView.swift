//
//  ContentView.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 29/6/25.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Estado de la Vista
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var uiState = UIState()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo gradiente suave
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Área de Chat
                    ChatScrollView(
                        mensajes: chatViewModel.mensajes,
                        isLoading: chatViewModel.isLoading
                    )
                    .background(Color.clear)
                    
                    // MARK: - Divisor con estilo
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    // MARK: - Área de Entrada
                    ChatInputView(
                        entradaTexto: $chatViewModel.entradaTexto,
                        isLoading: chatViewModel.isLoading,
                        onSendMessage: {
                            Task {
                                await chatViewModel.enviarMensaje()
                            }
                        },
                        onSelectImage: {
                            uiState.mostrarPicker = true
                        }
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Asistente Legal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        chatViewModel.limpiarChat()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(chatViewModel.mensajes.isEmpty)
                }
            }
            .onAppear {
                chatViewModel.inicializar()
            }
            .sheet(isPresented: $uiState.mostrarPicker) {
                ImagePicker(image: $uiState.imagenSeleccionada)
                    .onDisappear {
                        if let imagen = uiState.imagenSeleccionada {
                            Task {
                                await chatViewModel.enviarImagen(imagen)
                            }
                            uiState.imagenSeleccionada = nil
                        }
                    }
            }
            .alert("Error", isPresented: $chatViewModel.mostrarError) {
                Button("OK") {
                    chatViewModel.mostrarError = false
                }
            } message: {
                Text(chatViewModel.mensajeError)
            }
        }
    }
}

// MARK: - Vista de Chat Scrolleable
struct ChatScrollView: View {
    let mensajes: [Mensaje]
    let isLoading: Bool
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(mensajes) { mensaje in
                        BurbujaMensaje(mensaje: mensaje)
                            .id(mensaje.id)
                    }
                    
                    if isLoading {
                        IndicadorCarga()
                            .id("loading")
                    }
                }
                .padding(.vertical, 16)
                .animation(.easeInOut(duration: 0.3), value: mensajes.count)
            }
            .onChange(of: mensajes.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: isLoading) { _, _ in
                if isLoading {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy){
    
        withAnimation(.easeInOut(duration: 0.5)) {
            if isLoading {
                proxy.scrollTo("loading", anchor: .bottom)
            } else if let ultimo = mensajes.last {
                proxy.scrollTo(ultimo.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Vista de Entrada de Chat
struct ChatInputView: View {
    @Binding var entradaTexto: String
    let isLoading: Bool
    let onSendMessage: () -> Void
    let onSelectImage: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Campo de texto mejorado
            TextField("Escribe tu consulta legal...", text: $entradaTexto, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .disabled(isLoading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            
            // Botón de imagen
            Button(action: onSelectImage) {
                Image(systemName: "photo.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white, isLoading ? .gray : .blue)
                    .background(Circle().fill(Color.clear))
            }
            .disabled(isLoading)
            .scaleEffect(isLoading ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
            
            // Botón de envío
            Button(action: onSendMessage) {
                Image(systemName: isLoading ? "stop.circle.fill" : "paperplane.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white, isLoading ? .red : .blue)
                    .rotationEffect(.degrees(isLoading ? 0 : 45))
            }
            .disabled(entradaTexto.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading)
            .scaleEffect(isLoading ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    ContentView()
}
