//
//  OpenAIAssistantService.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 4/7/25.
//
import Foundation

// MARK: - Servicio de Asistente de OpenAI
class OpenAIAssistantService {
    private let session = URLSession.shared
    private let baseURL = "https://api.openai.com/v1"
    private var threadID: String?

    // MARK: - Crear nuevo thread
    func crearThread() async throws {
        let url = URL(string: "\(baseURL)/threads")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Secret.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        request.httpBody = "{}".data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ErroresApp.networkError
        }

        switch httpResponse.statusCode {
        case 200...299:
            let json = try JSONDecoder().decode(ThreadResponse.self, from: data)
            self.threadID = json.id
        case 401:
            throw ErroresApp.apiKeyFaltante
        case 429:
            throw ErroresApp.rateLimitExceeded
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Respuesta no legible"
            throw ErroresApp.generalError("Error HTTP \(httpResponse.statusCode): \(errorMessage)")
        }
    }

    // MARK: - Enviar mensaje y obtener respuesta
    func enviarMensaje(_ texto: String) async throws -> String {
        if threadID == nil {
            try await crearThread()
        }

        guard let threadID = threadID else {
            throw ErroresApp.networkError
        }

        // Enviar mensaje
        var messageRequest = URLRequest(url: URL(string: "\(baseURL)/threads/\(threadID)/messages")!)
        messageRequest.httpMethod = "POST"
        messageRequest.setValue("Bearer \(Secret.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        messageRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        messageRequest.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")

        let messageBody: [String: Any] = ["role": "user", "content": texto]
        messageRequest.httpBody = try JSONSerialization.data(withJSONObject: messageBody)
        _ = try await session.data(for: messageRequest)

        // Ejecutar asistente
        var runRequest = URLRequest(url: URL(string: "\(baseURL)/threads/\(threadID)/runs")!)
        runRequest.httpMethod = "POST"
        runRequest.setValue("Bearer \(Secret.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        runRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        runRequest.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")

        let runBody: [String: Any] = ["assistant_id": Secret.openAIAssistantID]
        runRequest.httpBody = try JSONSerialization.data(withJSONObject: runBody)
        let (runData, _) = try await session.data(for: runRequest)
        let run = try JSONDecoder().decode(RunResponse.self, from: runData)

        // Esperar completado
        try await waitForRunCompletion(threadID: threadID, runID: run.id)

        // Obtener respuesta
        let messagesURL = URL(string: "\(baseURL)/threads/\(threadID)/messages")!
        var messagesRequest = URLRequest(url: messagesURL)
        messagesRequest.setValue("Bearer \(Secret.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        messagesRequest.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")

        let (data, _) = try await session.data(for: messagesRequest)
        let messages = try JSONDecoder().decode(MessagesResponse.self, from: data)

        return messages.data.first?.content.first?.text.value ?? "Error: sin respuesta."
    }

    // MARK: - Esperar completación
    private func waitForRunCompletion(threadID: String, runID: String) async throws {
        let url = URL(string: "\(baseURL)/threads/\(threadID)/runs/\(runID)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(Secret.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")

        for _ in 0..<30 {
            let (data, _) = try await session.data(for: request)
            let status = try JSONDecoder().decode(RunResponse.self, from: data).status
            if status == "completed" { return }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }

        throw ErroresApp.generalError("Tiempo de espera excedido.")
    }
}

// MARK: - Decodificadores JSON

struct ThreadResponse: Decodable {
    let id: String
}

struct RunResponse: Decodable {
    let id: String
    let status: String
}

struct MessagesResponse: Decodable {
    struct Message: Decodable {
        struct Content: Decodable {
            struct Text: Decodable {
                let value: String
            }
            let text: Text
        }
        let content: [Content]
    }
    let data: [Message]
}
