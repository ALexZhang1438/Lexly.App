//
//  Models.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 29/6/25.
//

import Foundation

// MARK: - Modelo de Mensaje
// Esta estructura representa un mensaje individual en el chat
// Se usa para mostrar mensajes del usuario y del asistente
struct Mensaje: Identifiable, Equatable {
    let id = UUID()           // Identificador único del mensaje
    let texto: String         // Contenido del mensaje
    let esUsuario: Bool       // true si es del usuario, false si es del asistente
    let timestamp: Date       // Fecha y hora cuando se creó el mensaje
    
    /// Inicializador del mensaje
    /// - Parameters:
    ///   - texto: El contenido del mensaje
    ///   - esUsuario: Indica si el mensaje es del usuario o del asistente
    init(texto: String, esUsuario: Bool) {
        self.texto = texto
        self.esUsuario = esUsuario
        self.timestamp = Date()  // Se asigna automáticamente la fecha actual
    }
    
    /// Compara dos mensajes para verificar si son iguales
    /// Se usa para optimizar la UI y evitar re-renderizados innecesarios
    static func == (lhs: Mensaje, rhs: Mensaje) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Tipos de Error
// Esta enumeración define todos los tipos de errores que pueden ocurrir en la app
// Cada error tiene un mensaje descriptivo y una sugerencia de recuperación
enum ErroresApp: LocalizedError {
    case apiKeyFaltante          // La clave API no está configurada o es inválida
    case networkError            // Error de conexión a internet
    case invalidResponse         // La respuesta del servidor no tiene el formato esperado
    case contentFiltered         // El contenido fue filtrado por políticas de seguridad
    case rateLimitExceeded       // Se excedió el límite de peticiones por minuto
    case imageProcessingError    // Error al procesar una imagen
    case generalError(String)    // Error general con mensaje personalizado
    
    /// Descripción del error que se muestra al usuario
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
    
    /// Sugerencia de cómo resolver el error
    /// Ayuda al usuario a entender qué puede hacer para solucionarlo
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

// MARK: - Configuración (Consolidada en Config.swift)
// Las configuraciones se han movido a Config.swift para evitar duplicación

// MARK: - Extensiones Útiles

// MARK: - Extensión de Date para formateo
// Añade funcionalidad de formateo de fechas a la clase Date
extension Date {
    /// Formatea la fecha para mostrar solo la hora (ej: "14:30")
    func formatoHora() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Formatea la fecha para mostrar fecha y hora completas (ej: "15 Ene 2024, 14:30")
    func formatoCompleto() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Extensión de String para utilidades
// Añade funcionalidades útiles para el procesamiento de texto
extension String {
    /// Elimina espacios en blanco al inicio y final del texto
    func limpiarTexto() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Verifica si el texto está vacío después de limpiarlo
    var esVacio: Bool {
        return self.limpiarTexto().isEmpty
    }
    
    /// Limita la longitud del texto y añade "..." si es muy largo
    /// - Parameter limite: La longitud máxima permitida
    /// - Returns: El texto truncado si es necesario
    func limitarLongitud(_ limite: Int) -> String {
        if self.count > limite {
            return String(self.prefix(limite)) + "..."
        }
        return self
    }
}
