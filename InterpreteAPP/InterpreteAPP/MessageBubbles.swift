//  MessageBubbles.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 29/6/25.
//

import SwiftUI

// MARK: - Burbuja de Mensaje Optimizada
struct BurbujaMensaje: View {
    let mensaje: Mensaje
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if mensaje.esUsuario {
                Spacer(minLength: 60)
                UserMessageBubble(mensaje: mensaje)
            } else {
                AssistantMessageBubble(mensaje: mensaje)
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        ))
    }
}

// MARK: - Burbuja del Usuario
struct UserMessageBubble: View {
    let mensaje: Mensaje
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(mensaje.texto)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(BubbleShape(isUser: true))
                .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 2)
            
            Text(mensaje.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.trailing, 8)
        }
    }
}

// MARK: - Burbuja del Asistente
struct AssistantMessageBubble: View {
    let mensaje: Mensaje
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar del asistente
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "scales.of.justice")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                )
                .shadow(color: .purple.opacity(0.3), radius: 2, x: 0, y: 1)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mensaje.texto)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .clipShape(BubbleShape(isUser: false))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Text(mensaje.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
            }
        }
    }
}

// MARK: - Forma de Burbuja Personalizada
struct BubbleShape: Shape {
    let isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: isUser ?
                [.topLeft, .topRight, .bottomLeft] :
                [.topLeft, .topRight, .bottomRight],
            cornerRadii: CGSize(width: 18, height: 18)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Indicador de Carga Mejorado
struct IndicadorCarga: View {
    @State private var animating = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Avatar del asistente
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "scales.of.justice")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                )
                .scaleEffect(animating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(), value: animating)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Analizando...")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .scaleEffect(animating ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: animating
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
                .clipShape(BubbleShape(isUser: false))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 16)
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    VStack {
        BurbujaMensaje(mensaje: Mensaje(texto: "Hola, ¿puedes ayudarme con este contrato?", esUsuario: true))
        BurbujaMensaje(mensaje: Mensaje(texto: "¡Por supuesto! Te ayudo a explicar cualquier texto legal de manera sencilla.", esUsuario: false))
        IndicadorCarga()
    }
    .padding()
}
