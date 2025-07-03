//
//  ContentView.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 29/6/25.
//

import SwiftUI
import Foundation
import AVFoundation
import AVKit

// MARK: - Modelos de Datos

/// Estructura que representa un mensaje individual en el chat
struct Mensaje: Identifiable {
    let id = UUID()
    let texto: String
    let esUsuario: Bool
    let timestamp: Date = Date()
}

/// Enum para manejar diferentes tipos de errores
enum ErroresApp: LocalizedError {
    case apiKeyFaltante
    case networkError
    case invalidResponse
    case contentFiltered
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .apiKeyFaltante:
            return "Configuración de API no encontrada"
        case .networkError:
            return "Error de conexión. Verifica tu internet"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .contentFiltered:
            return "Contenido filtrado por políticas de seguridad"
        case .rateLimitExceeded:
            return "Demasiadas consultas. Espera un momento"
        }
    }
}

// MARK: - Componentes de UI

/// Vista que renderiza una burbuja de mensaje individual
struct BurbujaMensaje: View {
    let mensaje: Mensaje

    var body: some View {
        HStack {
            if mensaje.esUsuario {
                Spacer()
                Text(mensaje.texto)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .frame(maxWidth: 250, alignment: .trailing)
            } else {
                Text(mensaje.texto)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .frame(maxWidth: 250, alignment: .leading)
                Spacer()
            }
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom))
    }
}

/// Vista para mostrar indicador de carga
struct IndicadorCarga: View {
    var body: some View {
        HStack {
            Text("Procesando...")
                .foregroundColor(.gray)
            ProgressView()
                .scaleEffect(0.8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .frame(maxWidth: 250, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: - Vista Principal

struct ContentView: View {
    // MARK: - Estados de la Vista
    
    @State private var entradaTexto = ""
    @State private var mensajes: [Mensaje] = []
    @State private var saludoMostrado = false
    @State private var mostrarPicker = false
    @State private var imagenSeleccionada: UIImage?
    
    // MARK: - Nuevos Estados para Mejoras
    
    @State private var isLoading = false
    @State private var mostrarError = false
    @State private var mensajeError = ""
    @State private var contadorMensajes = 0
    @State private var ultimoMensaje: Date = Date()
    
    // MARK: - Constantes
    
    private let maxMensajesPorMinuto = 10
    private let tiempoMinimoEntreMensajes: TimeInterval = 2.0
    
    var body: some View {
        NavigationStack {
            VStack {
                // MARK: - Área de Chat
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(mensajes) { mensaje in
                                BurbujaMensaje(mensaje: mensaje)
                            }
                            
                            // Mostrar indicador de carga
                            if isLoading {
                                IndicadorCarga()
                                    .id("loading")
                            }
                        }
                        .padding(.vertical)
                        .onChange(of: mensajes.count) {
                            if let ultimo = mensajes.last {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo(ultimo.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: isLoading) {
                            if isLoading {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo("loading", anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                Divider()

                // MARK: - Área de Entrada de Texto
                
                HStack {
                    TextField("Escribe o pega el texto legal...", text: $entradaTexto, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3)
                        .disabled(isLoading)
                    
                    Button {
                        mostrarPicker = true
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 24))
                            .foregroundColor(isLoading ? .gray : .blue)
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Adjuntar imagen")

                    Button {
                        Task {
                            await enviarMensaje()
                        }
                    } label: {
                        Image(systemName: isLoading ? "stop.circle.fill" : "paperplane.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, isLoading ? .red : .blue)
                            .font(.system(size: 28))
                    }
                    .disabled(entradaTexto.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading)
                    .accessibilityLabel(isLoading ? "Cancelar" : "Enviar mensaje")
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .navigationTitle("Asistente Legal")
            .onAppear {
                if !saludoMostrado {
                    mostrarSaludoInicial()
                    saludoMostrado = true
                }
            }
            .sheet(isPresented: $mostrarPicker) {
                ImagePicker(image: $imagenSeleccionada)
                    .onDisappear {
                        if let imagen = imagenSeleccionada {
                            Task {
                                await enviarImagen(imagen)
                            }
                        }
                    }
            }
            .alert("Error", isPresented: $mostrarError) {
                Button("OK") {
                    mostrarError = false
                }
            } message: {
                Text(mensajeError)
            }
        }
    }

    // MARK: - Funciones Auxiliares

    /// Función que maneja el envío de mensajes con validación y rate limiting
    func enviarMensaje() async {
        // Validar entrada
        guard !entradaTexto.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // Rate limiting
        if !validarRateLimit() {
            mostrarErrorPersonalizado(.rateLimitExceeded)
            return
        }
        
        let textoUsuario = entradaTexto.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Filtrar contenido inapropiado
        if contienePalabrasFiltradas(textoUsuario) {
            mostrarErrorPersonalizado(.contentFiltered)
            return
        }
        
        // Añadir mensaje del usuario
        mensajes.append(Mensaje(texto: textoUsuario, esUsuario: true))
        entradaTexto = ""
        isLoading = true
        
        do {
            let respuesta = try await generarExplicacionIA(para: textoUsuario)
            mensajes.append(Mensaje(texto: respuesta, esUsuario: false))
        } catch {
            if let appError = error as? ErroresApp {
                mostrarErrorPersonalizado(appError)
            } else {
                mostrarErrorPersonalizado(.networkError)
            }
        }
        
        isLoading = false
    }

    /// Valida si se puede enviar un mensaje (rate limiting)
    private func validarRateLimit() -> Bool {
        let ahora = Date()
        
        // Verificar tiempo mínimo entre mensajes
        if ahora.timeIntervalSince(ultimoMensaje) < tiempoMinimoEntreMensajes {
            return false
        }
        
        // Verificar límite por minuto (simplificado)
        contadorMensajes += 1
        ultimoMensaje = ahora
        
        if contadorMensajes > maxMensajesPorMinuto {
            return false
        }
        
        return true
    }

    /// Filtro básico de contenido inapropiado
    private func contienePalabrasFiltradas(_ texto: String) -> Bool {
        let palabrasFiltradas = ["spam", "test repetitivo"] // Expandir según necesidades
        let textoMinuscula = texto.lowercased()
        
        return palabrasFiltradas.contains { palabra in
            textoMinuscula.contains(palabra)
        }
    }

    /// Muestra errores personalizados
    private func mostrarErrorPersonalizado(_ error: ErroresApp) {
        mensajeError = error.localizedDescription
        mostrarError = true
    }

    /// Muestra el mensaje de saludo inicial
    func mostrarSaludoInicial() {
        let idioma = Locale.current.language.languageCode?.identifier ?? "es"
        let saludo: String
        
        switch idioma {
        case "en":
            saludo = "👋 Hello! I'm your legal assistant. Paste any legal text and I'll explain it in simple terms."
        case "fr":
            saludo = "👋 Bonjour ! Je suis votre assistant juridique. Envoyez-moi un texte juridique et je vous l'expliquerai simplement."
        default:
            saludo = "👋 ¡Hola! Soy tu asistente legal. Pega un texto legal y te lo explicaré con palabras sencillas."
        }
        
        mensajes.append(Mensaje(texto: saludo, esUsuario: false))
    }

    /// Función mejorada para generar explicaciones con manejo robusto de errores
    func generarExplicacionIA(para texto: String) async throws -> String {
        // Validar configuración
        guard !Config.openAIAPIKey.isEmpty else {
            throw ErroresApp.apiKeyFaltante
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw ErroresApp.networkError
        }

        let headers = [
            "Authorization": "Bearer \(Config.openAIAPIKey)",
            "Content-Type": "application/json"
        ]

        let userPrompt = construirUserPrompt(con: texto)
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]

        // Manejo seguro de JSON
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw ErroresApp.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData
        request.timeoutInterval = 30

        // Realizar petición con async/await
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Verificar respuesta HTTP
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    throw ErroresApp.rateLimitExceeded
                } else if httpResponse.statusCode >= 400 {
                    throw ErroresApp.networkError
                }
            }
            
            // Procesar respuesta JSON
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw ErroresApp.invalidResponse
            }
            
            let respuestaLimpia = content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Validar respuesta
            if respuestaLimpia.isEmpty || respuestaLimpia.count > 5000 {
                throw ErroresApp.invalidResponse
            }
            
            return respuestaLimpia
            
        } catch {
            if error is ErroresApp {
                throw error
            } else {
                throw ErroresApp.networkError
            }
        }
    }

    /// Función mejorada para enviar imágenes
    func enviarImagen(_ imagen: UIImage) async {
        // Optimizar compresión según tamaño
        let compressionQuality: CGFloat = imagen.size.width > 1000 ? 0.5 : 0.8
        
        guard let imageData = imagen.jpegData(compressionQuality: compressionQuality)?.base64EncodedString(),
              let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            mostrarErrorPersonalizado(.invalidResponse)
            return
        }

        isLoading = true
        
        let headers = [
            "Authorization": "Bearer \(Config.openAIAPIKey)",
            "Content-Type": "application/json"
        ]

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

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = jsonData
            request.timeoutInterval = 45

            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                let respuestaLimpia = content.trimmingCharacters(in: .whitespacesAndNewlines)
                mensajes.append(Mensaje(texto: respuestaLimpia, esUsuario: false))
            } else {
                throw ErroresApp.invalidResponse
            }
        } catch {
            mostrarErrorPersonalizado(.networkError)
        }
        
        isLoading = false
    }
}

// MARK: - Extensiones

extension ContentView {
    /// Resetea el contador de mensajes cada minuto
    private func resetearContadorMensajes() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            contadorMensajes = 0
        }
    }
}
