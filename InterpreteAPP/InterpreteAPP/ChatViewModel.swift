//  ChatViewModel.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 29/6/25.
//

import SwiftUI
import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Estados Publicados
    @Published var mensajes: [Mensaje] = []
    @Published var entradaTexto = ""
    @Published var isLoading = false
    @Published var mostrarError = false
    @Published var mensajeError = ""
    
    // MARK: - Propiedades Privadas
    private var saludoMostrado = false
    private var contadorMensajes = 0
    private var ultimoMensaje: Date = Date()
    private let apiService = OpenAIService()
    private let rateLimiter = RateLimiter()
    
    // MARK: - Inicialización
    func inicializar() {
        if !saludoMostrado {
            mostrarSaludoInicial()
            saludoMostrado = true
        }
        configurarTimer()
    }
    
    // MARK: - Funciones Principales
    func enviarMensaje() async {
        guard validarEntrada() else { return }
        
        let textoUsuario = entradaTexto.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Añadir mensaje del usuario
        mensajes.append(Mensaje(texto: textoUsuario, esUsuario: true))
        entradaTexto = ""
        isLoading = true
        
        do {
            let respuesta = try await apiService.generarExplicacion(para: textoUsuario)
            mensajes.append(Mensaje(texto: respuesta, esUsuario: false))
            
            // Ocultar teclado automáticamente cuando se recibe la respuesta
            hideKeyboard()
        } catch {
            manejarError(error)
        }
        
        isLoading = false
    }
    
    func enviarImagen(_ imagen: UIImage) async {
        isLoading = true
        
        do {
            let respuesta = try await apiService.analizarImagen(imagen)
            mensajes.append(Mensaje(texto: respuesta, esUsuario: false))
            
            // Ocultar teclado automáticamente cuando se recibe la respuesta
            hideKeyboard()
        } catch {
            manejarError(error)
        }
        
        isLoading = false
    }
    
    func limpiarChat() {
        mensajes.removeAll()
        mostrarSaludoInicial()
    }
    
    // MARK: - Funciones Privadas
    private func validarEntrada() -> Bool {
        guard !entradaTexto.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        
        guard rateLimiter.puedeEnviar() else {
            mostrarErrorPersonalizado(.rateLimitExceeded)
            return false
        }
        
        if ContentFilter.contienePalabrasFiltradas(entradaTexto) {
            mostrarErrorPersonalizado(.contentFiltered)
            return false
        }
        
        return true
    }
    
    private func mostrarSaludoInicial() {
        let saludo = LocalizationHelper.obtenerSaludo()
        mensajes.append(Mensaje(texto: saludo, esUsuario: false))
    }
    
    private func manejarError(_ error: Error) {
        if let appError = error as? ErroresApp {
            mostrarErrorPersonalizado(appError)
        } else {
            mostrarErrorPersonalizado(.networkError)
        }
    }
    
    private func mostrarErrorPersonalizado(_ error: ErroresApp) {
        mensajeError = error.localizedDescription
        mostrarError = true
    }
    
    private func configurarTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                self.rateLimiter.resetearContador()
            }
        }
    }
    
    // MARK: - Función para ocultar teclado
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Estado de UI
class UIState: ObservableObject {
    @Published var mostrarPicker = false
    @Published var imagenSeleccionada: UIImage?
}
