//
//  ReporteErrorView.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 5/7/25.
//
import SwiftUI

struct ReporteErrorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var comentarioUsuario: String = ""
    let historialChat: String

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("¿Qué ocurrió?")) {
                    TextEditor(text: $comentarioUsuario)
                        .frame(minHeight: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                }

                Section(header: Text("Incluir historial del chat")) {
                    ScrollView {
                        Text(historialChat)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: {
                    enviarReporte()
                    dismiss()
                }) {
                    Label("Enviar reporte", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(comentarioUsuario.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .navigationTitle("Reporte de error")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    func enviarReporte() {
        let url = URL(string: "https://script.google.com/macros/s/AKfycbx4wq-ITjOYx53V-74v7nRLfkrf3clU5N3qSY4SWawdveaqXVIewRJzc4ekmo8f5prWgA/exec")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let datos: [String: String] = [
            "comentario": comentarioUsuario,
            "historial": historialChat
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: datos, options: .prettyPrinted)
            request.httpBody = jsonData

            print("📦 Enviando JSON:")
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Error de red: \(error.localizedDescription)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("📬 Código de respuesta: \(httpResponse.statusCode)")
                }

                if let data = data, let respuesta = String(data: data, encoding: .utf8) {
                    print("🔁 Respuesta del servidor: \(respuesta)")
                }
            }.resume()

        } catch {
            print("❌ Error al serializar JSON: \(error)")
        }
    }


}

