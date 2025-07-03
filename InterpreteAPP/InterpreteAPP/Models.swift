//
//  Models.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 29/6/25.
//

import Foundation

// MARK: - Modelo de Mensaje
struct Mensaje: Identifiable, Equatable {
    let id = UUID()
    let texto: String
    let esUsuario: Bool
    let timestamp: Date
    
    init(texto: String, esUsuario: Bool) {
        self.texto = texto
        self.esUsuario = esUsuario
        self.timestamp = Date()
    }
    
    static func == (lhs: Mensaje, rhs: Mensaje) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Tipos de Error
enum ErroresApp: LocalizedError {
    case apiKeyFaltante
    case networkError
    case invalidResponse
    case contentFiltered
    case rateLimitExceeded
    case imageProcessingError
    case generalError(String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyFaltante:
            return "⚠️ Configuración de API no encontrada. Verifica tu clave de API."
        case .networkError:
            return "🌐 Error de conexión. Verifica tu conexión a internet."
        case .invalidResponse:
            return "❌ Respuesta inválida del servidor. Intenta nuevamente."
        case .contentFiltered:
            return "🚫 Contenido filtrado por políticas de seguridad."
        case .rateLimitExceeded:
            return "⏰ Demasiadas consultas. Espera un momento antes de continuar."
        case .imageProcessingError:
            return "🖼️ Error al procesar la imagen. Intenta con otra imagen."
        case .generalError(let mensaje):
            return "⚠️ \(mensaje)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .apiKeyFaltante:
            return "Contacta al desarrollador para configurar la API."
        case .networkError:
            return "Verifica tu conexión a internet e intenta nuevamente."
        case .invalidResponse:
            return "El servidor está experimentando problemas. Intenta más tarde."
        case .contentFiltered:
            return "Reformula tu mensaje evitando contenido inapropiado."
        case .rateLimitExceeded:
            return "Espera unos minutos antes de enviar otro mensaje."
        case .imageProcessingError:
            return "Asegúrate de que la imagen sea clara y esté en formato válido."
        case .generalError:
            return "Intenta nuevamente o contacta soporte si el problema persiste."
        }
    }
}

// MARK: - Configuración
struct ApiConfig {
    static let openAIAPIKey = Secret.openAIAPIKey
    static let maxTokens = 1000
    static let temperature: Double = 0.7
    static let maxImageSize: CGFloat = 1024
    static let imageCompressionQuality: CGFloat = 0.8
}

// MARK: - Constantes de la App
struct AppConstants {
    static let maxMensajesPorMinuto = 10
    static let tiempoMinimoEntreMensajes: TimeInterval = 2.0
    static let maxLongitudTexto = 5000
    static let maxMensajesEnMemoria = 100
    
    // Animaciones
    static let animacionDuracion: Double = 0.3
    static let animacionRebote: Double = 0.5
    
    // Colores
    static let colorPrimario = "AccentColor"
    static let colorSecundario = "SecondaryColor"
}

// MARK: - Estados de la App
enum AppState {
    case idle
    case loading
    case processing
    case error(ErroresApp)
    case success
}

// MARK: - Extensiones Útiles
extension Date {
    func formatoHora() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func formatoCompleto() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

extension String {
    func limpiarTexto() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var esVacio: Bool {
        return self.limpiarTexto().isEmpty
    }
    
    func limitarLongitud(_ limite: Int) -> String {
        if self.count > limite {
            return String(self.prefix(limite)) + "..."
        }
        return self
    }
}
