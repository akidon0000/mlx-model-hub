# LEARNINGS — 指摘事項と学びの記録

ループ開発で**同じ誤りを繰り返さない**ための記録。レビュー指摘・ユーザーからの指摘・
ハマった原因をここに追記する。作業を始める前にこのファイルを読むこと。

書式: `- [日付] 指摘/事象 → 学び・対応`

## 記録

- [2026-06-20] mlx-swift-examples の `main` には `MLXLLM`/`MLXVLM`/`MLXLMCommon` 製品が無い
  → タグ `2.29.1` に固定する（再構成中のため）。
- [2026-06-20] モデルの保存先を Documents で探していて「ダウンロード済み」判定が常に false
  → mlx は `defaultHubApi` の **Caches** に保存。`LocalModelStorage` を Caches に合わせた。
- [2026-06-20] `URL.appending(component:)` は repo の `/` をエンコードしてパスが不一致
  → `appending(path:)` を使う（最終的に `ModelConfiguration.modelDirectory` に統一）。
- [2026-06-20] HF 一覧 API に `expand[]=usedStorage` を付けると 400 で検索全体が失敗
  → usedStorage は使わず、サイズは `ModelHeuristics.estimateSize` で概算。
- [2026-06-20] モダリティ推定で `"vl"` 部分一致が `vllm` 等を拾い LLM を VLM に誤判定
  → 限定キーワード（image-text-to-text / qwen2-vl 等）のみで判定。
- [2026-06-20] `1.7B` のパラメータ換算が Double 誤差で `1_699_999_999` に
  → `.rounded()` してから `Int64` 化。
- [2026-06-20] Preview がネットワーク検索を実行してしまう
  → `ModelSearching` プロトコル化し、Preview/テストは `MockModelService`（通信なし）を注入。
- [2026-06-20] 新規 Swift ファイルを追加してもビルドに含まれない
  → xcodegen は生成時にファイルを glob するため、追加後は `make generate` が必須。
