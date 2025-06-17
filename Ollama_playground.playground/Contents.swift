import Foundation
import PlaygroundSupport

// Swift標準にないので自作
struct AnyCodable: Codable {
    let value: Any
    init(_ value: Any) {
        self.value = value
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let string as String:
            try container.encode(string)
        default:
            throw EncodingError.invalidValue(
                value,
                .init(codingPath: encoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let string = try? container.decode(String.self) {
            value = string
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }
}

struct GenerateRequest: Codable {
    let model: String
    let prompt: String
    let options: [String: AnyCodable]? // Optional
}

// デコードエラー対策済み
struct GenerateResponse: Decodable {
    let response: String?
    let done: Bool
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        response = try container.decodeIfPresent(String.self, forKey: .response)
        done = try container.decode(Bool.self, forKey: .done)
    }
    enum CodingKeys: String, CodingKey {
        case response, done
    }
}

func generateText(prompt: String) async throws -> String {
    guard let url = URL(string: "http://127.0.0.1:11434/api/generate") else {
        throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body = GenerateRequest(
        model: "llama3.2:1b",  // モデル名を変更
        prompt: prompt,
        options: nil
    )
    request.httpBody = try JSONEncoder().encode(body)
    
    print("📤 リクエスト送信中...")
    let (stream, response) = try await URLSession.shared.bytes(for: request)
    
    // HTTPレスポンスステータスをチェック
    if let httpResponse = response as? HTTPURLResponse {
        print("📡 HTTPステータス: \(httpResponse.statusCode)")
    }
    
    var result = ""
    var lineCount = 0
    
    for try await line in stream.lines {
        lineCount += 1
        print("📥 受信行 \(lineCount): \(line)")
        
        guard let data = line.data(using: .utf8) else {
            print("⚠️ UTF-8変換失敗")
            continue
        }
        
        do {
            let decoded = try JSONDecoder().decode(GenerateResponse.self, from: data)
            print("✅ JSON解析成功 - response: \(decoded.response ?? "nil"), done: \(decoded.done)")
            
            if let res = decoded.response {
                result += res
                print("🔄 現在の結果長: \(result.count)")
            }
            if decoded.done {
                print("🏁 生成完了")
                break
            }
        } catch {
            print("⚠️ JSONデコード失敗: \(error)")
            print("⚠️ 生データ: \(line)")
            continue
        }
    }
    
    print("📊 最終結果長: \(result.count)")
    return result
}

func checkAvailableModels() async throws -> [String] {
    guard let url = URL(string: "http://127.0.0.1:11434/api/tags") else {
        throw URLError(.badURL)
    }
    let (data, _) = try await URLSession.shared.data(from: url)
    
    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
       let models = json["models"] as? [[String: Any]] {
        return models.compactMap { $0["name"] as? String }
    }
    return []
}

func checkOllamaConnection() async throws -> Bool {
    guard let url = URL(string: "http://127.0.0.1:11434") else {
        throw URLError(.badURL)
    }
    let (_, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }
    return httpResponse.statusCode == 200
}

// Playground用：非同期処理を同期的に実行
PlaygroundPage.current.needsIndefiniteExecution = true

Task {
    do {
        print("🔍 Ollama接続チェック中...")
        let isConnected = try await checkOllamaConnection()
        print(isConnected ? "✅ 接続OK" : "❌ 接続NG")
        
        if isConnected {
            // 利用可能なモデルを確認
            print("📋 利用可能なモデル確認中...")
            let models = try await checkAvailableModels()
            print("📋 利用可能なモデル: \(models)")
            
            print("🚀 テキスト生成開始...")
            let output = try await generateText(prompt: "日本の四季について説明して")
            print("📝 生成結果:")
            print("「\(output)」")
            print("📏 結果の文字数: \(output.count)")
        }
    } catch {
        print("⚠️ エラー: \(error)")
    }
    
    // Playground終了
    PlaygroundPage.current.finishExecution()
}
