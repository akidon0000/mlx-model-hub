# CLAUDE.md

このリポジトリで AI（Claude Code 等）が**ループ開発**（変更 → ビルド → テスト → 検証 → 修正 を自走で繰り返す）を行うための前提・規約。

## プロジェクト概要

MLX で言語(LLM)・映像(VLM)・音声(ASR) のローカルモデルを動かす iOS/iPadOS アプリ。
Hugging Face Hub からモデルを検索・ダウンロードし、複数モデルを切り替えて推論する。
Apple FoundationModels（OS 同梱 LLM）にも対応。

## 開発ループの基本コマンド

`Makefile` 経由で実行する（入口を統一）。

```bash
make generate   # project.yml から .xcodeproj を再生成（新規ファイル追加後は必須）
make build      # iOS シミュレータ向けビルド
make test       # ユニットテスト実行
make ci         # generate → build → test（CI と同じ）
```

直接叩く場合の destination は `generic/platform=iOS Simulator`（ビルド）/
ブート済みシミュレータ id（テスト）。

## ループの回し方（自走）

1. 変更を加える
2. **新規ファイルを追加したら必ず `make generate`**（xcodegen はファイルを生成時にglobする）
3. `make build` でコンパイル確認
4. `make test` でロジック検証
5. 失敗したら原因を直して 3 に戻る
6. 通ったらコミット（ユーザーが指示したときのみ push）

## アーキテクチャ

```
Sources/
  App/         エントリ・Info.plist
  Models/      ドメイン: Modality / ModelDescriptor / ModelCatalog / ModelStore /
               HFModelService(本番検索) / MockModelService(Preview/テスト) /
               ModelHeuristics(純粋関数: 量子化/パラメータ/サイズ推定) / SortOption
  Download/    LocalModelStorage / DownloadState
  Inference/   Language(MLXLLM) / Vision(MLXVLM) / Audio(stub) / FoundationModels
  Views/       RootView / ChatView / CameraView / AudioView / ModelListView / ModelRow / ModelSwitcher
Tests/         Swift Testing（ロジックのユニットテスト）
```

- 状態の中心は `@MainActor @Observable ModelStore`。検索・DL/ロード状態・active モデルを保持。
- 検索は `ModelSearching` プロトコル越し。本番=`HFModelService`、Preview/テスト=`MockModelService`（**ネットワーク不使用**）。
- 推定ロジックは副作用の無い `ModelHeuristics` に集約（テスト対象）。

## 確立した前提・制約（変更しないこと）

- **mlx-swift-examples は `exactVersion: 2.29.1` 固定**。main は LLM/VLM ライブラリ分離の再構成中で
  `MLXLLM`/`MLXVLM`/`MLXLMCommon` 製品が無いためビルド不可。
- モデルの保存先は mlx の `defaultHubApi` と同じ **Caches ディレクトリ**（`Caches/models/<repo>`）。
  Documents ではない。`LocalModelStorage` はこれに合わせている。
- HF 一覧 API は `usedStorage` を `expand[]` で取得できない（付けると検索自体が 400）。
  サイズは `ModelHeuristics.estimateSize`（パラメータ×量子化ビット）で**概算**する。
- モダリティ推定で `"vl"` の部分一致は使わない（`vllm` 等で LLM を VLM に誤判定する）。
- Preview は必ず `ModelStore.preview(...)`（MockModelService）を使い、通信しない。

## テスト方針

- `Tests/` に Swift Testing で**純粋ロジック**を中心に書く（`ModelHeuristics` / `Modality.infer` /
  `ModelDescriptor` 表示 / `ModelStore` のモック検索）。
- UI / 実ネットワーク / MLX 実推論はユニットテスト対象外（実機・手動で確認）。

## 指摘事項の記憶

レビューやユーザーからの指摘・学びは [LEARNINGS.md](LEARNINGS.md) に追記して再発を防ぐ。
ループ中に同じ誤りを繰り返さないため、**作業前に LEARNINGS.md を読む**こと。
