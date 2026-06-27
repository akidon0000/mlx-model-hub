<p align="center">
  <img src="assets/banner.svg" alt="MLX Model Hub" width="100%"/>
</p>

<h1 align="center">MLX Model Hub</h1>

<p align="center">
  <strong>ローカルの LLM・VLM・ASR モデルを、MLX で iPhone 上で動かす。</strong><br/>
  言語・映像・音声のオンデバイスモデルを検索・ダウンロードし、複数モデルを切り替えて推論する SwiftUI 製 iOS/iPadOS アプリ。Apple <a href="https://github.com/ml-explore/mlx-swift-examples">MLX</a> と Apple FoundationModels を活用。
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/platform-iOS%2026%2B-1B1B1F?style=flat-square&logo=apple"/>
  <img alt="Language" src="https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white"/>
  <img alt="UI" src="https://img.shields.io/badge/SwiftUI-MLX-1FA6B8?style=flat-square"/>
  <img alt="License" src="https://img.shields.io/badge/License-MIT-10262E?style=flat-square"/>
  <img alt="PRs" src="https://img.shields.io/badge/PRs-welcome-38D6C8?style=flat-square"/>
  <a href="https://github.com/akidon0000/mlx-model-hub/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/akidon0000/mlx-model-hub/actions/workflows/ci.yml/badge.svg"/></a>
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ja.md">日本語</a>
</p>

---

<p align="center">
  <img src="assets/screenshot.svg" alt="モデル一覧のスクリーンショット" width="320"/>
</p>

## ✨ なぜ作ったか

Apple Silicon の iPhone は意外なほど高性能なモデルを完全オンデバイスで動かせますが、MLX の配線・Hugging Face からの重みダウンロード・複数モダリティの取り回しは面倒です。**MLX Model Hub** はそれを 1 アプリで完結させます。カタログから選び、`mlx-community` からタップでダウンロードし、ロードして推論 — テキスト(LLM)・画像(VLM)・音声(ASR) すべてに対応し、利用可能な端末では Apple 同梱の FoundationModels にフォールバックします。すべてローカルで動作し、データは端末外に出ません。

## 🚀 特長

- 🧩 **マルチモダリティ** — 言語(LLM)・映像(VLM)・音声(ASR) を 1 アプリで。
- 🔀 **モデルの即時切替** — カタログから選ぶだけでダウンロード → ロード → 推論。
- ⬇️ **アプリ内ダウンロード** — Hugging Face Hub（`mlx-community`）から自動取得。
- 🍎 **FoundationModels** — 対応端末では OS 同梱モデルをダウンロード不要で利用。
- 🧮 **サイズ概算** — HF 一覧 API では storage を展開できないため、パラメータ × 量子化ビットで概算。
- 🧪 **テスト可能なコア** — 純粋ヒューリスティクスとモックサービスでユニットテストを通信不要に。

## 🧰 動作環境

- iOS **26.0+** の実機（Apple Silicon）。MLX は GPU/Neural Engine を使うため、シミュレータより実機推奨。
- Xcode **26.3+**（Xcode 27 でも可）、Swift **6.0**。
- `project.yml` からプロジェクトを生成する [XcodeGen](https://github.com/yonaskolb/XcodeGen)。

## 📦 セットアップ

```bash
git clone https://github.com/akidon0000/mlx-model-hub.git
cd mlx-model-hub

brew install xcodegen   # 未インストールの場合
make generate           # project.yml → MLXModelHub.xcodeproj
open MLXModelHub.xcodeproj
```

Xcode で署名チーム（`DEVELOPMENT_TEAM`）を設定してから実機へ。

> [!NOTE]
> `mlx-swift-examples` は意図的に `exactVersion: 2.29.1` に固定しています（`main` は LLM/VLM ライブラリ分離の再構成中で `MLXLLM` / `MLXVLM` 製品が無いため）。モデルは `Caches/models/<repo>`（MLX の `defaultHubApi` と同じ場所）にキャッシュされます。

### 開発ループ

```bash
make build   # iOS シミュレータ向けビルド
make test    # ユニットテスト実行
make ci      # generate → build → test（CI と同じ）
```

## 🏗 アーキテクチャ

```
Sources/
  App/         エントリ・Info.plist
  Models/      Modality・ModelDescriptor・ModelCatalog・ModelStore・
               HFModelService(本番検索)・MockModelService(Preview/テスト)・
               ModelHeuristics(純粋関数: 量子化/パラメータ/サイズ)・SortOption
  Download/    LocalModelStorage・DownloadState
  Inference/   Language(MLXLLM)・Vision(MLXVLM)・Audio(stub)・FoundationModels
  Views/       RootView・ChatView・CameraView・AudioView・ModelListView・ModelRow
Tests/         Swift Testing（ロジックのユニットテスト）
```

- 状態の中心は `@MainActor @Observable ModelStore`（検索・DL/ロード状態・active モデルを保持）。
- 検索は `ModelSearching` プロトコル越し。本番=`HFModelService`、Preview/テスト=通信しない `MockModelService`。
- 推定ロジックは副作用の無い `ModelHeuristics` に集約。

## ➕ モデルの追加

[`Sources/Models/ModelCatalog.swift`](Sources/Models/ModelCatalog.swift) に `ModelDescriptor` を 1 つ足すだけで一覧に並び、ダウンロード対象になります。`id` は Hugging Face の repo id。

## 🗺 ロードマップ / 既知の未実装

- 音声（Whisper）の実推論は未実装。`AudioEngine` は WhisperKit 統合待ちのスタブ。
- `mlx-swift-examples` の API は更新が速く、`generate` / `loadContainer` のシグネチャは固定版に合わせる必要がある場合あり。
- 大きめモデル向けの Increased Memory Limit entitlement（実機）。

## 🤝 コントリビュート

PR 歓迎です！開発ループ・コーディング規約・PR チェックリストは [CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。

## 📄 ライセンス

[MIT](LICENSE) © akidon0000
