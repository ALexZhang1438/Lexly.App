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
//

import Foundation

struct Config {
    
    // MARK: - API Configuration
    
    /// Clave API de OpenAI - debe estar en Secret.swift
    static let openAIAPIKey: String = {
        #if DEBUG
        return Secret.openAIAPIKey
        #else
        // En producción, considera usar un backend propio
        return Secret.openAIAPIKey
        #endif
    }()
    
    // MARK: - App Configuration
    
    /// Límites de uso para evitar costos excesivos
    struct Limits {
        static let maxMessagesPerMinute = 10
        static let maxMessagesPerDay = 100
        static let minTimeBetweenMessages: TimeInterval = 2.0
        static let maxMessageLength = 2000
        static let maxResponseLength = 5000
    }
    
    /// Configuración de la API
    struct API {
        static let timeout: TimeInterval = 30.0
        static let maxRetries = 3
        static let baseURL = "https://api.openai.com/v1/"
        
        // Modelos disponibles
        static let textModel = "gpt-3.5-turbo"
        static let visionModel = "gpt-4-vision-preview"
        
        // Parámetros por defecto
        static let defaultTemperature: Double = 0.7
        static let defaultMaxTokens = 1000
    }
    
    /// Configuración de contenido y filtros
    struct Content {
        // Palabras que activarán el filtro de contenido
        static let filteredWords = [
            "spam", "test repetitivo", "insulto", "ofensivo"
            // Añade más palabras según necesites
        ]
        
        // Patrones de texto sospechosos
        static let suspiciousPatterns = [
            "(..)\\1{10,}", // Repetición excesiva de caracteres
            "http[s]?://[^\\s]+", // URLs (opcional)
        ]
    }
    
    /// Mensajes de error localizados
    struct ErrorMessages {
        static let apiKeyMissing = "Configuración de API no encontrada"
        static let networkError = "Error de conexión. Verifica tu internet"
        static let rateLimitExceeded = "Demasiadas consultas. Espera un momento"
        static let contentFiltered = "Contenido filtrado por políticas de seguridad"
        static let invalidResponse = "Respuesta inválida del servidor"
        static let servicePaused = "Servicio temporalmente pausado"
    }
    
    // MARK: - Feature Flags
    
    /// Controla qué funcionalidades están habilitadas
    struct Features {
        static let imageAnalysis = true
        static let messageHistory = true
        static let offlineMode = false
        static let analytics = false
        static let crashReporting = true
    }
    
    // MARK: - Debug Configuration
    
    #if DEBUG
    struct Debug {
        static let enableLogging = true
        static let logAPIRequests = true
        static let simulateErrors = false
        static let skipRateLimit = false
    }
    #endif
}

// MARK: - Validation Extensions

extension Config {
    /// Valida que la configuración sea correcta
    static func validateConfiguration() -> Bool {
        // Verificar que la API key no esté vacía
        guard !openAIAPIKey.isEmpty else {
            print("❌ API Key no configurada")
            return false
        }
        
        // Verificar que la API key tenga el formato correcto
        guard openAIAPIKey.hasPrefix("sk-") else {
            print("❌ API Key no tiene el formato correcto")
            return false
        }
        
        print("✅ Configuración validada correctamente")
        return true
    }
    
    /// Obtiene la configuración actual como string para debugging
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
