//
//  ChatInputView.swift
//  InterpreteAPP
//
//  Created by Jules on 7/7/24.
//

import SwiftUI

struct ChatInputView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var mostrarPicker: Bool // Binding para controlar el ImagePicker desde ContentView

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) { // Alineación .bottom para multilínea TextField
            TextField("Escribe o pega el texto legal...", text: $viewModel.entradaTexto, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .disabled(viewModel.isLoading)
                // Añadir un poco de padding interno al TextField si es necesario
                // .padding(.vertical, 8)

            // Botón para adjuntar imagen
            if Config.Features.imageAnalysis {
                Button {
                    // Ocultar teclado si está visible antes de mostrar el picker
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    mostrarPicker = true
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.isLoading ? .gray : .accentColor) // Usar AccentColor
                }
                .disabled(viewModel.isLoading)
                .accessibilityLabel("Adjuntar imagen")
            }

            // Botón para enviar mensaje
            Button {
                Task {
                    await viewModel.enviarMensajeUsuario()
                }
            } label: {
                Image(systemName: viewModel.isLoading ? "stop.circle.fill" : "paperplane.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(viewModel.isLoading ? Color.red : Color.white, Color.accentColor) // Ajustar colores, blanco para el ícono interno
                    .font(.system(size: 28))
                    .animation(.easeInOut, value: viewModel.isLoading) // Animar cambio de ícono
            }
            .disabled(viewModel.entradaTexto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading)
            .accessibilityLabel(viewModel.isLoading ? "Cancelar" : "Enviar mensaje")
            // Considerar un frame fijo para el botón para evitar que el TextField se mueva mucho
            // .frame(width: 30, height: 30)
        }
        .padding(.horizontal)
        .padding(.top, 8) // Espacio arriba del input area
        .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom == 0 ? 10 : 0) // Padding inferior solo si no hay safe area
    }
}

// Notas:
// - El ViewModel se pasa como `ObservedObject`.
// - `mostrarPicker` es un `@Binding` para que `ContentView` pueda controlar la presentación de `ImagePicker`.
// - La lógica de deshabilitar botones y la acción de envío son las mismas que en `ContentView`.
// - Se usa `Config.Features.imageAnalysis` para mostrar condicionalmente el botón de adjuntar imagen.
// - Se añadió un pequeño padding superior y un padding inferior condicional para mejorar el espaciado,
//   especialmente en dispositivos sin notch.
// - Se añadió una animación al botón de enviar/cancelar.
// - Se añadió `UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder)...` para ocultar el teclado
//   antes de mostrar el `ImagePicker`, lo cual es una mejor práctica de UX.
// - `Color.accentColor` se usa para el botón de imagen para consistencia.
// - El `HStack` tiene `alignment: .bottom` para que los botones se alineen con la base del `TextField`
//   cuando este crece por múltiples líneas de texto.
// - Se puede considerar añadir `.padding(.vertical, 8)` al `TextField` si el estilo `.roundedBorder`
//   no da suficiente espacio vertical interno cuando el texto es multilínea.
