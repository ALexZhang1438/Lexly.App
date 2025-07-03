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
    let id = UUID() // Identificador único para cada mensaje (requerido por Identifiable)
    let texto: String // Contenido del mensaje
    let esUsuario: Bool // true si el mensaje fue enviado por el usuario, false si es del asistente
}

// MARK: - Componentes de UI

/// Vista que renderiza una burbuja de mensaje individual
struct BurbujaMensaje: View {
    let mensaje: Mensaje

    var body: some View {
        HStack {
            // Condicional para determinar la alineación del mensaje
            if mensaje.esUsuario {
                // Mensajes del usuario: alineados a la derecha, fondo azul
                Spacer() // Empuja el contenido hacia la derecha
                Text(mensaje.texto)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .frame(maxWidth: 250, alignment: .trailing)
            } else {
                // Mensajes del asistente: alineados a la izquierda, fondo gris
                Text(mensaje.texto)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .frame(maxWidth: 250, alignment: .leading)
                Spacer() // Empuja el contenido hacia la izquierda
            }
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom)) // Animación cuando aparece el mensaje
    }
}

// MARK: - Vista Principal

/// Vista principal de la aplicación de chat legal
struct ContentView: View {
    // MARK: - Estados de la Vista
    
    @State private var entradaTexto = "" // Texto que el usuario está escribiendo
    @State private var mensajes: [Mensaje] = [] // Array de todos los mensajes del chat
    @State private var saludoMostrado = false // Flag para mostrar el saludo inicial solo una vez
    @State private var mostrarPicker = false // Controla si se muestra el selector de imágenes
    @State private var imagenSeleccionada: UIImage? // Imagen seleccionada por el usuario

    var body: some View {
        NavigationStack {
            VStack {
                // MARK: - Área de Chat (ScrollView)
                
                ScrollViewReader { proxy in // Permite hacer scroll programáticamente
                    ScrollView {
                        VStack(spacing: 12) {
                            // Renderiza todos los mensajes usando ForEach
                            ForEach(mensajes) { mensaje in
                                BurbujaMensaje(mensaje: mensaje)
                            }
                        }
                        .padding(.vertical)
                        // Observer que detecta cuando se añaden nuevos mensajes
                        .onChange(of: mensajes.count) {
                            // Hace scroll automático al último mensaje
                            if let ultimo = mensajes.last {
                                withAnimation {
                                    proxy.scrollTo(ultimo.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                Divider() // Línea separadora entre chat y área de entrada

                // MARK: - Área de Entrada de Texto
                
                HStack {
                    // Campo de texto multilínea para escribir mensajes
                    TextField("Escribe o pega el texto legal...", text: $entradaTexto, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3) // Máximo 3 líneas visibles
                    
                    // Botón para adjuntar imágenes
                    Button {
                        mostrarPicker = true // Activa el selector de imágenes
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    .accessibilityLabel("Adjuntar imagen") // Para accesibilidad

                    // Botón para enviar mensaje
                    Button {
                        enviarMensaje() // Llama a la función para enviar mensaje
                    } label: {
                        Image(systemName: "paperplane.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .blue)
                            .font(.system(size: 28))
                    }
                    .accessibilityLabel("Enviar mensaje") // Para accesibilidad
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .navigationTitle("Asistente Legal") // Título de la barra de navegación
            
            // MARK: - Eventos del Ciclo de Vida
            
            .onAppear {
                // Se ejecuta cuando la vista aparece por primera vez
                if !saludoMostrado {
                    mostrarSaludoInicial() // Muestra el mensaje de bienvenida
                    saludoMostrado = true
                }
            }
            
            // MARK: - Selector de Imágenes (Sheet)
            
            .sheet(isPresented: $mostrarPicker) {
                // Presenta el selector de imágenes como una modal
                ImagePicker(image: $imagenSeleccionada)
                    .onDisappear {
                        // Se ejecuta cuando se cierra el selector
                        if let imagen = imagenSeleccionada {
                            enviarImagen(imagen) // Procesa la imagen seleccionada
                        }
                    }
            }
        }
    }

    // MARK: - Funciones Auxiliares

    /// Función que maneja el envío de mensajes de texto
    func enviarMensaje() {
        // Verifica que el texto no esté vacío
        guard !entradaTexto.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // Limpia espacios en blanco del texto
        let textoUsuario = entradaTexto.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Añade el mensaje del usuario al array de mensajes
        mensajes.append(Mensaje(texto: textoUsuario, esUsuario: true))
        
        // Limpia el campo de entrada
        entradaTexto = ""

        // Simula un pequeño retraso antes de generar la respuesta del asistente
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            generarExplicacionIA(para: textoUsuario) { respuesta in
                // Añade la respuesta del asistente cuando se recibe
                mensajes.append(Mensaje(texto: respuesta, esUsuario: false))
            }
        }
    }

    /// Muestra el mensaje de saludo inicial según el idioma del dispositivo
    func mostrarSaludoInicial() {
        // Detecta el idioma del dispositivo
        let idioma = Locale.current.language.languageCode?.identifier ?? "es"

        // Selecciona el saludo apropiado según el idioma
        let saludo: String
        switch idioma {
        case "en":
            saludo = "👋 Hello! I'm your legal assistant. Paste any legal text and I'll explain it in simple terms."
        case "fr":
            saludo = "👋 Bonjour ! Je suis votre assistant juridique. Envoyez-moi un texte juridique et je vous l'expliquerai simplement."
        default:
            saludo = "👋 ¡Hola! Soy tu asistente legal. Pega un texto legal y te lo explicaré con palabras sencillas."
        }

        // Añade el saludo como primer mensaje del asistente
        mensajes.append(Mensaje(texto: saludo, esUsuario: false))
    }

    /// Función que hace la llamada a la API de OpenAI para generar explicaciones
    /// - Parameters:
    ///   - texto: El texto legal que necesita explicación
    ///   - completion: Closure que se ejecuta cuando se recibe la respuesta
    func generarExplicacionIA(para texto: String, completion: @escaping (String) -> Void) {
        // Configura la URL de la API de OpenAI
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return }

        // Headers requeridos para la autenticación y tipo de contenido
        let headers = [
            "Authorization": "Bearer \(openAIAPIKey)", // Clave de API (debe estar definida en otro archivo)
            "Content-Type": "application/json"
        ]

        // Construye el prompt del usuario (función debe estar definida en otro lugar)
        let userPrompt = construirUserPrompt(con: texto)

        // Cuerpo de la petición HTTP con los parámetros de la API
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo", // Modelo de IA a utilizar
            "messages": [
                ["role": "system", "content": systemPrompt], // Prompt del sistema (debe estar definido)
                ["role": "user", "content": userPrompt] // Prompt del usuario
            ],
            "temperature": 0.7 // Controla la creatividad de las respuestas (0-1)
        ]

        // Convierte el diccionario a JSON
        let jsonData = try! JSONSerialization.data(withJSONObject: body)

        // Configura la petición HTTP
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData

        // Ejecuta la petición de red de forma asíncrona
        URLSession.shared.dataTask(with: request) { data, _, _ in
            // Procesa la respuesta de la API
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                // Ejecuta el completion en el hilo principal con la respuesta
                DispatchQueue.main.async {
                    completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            } else {
                // Maneja errores mostrando un mensaje de error
                DispatchQueue.main.async {
                    completion("⚠️ Hubo un error al obtener la explicación del asistente.")
                }
            }
        }.resume() // Inicia la petición
    }

    /// Función que procesa y envía imágenes a la API de OpenAI Vision
    /// - Parameter imagen: La imagen seleccionada por el usuario
    func enviarImagen(_ imagen: UIImage) {
        // Convierte la imagen a base64 y configura la URL
        guard let imageData = imagen.jpegData(compressionQuality: 0.8)?.base64EncodedString(),
              let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return }

        // Headers para la autenticación
        let headers = [
            "Authorization": "Bearer \(openAIAPIKey)",
            "Content-Type": "application/json"
        ]

        // Cuerpo de la petición para análisis de imágenes
        let body: [String: Any] = [
            "model": "gpt-4-vision-preview", // Modelo específico para análisis de imágenes
            "messages": [
                ["role": "user",
                 "content": [
                    ["type": "text", "text": "Describe el contenido de esta imagen en términos legales si aplica."],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(imageData)"]]
                 ]
                ]
            ],
            "max_tokens": 1000 // Límite de tokens para la respuesta
        ]

        // Convierte a JSON y configura la petición
        let jsonData = try! JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData

        // Ejecuta la petición para análisis de imagen
        URLSession.shared.dataTask(with: request) { data, _, _ in
            // Procesa la respuesta del análisis de imagen
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                // Añade la respuesta del análisis como nuevo mensaje
                DispatchQueue.main.async {
                    mensajes.append(Mensaje(texto: content, esUsuario: false))
                }
            }
        }.resume()
    }
}
