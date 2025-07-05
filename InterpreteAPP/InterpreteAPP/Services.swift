//
//  Services.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 29/6/25.
//

import Foundation
import UIKit

// MARK: - Servicio principal de OpenAI
// Esta clase maneja todas las comunicaciones con la API de OpenAI
// Incluye funciones para texto y análisis de imágenes
class OpenAIService {
    // Configuración de la sesión de red
    // Se optimiza para peticiones HTTP con timeouts y caché
    private let session: URLSession
    
    // MARK: - Inicialización
    init() {
        // Configurar la sesión de red con parámetros optimizados
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30  // Timeout de 30 segundos por petición
        config.timeoutIntervalForResource = 60 // Timeout de 60 segundos por recurso
        config.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024) // Caché de 10MB en memoria, 50MB en disco
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Función principal para generar explicaciones de texto
    /// Genera una explicación de texto legal usando la API de OpenAI
    /// - Parameter texto: El texto legal que se quiere explicar
    /// - Returns: Una explicación clara y simple del texto legal
    /// - Throws: Errores de red, API, o validación
    func generarExplicacion(para texto: String) async throws -> String {
        // Verificar que la API key esté configurada antes de hacer la petición
        guard !Config.openAIAPIKey.isEmpty else {
            throw ErroresApp.apiKeyFaltante
        }
        
        // Construir y enviar la petición HTTP
        let request = try construirRequest(para: texto)
        let (data, response) = try await session.data(for: request)
        
        // Validar la respuesta del servidor
        try validarRespuesta(response)
        
        // Procesar y retornar la respuesta
        return try procesarRespuesta(data)
    }
    
    // MARK: - Función para analizar imágenes
    /// Analiza una imagen y genera una explicación legal si aplica
    /// - Parameter imagen: La imagen UIImage que se quiere analizar
    /// - Returns: Una explicación del contenido de la imagen
    /// - Throws: Errores de procesamiento de imagen o API
    func analizarImagen(_ imagen: UIImage) async throws -> String {
        // Verificar que la API key esté configurada
        guard !Config.openAIAPIKey.isEmpty else {
            throw ErroresApp.apiKeyFaltante
        }
        
        // Construir petición específica para análisis de imagen
        let request = try construirRequestImagen(imagen)
        let (data, response) = try await session.data(for: request)
        
        // Validar y procesar la respuesta
        try validarRespuesta(response)
        return try procesarRespuesta(data)
    }
    
    // MARK: - Métodos Privados para construir peticiones
    
    /// Construye una petición HTTP para enviar texto a la API de OpenAI
    /// - Parameter texto: El texto que se quiere procesar
    /// - Returns: URLRequest configurado para la API de OpenAI
    /// - Throws: Errores de construcción de petición
    private func construirRequest(para texto: String) throws -> URLRequest {
        // Crear la URL del endpoint de chat completions
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw ErroresApp.networkError
        }
        
        // Configurar la petición HTTP
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization") // Autenticación con API key
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Tipo de contenido JSON
        
        // Construir el cuerpo de la petición en formato JSON
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo", // Modelo de OpenAI a usar
            "messages": [
                ["role": "system", "content": PromptHelper.systemPrompt], // Prompt del sistema que define el comportamiento
                ["role": "user", "content": PromptHelper.construirUserPrompt(con: texto)] // Mensaje del usuario
            ],
            "temperature": 0.7, // Controla la creatividad (0.0 = conservador, 1.0 = creativo)
            "max_tokens": 1000  // Máximo número de tokens en la respuesta
        ]
        
        // Convertir el cuerpo a datos JSON
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    /// Construye una petición HTTP para analizar imágenes con la API de OpenAI
    /// - Parameter imagen: La imagen UIImage que se quiere analizar
    /// - Returns: URLRequest configurado para análisis de imagen
    /// - Throws: Errores de procesamiento de imagen
    private func construirRequestImagen(_ imagen: UIImage) throws -> URLRequest {
        // Crear la URL del endpoint de chat completions (soporta imágenes)
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw ErroresApp.networkError
        }
        
        // Comprimir la imagen según su tamaño para optimizar la petición
        let compressionQuality: CGFloat = imagen.size.width > 1000 ? 0.5 : 0.8
        guard let imageData = imagen.jpegData(compressionQuality: compressionQuality)?.base64EncodedString() else {
            throw ErroresApp.invalidResponse
        }
        
        // Configurar la petición HTTP
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Construir el cuerpo de la petición para análisis de imagen
        let body: [String: Any] = [
            "model": "gpt-4o", // Modelo que soporta análisis de imágenes
            "messages": [
                ["role": "user",
                 "content": [
                    ["type": "text", "text": "Analiza esta imagen en términos legales si aplica. Sé conciso y claro."],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(imageData)"]]
                 ]
                ]
            ],
            "max_tokens": 1000
        ]
        
        // Convertir el cuerpo a datos JSON
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    // MARK: - Métodos de validación y procesamiento
    
    /// Valida la respuesta HTTP del servidor
    /// - Parameter response: La respuesta HTTP recibida
    /// - Throws: Errores específicos según el código de estado HTTP
    private func validarRespuesta(_ response: URLResponse) throws {
        // Verificar que sea una respuesta HTTP válida
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ErroresApp.networkError
        }
        
        // Manejar diferentes códigos de estado HTTP
        switch httpResponse.statusCode {
        case 200...299:
            // Respuesta exitosa
            break
        case 401:
            // No autorizado - API key inválida
            throw ErroresApp.apiKeyFaltante
        case 429:
            // Rate limit excedido - demasiadas peticiones
            throw ErroresApp.rateLimitExceeded
        case 500...599:
            // Error del servidor
            throw ErroresApp.generalError("Error del servidor (\(httpResponse.statusCode))")
        default:
            // Otros errores HTTP
            throw ErroresApp.generalError("Error HTTP \(httpResponse.statusCode)")
        }
    }
    
    /// Procesa la respuesta JSON de la API de OpenAI
    /// - Parameter data: Los datos JSON recibidos del servidor
    /// - Returns: El texto de la respuesta procesado
    /// - Throws: Errores si la respuesta no tiene el formato esperado
    private func procesarRespuesta(_ data: Data) throws -> String {
        // Parsear el JSON de la respuesta
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ErroresApp.invalidResponse
        }
        
        // Limpiar espacios en blanco del texto de respuesta
        let respuestaLimpia = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Verificar que la respuesta no esté vacía y no sea demasiado larga
        guard !respuestaLimpia.isEmpty && respuestaLimpia.count <= 5000 else {
            throw ErroresApp.invalidResponse
        }
        
        return respuestaLimpia
    }
}

// MARK: - Controlador de límites de uso (Rate Limiter)
// Esta clase controla cuántas peticiones se pueden hacer en un período de tiempo
// Ayuda a evitar costos excesivos y respetar los límites de la API
class RateLimiter {
    // Variables para rastrear el uso
    private var contadorMensajes = 0          // Contador de mensajes en el período actual
    private var ultimoMensaje: Date = Date()  // Timestamp del último mensaje enviado
    private let maxMensajesPorMinuto = 10     // Límite de mensajes por minuto
    private let tiempoMinimoEntreMensajes: TimeInterval = 2.0  // Tiempo mínimo entre mensajes
    
    /// Verifica si se puede enviar un nuevo mensaje
    /// - Returns: true si se puede enviar, false si se debe esperar
    func puedeEnviar() -> Bool {
        let ahora = Date()
        
        // Verificar tiempo mínimo entre mensajes (evita spam)
        guard ahora.timeIntervalSince(ultimoMensaje) >= tiempoMinimoEntreMensajes else {
            return false
        }
        
        // Verificar límite por minuto (controla costos)
        guard contadorMensajes < maxMensajesPorMinuto else {
            return false
        }
        
        // Actualizar contadores
        contadorMensajes += 1
        ultimoMensaje = ahora
        return true
    }
    
    /// Resetea el contador de mensajes (se llama cada minuto)
    func resetearContador() {
        contadorMensajes = 0
    }
}

// MARK: - Filtro de contenido
// Esta estructura ayuda a prevenir el envío de contenido inapropiado
struct ContentFilter {
    // Lista de palabras que activan el filtro
    private static let palabrasFiltradas = ["spam", "test repetitivo", "abuso"]
    
    /// Verifica si un texto contiene palabras filtradas
    /// - Parameter texto: El texto a verificar
    /// - Returns: true si contiene palabras filtradas, false si está limpio
    static func contienePalabrasFiltradas(_ texto: String) -> Bool {
        let textoMinuscula = texto.lowercased()
        return palabrasFiltradas.contains { palabra in
            textoMinuscula.contains(palabra)
        }
    }
}

// MARK: - Helper para localización
// Esta estructura maneja los mensajes en diferentes idiomas
struct LocalizationHelper {
    /// Obtiene el saludo inicial según el idioma del usuario
    /// - Parameter idioma: Código de idioma (ej: "es", "zh", "en")
    /// - Returns: Mensaje de saludo en el idioma correspondiente
    static func obtenerSaludo(idioma: String? = nil) -> String {
        let idioma = idioma ?? String(Locale.preferredLanguages.first?.prefix(2) ?? "es")
        switch idioma {
        case "zh":
            return "👋 你好！我是你的法律助手。请发送法律文本，我会用简单的语言帮你解释。"
        case "es":
            return "👋 ¡Hola! Soy tu asistente legal. Envíame cualquier texto legal y te lo explicaré con palabras sencillas."
        default:
            return "👋 Hello! I'm your legal assistant. Send me any legal text and I'll explain it in simple terms."
        }
    }
}

