import Foundation

enum OllamaClient {
    private struct GenerateRequest: Codable {
        let model: String
        let prompt: String
        let stream: Bool
    }

    private struct GenerateResponse: Codable {
        let response: String
        let done: Bool?
    }

    static func sendRequest(_ request: OpenAIRequest, baseURL: String, logger: ((String) -> Void)? = nil) async throws -> [String] {
        guard let url = URL(string: baseURL)?.appendingPathComponent("api/generate") else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = GenerateRequest(model: request.modelName, prompt: request.prompt + "\n" + request.target, stream: false)
        urlRequest.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        if let decoded = try? JSONDecoder().decode(GenerateResponse.self, from: data) {
            logger?("Ollama raw response: \(decoded.response)")
            let text = decoded.response.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.split(separator: "\n").map(String.init)
        }
        return []
    }

    static func sendTextTransformRequest(prompt: String, modelName: String, baseURL: String) async throws -> String {
        guard let url = URL(string: baseURL)?.appendingPathComponent("api/generate") else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = GenerateRequest(model: modelName, prompt: prompt, stream: false)
        urlRequest.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        if let decoded = try? JSONDecoder().decode(GenerateResponse.self, from: data) {
            return decoded.response.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}
