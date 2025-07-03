//
//  Services.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 29/6/25.
//

import Foundation
import UIKit

// MARK: - Servicio de OpenAI
class OpenAIService {
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024)
        self.session = URLSession(configuration: config)
    }
    
    func generarExplicacion(para texto: String) async throws -> String {
        guard !Config.openAIAPIKey.isEmpty else {
            throw ErroresApp.apiKeyFaltante
        }
        
        let request = try construirRequest(para: texto)
        let (data, response) = try await session.data(for: request)
        
        try validarRespuesta(response)
        return try procesarRespuesta(data)
    }
    
    func analizarImagen(_ imagen: UIImage) async throws -> String {
        guard !Config.openAIAPIKey.isEmpty else {
            throw ErroresApp.apiKeyFaltante
        }
        
        let request = try construirRequestImagen(imagen)
        let (data, response) = try await session.data(for: request)
        
        try validarRespuesta(response)
        return try procesarRespuesta(data)
    }
    
    // MARK: - Métodos Privados
    private func construirRequest(para texto: String) throws -> URLRequest {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw ErroresApp.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": PromptHelper.systemPrompt],
                ["role": "user", "content": PromptHelper.construirUserPrompt(con: texto)]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    private func construirRequestImagen(_ imagen: UIImage) throws -> URLRequest {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw ErroresApp.networkError
        }
        
        let compressionQuality: CGFloat = imagen.size.width > 1000 ? 0.5 : 0.8
        guard let imageData = imagen.jpegData(compressionQuality: compressionQuality)?.base64EncodedString() else {
            throw ErroresApp.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4-vision-preview",
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
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    private func validarRespuesta(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ErroresApp.networkError
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 429:
            throw ErroresApp.rateLimitExceeded
        default:
            throw ErroresApp.networkError
        }
    }
    
    private func procesarRespuesta(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ErroresApp.invalidResponse
        }
        
        let respuestaLimpia = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !respuestaLimpia.isEmpty && respuestaLimpia.count <= 5000 else {
            throw ErroresApp.invalidResponse
        }
        
        return respuestaLimpia
    }
}

// MARK: - Rate Limiter
class RateLimiter {
    private var contadorMensajes = 0
    private var ultimoMensaje: Date = Date()
    private let maxMensajesPorMinuto = 10
    private let tiempoMinimoEntreMensajes: TimeInterval = 2.0
    
    func puedeEnviar() -> Bool {
        let ahora = Date()
        
        // Verificar tiempo mínimo entre mensajes
        guard ahora.timeIntervalSince(ultimoMensaje) >= tiempoMinimoEntreMensajes else {
            return false
        }
        
        // Verificar límite por minuto
        guard contadorMensajes < maxMensajesPorMinuto else {
            return false
        }
        
        contadorMensajes += 1
        ultimoMensaje = ahora
        return true
    }
    
    func resetearContador() {
        contadorMensajes = 0
    }
}

// MARK: - Filtro de Contenido
struct ContentFilter {
    private static let palabrasFiltradas = ["spam", "test repetitivo", "abuso"]
    
    static func contienePalabrasFiltradas(_ texto: String) -> Bool {
        let textoMinuscula = texto.lowercased()
        return palabrasFiltradas.contains { palabra in
            textoMinuscula.contains(palabra)
        }
    }
}

// MARK: - Helper de Localización
struct LocalizationHelper {
    static func obtenerSaludo() -> String {
        let idioma = Locale.current.language.languageCode?.identifier ?? "es"
        
        switch idioma {
        case "en":
            return "👋 Hello! I'm your legal assistant. Send me any legal text and I'll explain it in simple terms."
        case "fr":
            return "👋 Bonjour ! Je suis votre assistant juridique. Envoyez-moi un texte juridique et je vous l'expliquerai simplement."
        default:
            return "👋 ¡Hola! Soy tu asistente legal. Envíame cualquier texto legal y te lo explicaré con palabras sencillas."
        }
    }
}

// MARK: - Helper de Prompts
struct PromptHelper {
    static let systemPrompt = """
    Eres un asistente legal experto que explica textos legales de manera clara y accesible. 
    Tu objetivo es traducir lenguaje jurídico complejo a términos que cualquier persona pueda entender.
    
    Directrices:
    - Usa un lenguaje sencillo y claro
    - Proporciona ejemplos cuando sea útil
    - Destaca los puntos más importantes
    - Mantén un tono profesional pero accesible
    - Si no estás seguro, indícalo claramente
    """
    
    static func construirUserPrompt(con texto: String) -> String {
        return """
        Por favor, explica este texto legal de manera clara y sencilla:
        
        \(texto)
        
        Incluye:
        1. Un resumen en palabras simples
        2. Los puntos más importantes
        3. Cualquier implicación práctica relevante
        """
    }
}
