import Core
import SwiftUI

struct ConfigWindow: View {
    @ConfigState private var liveConversion = Config.LiveConversion()
    @ConfigState private var typeBackSlash = Config.TypeBackSlash()
    @ConfigState private var typeCommaAndPeriod = Config.TypeCommaAndPeriod()
    @ConfigState private var typeHalfSpace = Config.TypeHalfSpace()
    @ConfigState private var zenzai = Config.ZenzaiIntegration()
    @ConfigState private var zenzaiProfile = Config.ZenzaiProfile()
    @ConfigState private var zenzaiPersonalizationLevel = Config.ZenzaiPersonalizationLevel()
    @ConfigState private var openAiApiKey = Config.OpenAiApiKey()
    @ConfigState private var openAiModelName = Config.OpenAiModelName()
    @ConfigState private var ollamaUrl = Config.OllamaUrl()
    @ConfigState private var ollamaModelName = Config.OllamaModelName()
    @ConfigState private var learning = Config.Learning()
    @ConfigState private var inferenceLimit = Config.ZenzaiInferenceLimit()
    @ConfigState private var debugWindow = Config.DebugWindow()
    @ConfigState private var userDictionary = Config.UserDictionary()
    
    @ConfigState private var selectedBackend = Config.AIBackend()

    @State private var zenzaiHelpPopover = false
    @State private var zenzaiProfileHelpPopover = false
    @State private var zenzaiInferenceLimitHelpPopover = false
    @State private var openAiApiKeyPopover = false
    @State private var ollamaUrlPopover = false

    @ViewBuilder
    private func helpButton(helpContent: LocalizedStringKey, isPresented: Binding<Bool>) -> some View {
        if #available(macOS 14, *) {
            Button("ヘルプ", systemImage: "questionmark") {
                isPresented.wrappedValue = true
            }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.circle)
            .popover(isPresented: isPresented) {
                Text(helpContent).padding()
            }
        }
    }

    var body: some View {
        VStack {
            Text("azooKey on macOS")
                .bold()
                .font(.title)
            Spacer()
            HStack {
                Spacer()
                Form {

                    Picker("履歴学習", selection: $learning) {
                        Text("学習する").tag(Config.Learning.Value.inputAndOutput)
                        Text("学習を停止").tag(Config.Learning.Value.onlyOutput)
                        Text("学習を無視").tag(Config.Learning.Value.nothing)
                    }
                    Picker("パーソナライズ", selection: $zenzaiPersonalizationLevel) {
                        Text("オフ").tag(Config.ZenzaiPersonalizationLevel.Value.off)
                        Text("弱く").tag(Config.ZenzaiPersonalizationLevel.Value.soft)
                        Text("普通").tag(Config.ZenzaiPersonalizationLevel.Value.normal)
                        Text("強く").tag(Config.ZenzaiPersonalizationLevel.Value.hard)
                    }
                    Divider()
                    HStack {
                        Toggle("Zenzaiを有効化", isOn: $zenzai)
                        helpButton(helpContent: "Zenzaiはニューラル言語モデルを利用した最新のかな漢字変換システムです。\nMacのGPUを利用して高精度な変換を行います。\n変換エンジンはローカルで動作するため、外部との通信は不要です。", isPresented: $zenzaiHelpPopover)
                    }
                    HStack {
                        TextField("変換プロフィール", text: $zenzaiProfile, prompt: Text("例：田中太郎/高校生"))
                            .disabled(!zenzai.value)
                        helpButton(
                            helpContent: """
                        Zenzaiはあなたのプロフィールを考慮した変換を行うことができます。
                        名前や仕事、趣味などを入力すると、それに合わせた変換が自動で推薦されます。
                        （実験的な機能のため、精度が不十分な場合があります）
                        """,
                            isPresented: $zenzaiProfileHelpPopover
                        )
                    }
                    HStack {
                        TextField(
                            "Zenzaiの推論上限",
                            text: Binding(
                                get: {
                                    String(self.$inferenceLimit.wrappedValue)
                                },
                                set: {
                                    if let value = Int($0), (1 ... 50).contains(value) {
                                        self.$inferenceLimit.wrappedValue = value
                                    }
                                }
                            )
                        )
                        .disabled(!zenzai.value)
                        Stepper("", value: $inferenceLimit, in: 1 ... 50)
                            .labelsHidden()
                            .disabled(!zenzai.value)
                        helpButton(helpContent: "推論上限を小さくすると、入力中のもたつきが改善されることがあります。", isPresented: $zenzaiInferenceLimitHelpPopover)
                    }
                    Divider()
                    Toggle("ライブ変換を有効化", isOn: $liveConversion)
                    Toggle("円記号の代わりにバックスラッシュを入力", isOn: $typeBackSlash)
                    Toggle("「、」「。」の代わりに「，」「．」を入力", isOn: $typeCommaAndPeriod)
                    Toggle("スペースは常に半角を入力", isOn: $typeHalfSpace)
                    Divider()
                    Button("ユーザ辞書を編集する") {
                        (NSApplication.shared.delegate as? AppDelegate)!.openUserDictionaryEditorWindow()
                    }
                    Divider()
                    Toggle("（開発者用）デバッグウィンドウを有効化", isOn: $debugWindow)
                    Divider()
                    Section(header: Text("生成モデル")) {
                        Picker("使用するバックエンド", selection: $selectedBackend) {
                            ForEach(Config.AIBackend.Value.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)

                        // Ollama
                        if selectedBackend == .ollama {
                            VStack(alignment: .leading) {
                                TextField("Ollama URL", text: $ollamaUrl, prompt: Text("例: http://localhost:11434"))
                                TextField("Ollamaモデル名", text: $ollamaModelName, prompt: Text("例: llama3.2"))
                            }
                        }

                        // ChatGPT
                        if selectedBackend == .openAI {
                            VStack(alignment: .leading) {
                                SecureField("OpenAI APIキー", text: $openAiApiKey, prompt: Text("例: sk-xxxxxxxxxxx"))
                                TextField("OpenAIモデル名", text: $openAiModelName, prompt: Text("例: gpt-4o-mini"))
                            }
                        }
                    }

                    Divider()
                    LabeledContent("Version") {
                        Text(PackageMetadata.gitTag ?? PackageMetadata.gitCommit ?? "Unknown Version")
                            .monospaced()
                            .bold()
                            .copyable([
                                PackageMetadata.gitTag ?? PackageMetadata.gitCommit ?? "Unknown Version"
                            ])
                    }
                    .textSelection(.enabled)
                }
                Spacer()
            }
            Spacer()
        }
        .fixedSize()
        .frame(width: 500)
    }
}

#Preview {
    ConfigWindow()
}
