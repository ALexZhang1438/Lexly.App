//
//  ContentView.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 29/6/25.
//

import SwiftUI

// MARK: - Modelos de Datos (Considerar mover a Models.swift)
// Si `Mensaje` y `ErroresApp` no se usan en ningún otro lugar fuera del flujo de chat,
// podrían anidarse o mantenerse cerca. Si son globales, un archivo de Modelos es mejor.
// Por ahora, se asume que son accesibles (ej. definidas aquí o en otro archivo importado).

/// Estructura que representa un mensaje individual en el chat
struct Mensaje: Identifiable {
    let id = UUID()
    let texto: String
    let esUsuario: Bool
    let timestamp: Date = Date()
}

/// Enum para manejar diferentes tipos de errores de la aplicación.
/// Los mensajes de error localizados ahora se obtienen de `Config.ErrorMessages`
/// a través de `ChatViewModel`, pero el `enum` sigue siendo útil para la tipificación de errores.
enum ErroresApp: LocalizedError {
    case apiKeyFaltante
    case networkError
    case invalidResponse
    case contentFiltered
    case rateLimitExceeded
    
    // `errorDescription` puede seguir siendo útil para contextos donde no se usa `Config.ErrorMessages`
    // o para dar un fallback.
    var errorDescription: String? {
        switch self {
        case .apiKeyFaltante: return "API Key no configurada."
        case .networkError: return "Error de conexión."
        case .invalidResponse: return "Respuesta inválida del servidor."
        case .contentFiltered: return "Contenido filtrado."
        case .rateLimitExceeded: return "Límite de solicitudes excedido."
        }
    }
}


// MARK: - Componentes de UI (BurbujaMensaje, IndicadorCarga)
// Estos podrían moverse a sus propios archivos si se vuelven complejos o se reutilizan mucho.

/// Vista que renderiza una burbuja de mensaje individual.
struct BurbujaMensaje: View {
    let mensaje: Mensaje

    var body: some View {
        HStack {
            if mensaje.esUsuario {
                Spacer()
                Text(mensaje.texto)
                    .padding(10)
                    .background(Color.accentColor) // Usar AccentColor para mensajes de usuario
                    .foregroundColor(.white) // Texto blanco sobre AccentColor
                    .cornerRadius(16)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing) // Limitar ancho
            } else {
                Text(mensaje.texto)
                    .padding(10)
                    .background(Color(UIColor.systemGray5)) // Un gris más suave para el sistema
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading) // Limitar ancho
                Spacer()
            }
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

/// Vista para mostrar un indicador de carga mientras se procesa una solicitud.
struct IndicadorCarga: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView().scaleEffect(0.7)
            Text("Procesando...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}


// MARK: - Vista Principal

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var mostrarPicker = false // Controla la presentación del ImagePicker
    @State private var imagenSeleccionada: UIImage? // Almacena la imagen seleccionada

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) { // Eliminar espaciado por defecto del VStack principal
                // Vista de Mensajes
                ChatMessagesView(viewModel: viewModel)
                
                Divider()

                // Vista de Entrada de Texto
                ChatInputView(viewModel: viewModel, mostrarPicker: $mostrarPicker)
            }
            .navigationTitle("Asistente Legal")
            .navigationBarTitleDisplayMode(.inline) // Título más compacto
            // El saludo inicial es manejado por el ChatViewModel en su init.
            // .onAppear {
            // viewModel.mostrarSaludoInicialSiNecesario()
            // }
            .sheet(isPresented: $mostrarPicker) {
                ImagePicker(image: $imagenSeleccionada)
            }
            // Observar cambios en la imagen seleccionada para enviarla a través del ViewModel
            .onChange(of: imagenSeleccionada) { nuevaImagen in
                if let img = nuevaImagen {
                    Task {
                        await viewModel.enviarImagen(img)
                    }
                    imagenSeleccionada = nil // Resetear después de enviar
                }
            }
            // Alerta para mostrar errores provenientes del ViewModel
            .alert(viewModel.mensajeError, isPresented: $viewModel.mostrarError) { // Título del alert es el mensaje
                Button("OK") {
                    // Opcional: Alguna acción al cerrar el alert, como limpiar el error en el VM
                    // viewModel.mostrarError = false // El VM podría manejar esto internamente si es necesario
                }
            }
            // Añadir un gesto para ocultar el teclado cuando se toca fuera del área de texto
            .onTapGesture {
                hideKeyboard()
            }
        }
        // Aplicar un estilo de fondo si es necesario, o para interacciones con el teclado
        // .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Ya no se necesitan extensiones ni funciones de lógica de chat en ContentView,
// todo eso ha sido movido a ChatViewModel o a las sub-vistas.
