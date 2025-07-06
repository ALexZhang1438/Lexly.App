//  ChatViewModel.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 29/6/25.
//

import SwiftUI
import Foundation

// MARK: - ViewModel principal del chat
// Esta clase maneja toda la lógica de negocio de la interfaz de chat
// Coordina entre la UI y los servicios de API
@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Estados Publicados (ObservableObject)
    // Estas propiedades se actualizan automáticamente en la UI cuando cambian
    
    @Published var mensajes: [Mensaje] = []        // Lista de mensajes en el chat
    @Published var entradaTexto = ""               // Texto que el usuario está escribiendo
    @Published var isLoading = false               // Indica si se está procesando una petición
    @Published var mostrarError = false            // Indica si mostrar un mensaje de error
    @Published var mensajeError = ""               // Texto del mensaje de error
    @Published var idiomaActual: String = "es"     // Idioma actual (es, zh, en)
    @Published var cambiandoIdioma = false
    
    // MARK: - Propiedades Privadas
    // Variables internas para controlar el estado de la aplicación
    
    private var saludoMostrado = false             // Evita mostrar el saludo múltiples veces
    private var contadorMensajes = 0               // Contador de mensajes enviados
    private var ultimoMensaje: Date = Date()       // Timestamp del último mensaje
    private let assistantService = OpenAIAssistantService()  // Servicio para conversaciones con asistente
    private let apiService = OpenAIService()       // Servicio para peticiones directas a la API
    private let rateLimiter = RateLimiter()        // Controlador de límites de uso
    
    // MARK: - Inicialización
    /// Configura el estado inicial del chat
    func inicializar() {
        // Mostrar saludo solo la primera vez
        if !saludoMostrado {
            mostrarSaludoInicial()
            saludoMostrado = true
        }
        // Configurar timer para resetear contadores
        configurarTimer()
    }
    
    // MARK: - Funciones Principales
    
    /// Envía un mensaje de texto al asistente y obtiene la respuesta
    /// Esta función se ejecuta de forma asíncrona para no bloquear la UI
    func enviarMensaje() async {
        // Validar que el mensaje sea válido antes de enviarlo
        guard validarEntrada() else { return }
        
        // Limpiar espacios en blanco del texto del usuario
        let textoUsuario = entradaTexto.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Añadir mensaje del usuario a la lista y limpiar el campo de entrada
        mensajes.append(Mensaje(texto: textoUsuario, esUsuario: true))
        entradaTexto = ""
        isLoading = true  // Mostrar indicador de carga
        
        do {
            // Enviar mensaje al asistente y obtener respuesta
            let respuesta = try await assistantService.enviarMensaje(textoUsuario)
            mensajes.append(Mensaje(texto: respuesta, esUsuario: false))
            
            // Ocultar teclado automáticamente cuando se recibe la respuesta
            hideKeyboard()
        } catch {
            // Manejar cualquier error que ocurra durante el proceso
            manejarError(error)
        }
        
        isLoading = false  // Ocultar indicador de carga
    }
    
    /// Analiza una imagen y obtiene una explicación legal
    /// - Parameter imagen: La imagen UIImage que se quiere analizar
    func enviarImagen(_ imagen: UIImage) async {
        isLoading = true
        mostrarError = false
        mensajeError = ""
        
        do {
            // 1. Analizar la imagen con gpt-4o
            let resumen = try await apiService.analizarImagen(imagen)

            // 2. Enviar ese resumen al Assistant (mantiene el contexto del hilo)
            let inputTexto = "📷 Resultado del análisis de imagen:\n\(resumen)"
            let respuesta = try await assistantService.enviarMensaje(inputTexto)

            // 3. Mostrar en la UI como parte de la conversación
            agregarMensajeUsuario("📷 Imagen enviada.")
            agregarMensajeAsistente(respuesta)
            
        } catch {
            mostrarError = true
            mensajeError = (error as? ErroresApp)?.errorDescription ?? error.localizedDescription
        }
        
        isLoading = false
    }

    func agregarMensajeUsuario(_ texto: String) {
        mensajes.append(Mensaje(texto: texto, esUsuario: true))
    }

    func agregarMensajeAsistente(_ texto: String) {
        mensajes.append(Mensaje(texto: texto, esUsuario: false))
    }

    
    /// Limpia todo el historial de mensajes y reinicia el chat
    func limpiarChat() {
        mensajes.removeAll()  // Eliminar todos los mensajes
        mostrarSaludoInicial() // Mostrar saludo inicial nuevamente
    }
    
    // MARK: - Funciones Privadas
    
    /// Valida que el mensaje del usuario sea válido antes de enviarlo
    /// - Returns: true si el mensaje es válido, false si hay problemas
    private func validarEntrada() -> Bool {
        // Verificar que el texto no esté vacío
        guard !entradaTexto.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        
        // Verificar límites de rate (evitar spam y controlar costos)
        guard rateLimiter.puedeEnviar() else {
            mostrarErrorPersonalizado(.rateLimitExceeded)
            return false
        }
        
        // Verificar que el contenido no esté filtrado
        if ContentFilter.contienePalabrasFiltradas(entradaTexto) {
            mostrarErrorPersonalizado(.contentFiltered)
            return false
        }
        
        return true
    }
    
    /// Muestra el mensaje de saludo inicial según el idioma
    private func mostrarSaludoInicial() {
        let saludo = LocalizationHelper.obtenerSaludo(idioma: idiomaActual)
        mensajes.append(Mensaje(texto: saludo, esUsuario: false))
    }
    
    /// Maneja errores y los convierte en mensajes de error para el usuario
    /// - Parameter error: El error que ocurrió
    private func manejarError(_ error: Error) {
        print("❌ Error en ChatViewModel: \(error.localizedDescription)")
        
        // Intentar convertir el error a un ErroresApp específico
        if let appError = error as? ErroresApp {
            mostrarErrorPersonalizado(appError)
        } else {
            // Si no es un ErroresApp, intentar extraer información del mensaje de error
            let errorMessage = error.localizedDescription
            if errorMessage.contains("401") || errorMessage.contains("Unauthorized") {
                mostrarErrorPersonalizado(.apiKeyFaltante)
            } else if errorMessage.contains("429") || errorMessage.contains("rate limit") {
                mostrarErrorPersonalizado(.rateLimitExceeded)
            } else if errorMessage.contains("500") || errorMessage.contains("server") {
                mostrarErrorPersonalizado(.generalError("Error del servidor. Intenta más tarde."))
            } else {
                mostrarErrorPersonalizado(.networkError)
            }
        }
    }
    
    /// Muestra un error específico al usuario
    /// - Parameter error: El tipo de error a mostrar
    private func mostrarErrorPersonalizado(_ error: ErroresApp) {
        mensajeError = error.localizedDescription
        mostrarError = true
    }
    
    /// Configura un timer que resetea el contador de mensajes cada minuto
    /// Esto permite que el usuario pueda enviar más mensajes después del límite
    private func configurarTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                self.rateLimiter.resetearContador()
            }
        }
    }
    
    // MARK: - Función para ocultar teclado
    /// Oculta el teclado virtual cuando se recibe una respuesta
    /// Mejora la experiencia de usuario
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func notificarCambioIdioma() async {
        let mensajeIdioma: String
        switch idiomaActual {
        case "zh":
            mensajeIdioma = "从现在开始，请用中文回复。"
        case "es":
            mensajeIdioma = "A partir de ahora, responde en español."
        default:
            mensajeIdioma = "From now on, respond in English."
        }

        do {
            let respuesta = try await assistantService.enviarMensaje(mensajeIdioma)
            agregarMensajeUsuario(mensajeIdioma)
            agregarMensajeAsistente(respuesta)
        } catch {
            manejarError(error)
        }
    }
    func cambiarIdiomaConAnimacion() async {
        // Mostrar animación
        cambiandoIdioma = true
        
        // Reiniciar chat
        limpiarChat()
        
        // Enviar mensaje de cambio de idioma a la IA
        await notificarCambioIdioma()
        
        // Ocultar animación
        cambiandoIdioma = false
    }


}

// MARK: - Estado de UI para el selector de imágenes
// Esta clase maneja el estado del selector de imágenes
class UIState: ObservableObject {
    @Published var mostrarPicker = false           // Indica si mostrar el selector de imágenes
    @Published var imagenSeleccionada: UIImage?   // La imagen seleccionada por el usuario
}
