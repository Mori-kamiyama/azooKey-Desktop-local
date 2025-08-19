import Foundation
import Ollama

// Ollamaのリクエスト構造体

struct OllamaRequest {
    let prompt: String
    let c: String
    let modelName: String
}

// MARK: - Error Types

enum OllamaError: LocalizedError {
    case noResponse
    case parseError(String)
    case ollamaError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noResponse:
            return "Ollamaからの応答がありません"
        case .parseError(let message):
            return "応答の解析に失敗: \(message)"
        case .ollamaError(let error):
            return "Ollamaエラー: \(error.localizedDescription)"
        }
    }
}



// MARK: - Ollama Client
enum OllamaClient {
    // APIリクエストを送信する静的メソッド
    static func sendRequest(_ request: OllamaRequest, inputUrl: String?) async throws -> [String] {
        // URLの決定（優先度: 引数 > 設定 > デフォルト）
        let configUrl = Config.OllamaURL().value
        let base = (inputUrl?.isEmpty == false) ? inputUrl! :
                   (!configUrl.isEmpty ? configUrl : Config.OllamaURL.default)

        guard let baseURL = URL(string: base) else {
            throw OllamaError.parseError("無効なURL: \(base)")
        }

        let ollama = await Client(host: baseURL)
        
        let response = try await ollama.generate(
            model: Model.ID(stringLiteral: request.modelName),
            prompt: request.prompt,
            options: ["temperature": 0.7, "max_tokens": 100],
            keepAlive: .minutes(2)  // モデルを10分間メモリにキャッシュ
        )
        
        // レスポンスの検証
        guard !response.response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OllamaError.noResponse
        }

        return [response.response]
    }


    // Simple text transformation method for AI Transform feature
    static func sendTextTransformRequest(prompt: String, modelName: String, inputUrl: String? = nil) async throws -> String {
        // URLの決定（優先度: 引数 > 設定 > デフォルト）
        let configUrl = Config.OllamaURL().value
        let base = (inputUrl?.isEmpty == false) ? inputUrl! :
                   (!configUrl.isEmpty ? configUrl : Config.OllamaURL.default)

        guard let baseURL = URL(string: base) else {
            throw OllamaError.parseError("無効なURL: \(base)")
        }

        let ollama = await Client(host: baseURL)
        
        let response = try await ollama.generate(
            model: Model.ID(stringLiteral: modelName),
            prompt: "You are a helpful assistant that transforms text according to user instructions.\(prompt)",
            options: [
                "max_tokens": 150,
                "temperature": 0.7
            ],
            keepAlive: .minutes(10)
        )
        
        let text = response.response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw OllamaError.noResponse }
        return text
    }
}


