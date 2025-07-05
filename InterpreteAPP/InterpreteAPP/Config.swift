//
//  Config.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 3/7/25.
//
//  Config.swift
//  InterpreteAPP
//
//  Configuración centralizada para la aplicación
//  Este archivo contiene todas las configuraciones importantes de la app
//  como límites de uso, URLs de API, modelos, etc.
//

import Foundation

// MARK: - Estructura principal de configuración
// Esta estructura centraliza toda la configuración de la aplicación
// para facilitar el mantenimiento y evitar duplicación de código
struct Config {
    
    // MARK: - Configuración de API
    
    /// Clave API de OpenAI - debe estar en Secret.swift
    /// Esta propiedad obtiene la clave API de forma segura
    /// En modo DEBUG usa la clave de desarrollo, en producción usa la de producción
    static let openAIAPIKey: String = {
        #if DEBUG
        // En desarrollo, usa la clave de desarrollo
        return Secret.openAIAPIKey
        #else
        // En producción, considera usar un backend propio para mayor seguridad
        return Secret.openAIAPIKey
        #endif
    }()
    
    // MARK: - Configuración de la aplicación
    
    /// Límites de uso para evitar costos excesivos
    /// Estos límites protegen contra el uso excesivo de la API
    /// y ayudan a controlar los costos de OpenAI
    struct Limits {
        static let maxMessagesPerMinute = 10  // Máximo 10 mensajes por minuto
        static let maxMessagesPerDay = 100    // Máximo 100 mensajes por día
        static let minTimeBetweenMessages: TimeInterval = 2.0  // Mínimo 2 segundos entre mensajes
        static let maxMessageLength = 2000    // Máximo 2000 caracteres por mensaje
        static let maxResponseLength = 5000   // Máximo 5000 caracteres en respuesta
    }
    
    /// Configuración específica de la API de OpenAI
    /// Contiene URLs, timeouts, modelos y parámetros de la API
    struct API {
        static let timeout: TimeInterval = 30.0  // Timeout de 30 segundos para peticiones
        static let maxRetries = 3                // Máximo 3 reintentos si falla una petición
        static let baseURL = "https://api.openai.com/v1/"  // URL base de la API de OpenAI
        
        // Modelos disponibles de OpenAI
        static let textModel = "gpt-3.5-turbo"  // Modelo para texto (más rápido y económico)
        static let visionModel = "gpt-4o"       // Modelo para análisis de imágenes (más potente)
        
        // Parámetros por defecto para las peticiones
        static let defaultTemperature: Double = 0.7  // Controla la creatividad (0.0 = muy conservador, 1.0 = muy creativo)
        static let defaultMaxTokens = 1000          // Máximo número de tokens en la respuesta
        
        // Configuración específica para procesamiento de imágenes
        static let maxImageSize: CGFloat = 1024     // Tamaño máximo de imagen en píxeles
        static let imageCompressionQuality: CGFloat = 0.8  // Calidad de compresión de imagen (0.0 = muy comprimida, 1.0 = sin comprimir)
    }
    
    /// Configuración de filtros de contenido
    /// Ayuda a prevenir el envío de contenido inapropiado o spam
    struct Content {
        // Palabras que activarán el filtro de contenido
        // Si un mensaje contiene estas palabras, será rechazado
        static let filteredWords = [
            "spam", "test repetitivo", "insulto", "ofensivo"
            // Añade más palabras según necesites
        ]
        
        // Patrones de texto sospechosos (expresiones regulares)
        // Se usan para detectar patrones de spam o contenido inapropiado
        static let suspiciousPatterns = [
            "(..)\\1{10,}", // Repetición excesiva de caracteres (ej: aaaaaaaaaa)
            "http[s]?://[^\\s]+", // URLs (opcional, para prevenir spam con links)
        ]
    }
    
    /// Mensajes de error localizados
    /// Estos mensajes se muestran al usuario cuando ocurren errores
    /// Están en español para mejor experiencia de usuario
    struct ErrorMessages {
        static let apiKeyMissing = "Configuración de API no encontrada"
        static let networkError = "Error de conexión. Verifica tu internet"
        static let rateLimitExceeded = "Demasiadas consultas. Espera un momento"
        static let contentFiltered = "Contenido filtrado por políticas de seguridad"
        static let invalidResponse = "Respuesta inválida del servidor"
        static let servicePaused = "Servicio temporalmente pausado"
    }
    
    // MARK: - Banderas de funcionalidades (Feature Flags)
    
    /// Controla qué funcionalidades están habilitadas
    /// Permite activar/desactivar características sin cambiar código
    struct Features {
        static let imageAnalysis = true    // Análisis de imágenes con IA
        static let messageHistory = true   // Historial de mensajes
        static let offlineMode = false     // Modo offline (no implementado aún)
        static let analytics = false       // Análisis de uso (no implementado aún)
        static let crashReporting = true   // Reportes de errores
    }
    
    // MARK: - Configuración de depuración (solo en modo DEBUG)
    
    #if DEBUG
    /// Configuraciones específicas para desarrollo y depuración
    /// Solo están disponibles cuando la app se compila en modo DEBUG
    struct Debug {
        static let enableLogging = true        // Habilita logs detallados
        static let logAPIRequests = true       // Registra todas las peticiones a la API
        static let simulateErrors = false      // Simula errores para testing
        static let skipRateLimit = false       // Salta los límites de rate para testing
    }
    #endif
}

// MARK: - Extensiones para validación y utilidades

extension Config {
    /// Valida que la configuración sea correcta
    /// Verifica que las claves de API estén configuradas y tengan el formato correcto
    /// Retorna true si todo está bien, false si hay problemas
    static func validateConfiguration() -> Bool {
        // Verificar que la API key no esté vacía
        guard !openAIAPIKey.isEmpty else {
            print("❌ API Key no configurada")
            return false
        }
        
        // Verificar que la API key tenga el formato correcto (empiece con sk-)
        guard openAIAPIKey.hasPrefix("sk-") else {
            print("❌ API Key no tiene el formato correcto")
            return false
        }
        
        print("✅ Configuración validada correctamente")
        return true
    }
    
    /// Obtiene la configuración actual como string para debugging
    /// Útil para ver el estado actual de la configuración en la consola
    static func getConfigSummary() -> String {
        return """
        📱 Configuración de la App:
        - Modelo de texto: \(API.textModel)
        - Modelo de visión: \(API.visionModel)
        - Límite msg/min: \(Limits.maxMessagesPerMinute)
        - Timeout: \(API.timeout)s
        - Análisis de imagen: \(Features.imageAnalysis ? "✅" : "❌")
        """
    }
}
