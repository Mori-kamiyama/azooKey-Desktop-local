# Ollama ネイティブ対応 TODO

## 設計方針決定

### **個別クライアント方式を採用**
他の人との連携と既存コードとの一貫性を考慮し、**OllamaClient.swift として独立実装**する方針とします。

#### 採用理由
1. **既存パターンとの一貫性**: OpenAIClient.swift と同じ構造
2. **段階的実装**: 既存コードに影響を与えずに開発可能
3. **責任の分離**: 各AIプロバイダーの特性に応じた最適化が可能
4. **保守性**: バグ修正や機能追加の影響範囲が明確
5. **チーム開発**: 複数人での並行開発が容易

## 現在の実装状況
- ✅ 設定UI（ConfigWindow.swift）
- ✅ 接続テスト機能
- ✅ 設定項目の定義（Config）
- ❌ **実際のテキスト変換処理は未実装**

## 必要な実装項目

### 1. OllamaClient の実装
**ファイル**: `azooKeyMac/InputController/OllamaClient.swift`（新規作成）

#### 1.1 基本クライアント構造
- [ ] `enum OllamaClient` として実装（OpenAIClient と同じパターン）
- [ ] OpenAIClient.swift の `Prompt.dictionary` を共有利用
- [ ] エラーハンドリングの実装

#### 1.2 HTTP通信の実装
- [ ] URLSession を使用したHTTP POST リクエスト
- [ ] Ollama API エンドポイント（`/api/generate`）への接続
- [ ] リクエストボディの JSON 構造実装
- [ ] レスポンスの JSON パース処理

#### 1.3 Ollama API 仕様への対応
```json
// リクエスト形式
{
  "model": "モデル名",
  "prompt": "プロンプトテキスト",
  "stream": false,
  "options": {
    "temperature": 0.7,
    "top_p": 0.9
  }
}

// レスポンス形式
{
  "response": "生成されたテキスト",
  "done": true
}
```

#### 1.4 設定値の取得
- [ ] `Config.OllamaApiEndpoint` からエンドポイント取得
- [ ] `Config.OllamaModelName` からモデル名取得
- [ ] `Config.EnableOllama` で有効化状態確認

#### 1.5 OpenAIClient との共通化
- [ ] `Prompt.dictionary` を共有（同じプロンプトを使用）
- [ ] 同じメソッドシグネチャ `transform(text:transformType:)` を実装
- [ ] エラー型の統一

### 2. 変換処理の統合

#### 2.1 SelectedTextTransform.swift の修正
**ファイル**: `azooKeyMac/InputController/azooKeyMacInputController+SelectedTextTransform.swift`

- [ ] OllamaClient のインポート
- [ ] `transformSelectedText` メソッドでの Ollama 分岐処理追加
- [ ] 設定に応じたプロバイダー選択ロジック実装

#### 2.2 プロバイダー選択ロジック
- [ ] 設定に応じたAIプロバイダーの自動選択
- [ ] 優先順位: Ollama → OpenAI → エラー表示
- [ ] フォールバック機能の実装

#### 2.3 変換タイプ対応
- [ ] OpenAIClient.swift の `Prompt.dictionary` を共有利用
- [ ] 全変換タイプの動作確認（文章補完、絵文字、顔文字、記号、要約、翻訳、校正等）
- [ ] カスタムプロンプト対応

### 3. 実装詳細

#### 3.1 OllamaClient.swift の具体的実装
```swift
enum OllamaClient {
    static func transform(text: String, transformType: String) async throws -> [String] {
        // 1. 設定値の取得
        // 2. プロンプトの構築（OpenAIClient.Prompt.dictionary を使用）
        // 3. Ollama API リクエスト
        // 4. レスポンス解析
        // 5. 結果の配列化
    }
    
    private static func makeRequest(prompt: String) async throws -> String {
        // HTTP リクエストの実装
    }
}
```

#### 3.2 SelectedTextTransform.swift の修正箇所
```swift
// 既存の OpenAI 処理の前に Ollama チェックを追加
if Config.EnableOllama().value {
    return try await OllamaClient.transform(text: selectedText, transformType: transformType)
} else if Config.EnableOpenAiApiKey().value {
    // 既存の OpenAI 処理
}
```

### 4. エラーハンドリング

#### 4.1 Ollama 固有のエラー処理
- [ ] サーバー未起動エラー（Connection refused）
- [ ] モデル未ダウンロードエラー（Model not found）
- [ ] 生成タイムアウトエラー
- [ ] 不正なレスポンス形式エラー

#### 4.2 ユーザーフレンドリーなエラーメッセージ
- [ ] 「Ollamaサーバーが起動していません」
- [ ] 「指定されたモデルがダウンロードされていません」
- [ ] 「生成に時間がかかりすぎています」

### 5. 設定とUI改善

#### 5.1 ConfigWindow.swift の改善
- [ ] Ollama 接続テストの結果表示改善
- [ ] モデル一覧の自動取得（`/api/tags`）
- [ ] 設定の検証機能

#### 5.2 将来的な拡張設定
- [ ] Temperature, Top-p 等のパラメータ設定
- [ ] カスタムシステムプロンプト設定

### 6. テストと品質保証

#### 6.1 開発時テスト
- [ ] ローカル Ollama サーバーでの動作確認
- [ ] 各種モデル（llama2, codellama, mistral等）での動作確認
- [ ] エラーケースの動作確認

#### 6.2 統合テスト
- [ ] OpenAI との切り替え動作確認
- [ ] プロンプト入力ウィンドウとの連携確認
- [ ] 候補表示の動作確認

## 実装の優先順位

### Phase 1: 最小動作実装（高優先度）
1. **OllamaClient.swift の基本実装**
   - HTTP通信とJSON処理
   - 基本的なエラーハンドリング
2. **SelectedTextTransform.swift の統合**
   - Ollama分岐処理の追加
3. **文章補完機能の動作確認**

### Phase 2: 機能完成（中優先度）
1. **全変換タイプの対応**
2. **エラーハンドリングの強化**
3. **設定画面の改善**

### Phase 3: 品質向上（低優先度）
1. **詳細設定オプション**
2. **テストの充実**
3. **ドキュメント整備**

## 技術的考慮事項

### API仕様の違い
| 項目 | OpenAI | Ollama |
|------|--------|---------|
| エンドポイント | `/v1/chat/completions` | `/api/generate` |
| リクエスト形式 | Chat messages | Single prompt |
| レスポンス形式 | Choices array | Single response |
| ストリーミング | SSE | JSON lines |

### 実装時の注意点
1. **プロンプト共有**: OpenAIClient.Prompt.dictionary を活用
2. **エラー統一**: 同じエラーインターフェースを提供
3. **設定互換**: 既存設定パターンに従う
4. **段階実装**: 既存機能に影響を与えない

## 完了条件

- [ ] **基本動作**: Ollama での文章補完が動作
- [ ] **機能完全性**: 全変換タイプが利用可能
- [ ] **エラー処理**: 適切なエラーハンドリング
- [ ] **設定統合**: 設定画面での完全な制御
- [ ] **ドキュメント**: AI.md の実装状況更新

## 将来的な拡張可能性

### 統合クライアント化への道筋
現在の個別クライアント方式は、将来的な統合への基盤となります：

1. **共通インターフェース抽出**: 各クライアントから共通部分を抽出
2. **プロトコル定義**: AIProvider プロトコルの定義
3. **ファクトリーパターン**: プロバイダー選択の自動化
4. **設定統合**: 統一された設定インターフェース

この段階的アプローチにより、チーム開発での混乱を避けながら、最終的により保守しやすい設計に到達できます。