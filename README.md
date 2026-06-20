# mlx-model-hub

MLX を使って、言語・音声・映像の様々なローカルモデルを iOS / iPadOS 上で動かすアプリ。
複数モデルを選んで切り替えられ、アプリ内から簡単にダウンロードできる。Apple の
FoundationModels（OS 同梱のオンデバイス LLM）にも対応。

## 特徴

- **マルチモダリティ**: 言語（LLM）・映像（VLM）・音声（ASR）を 1 アプリで。
- **複数モデルの選択切替**: カタログから選ぶだけでダウンロード → ロード → 推論。
- **アプリ内ダウンロード**: Hugging Face Hub（`mlx-community`）から自動取得。
- **FoundationModels**: 対応端末では OS 同梱モデルをダウンロード不要で利用。

## 必要環境

- Xcode 26.3 以上（Xcode 27 でも可）
- iOS 26.0 以上の実機（Apple Silicon）。MLX は GPU/メモリを使うため、
  シミュレータより実機推奨。

## セットアップ

```bash
# プロジェクト生成（project.yml から .xcodeproj を作る）
brew install xcodegen   # 未インストールの場合
xcodegen generate
open MLXModelHub.xcodeproj
```

Xcode で署名チーム（DEVELOPMENT_TEAM）を設定してから実機へ。

## 構成

```
Sources/
  App/         アプリエントリ・Info.plist
  Models/      モダリティ定義・モデルカタログ・状態ストア(ModelStore)
  Download/    ダウンロード/ロード状態
  Inference/   推論エンジン（Language / Vision / Audio / FoundationModels）
  Views/       SwiftUI 画面（モデル一覧・チャット）
```

## モデルの追加

`Sources/Models/ModelCatalog.swift` に `ModelDescriptor` を 1 行足すだけで
一覧に並び、ダウンロード対象になる。`id` は Hugging Face の repo id。

## 既知の未実装 / TODO

- 音声（Whisper）の実推論は未実装。`AudioEngine` に WhisperKit などを統合予定。
- mlx-swift-examples の API は更新が速いため、`generate` / `loadContainer` の
  シグネチャはビルド時に取得版へ合わせる必要がある場合あり。
- 大きめモデル向けの Increased Memory Limit entitlement（実機）。

## ライセンス

MIT
