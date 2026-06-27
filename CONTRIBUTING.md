# Contributing to MLX Model Hub

Thanks for your interest! PRs that make this better are very welcome. This guide is intentionally short — keep it in mind, but don't sweat the small stuff.

[English](#en) · [日本語](#ja)

---

<a id="en"></a>

## English

### Ground rules

- **Be kind.** This project follows the spirit of the [Contributor Covenant](https://www.contributor-covenant.org/).
- **One topic per PR.** Smaller, focused PRs get merged faster.
- **Discuss before big changes.** For features that change UX or architecture, open an issue first.

### Dev loop

Everything goes through the `Makefile` so the entry point stays consistent:

```bash
brew install xcodegen   # if not installed
make generate   # project.yml → .xcodeproj (REQUIRED after adding new files)
make build      # build for the iOS simulator
make test       # run unit tests
make ci         # generate → build → test (same as CI)
```

XcodeGen globs files at generation time, so **run `make generate` whenever you add a new file.**

### Coding conventions

- SwiftUI + Swift 6 concurrency. UI-touching state lives on `@MainActor`.
- `ModelStore` is the single source of truth; keep estimation logic pure in `ModelHeuristics`.
- Previews and tests must use `MockModelService` — **never hit the network** in tests.
- `mlx-swift-examples` stays pinned to `exactVersion: 2.29.1` (see README for why).
- Add new models via a single `ModelDescriptor` in `Sources/Models/ModelCatalog.swift`.

### PR checklist

- [ ] `make ci` passes (generate → build → test)
- [ ] New files added → `make generate` was run and the diff includes the regenerated project if applicable
- [ ] Unit tests cover new pure logic (`ModelHeuristics`, `Modality.infer`, etc.)
- [ ] UI changes include a screenshot or short clip
- [ ] README / README.ja.md updated if user-visible behavior changed

---

<a id="ja"></a>

## 日本語

### 心構え

- **やさしく。** [Contributor Covenant](https://www.contributor-covenant.org/) の精神に沿って接してください。
- **1 PR 1 トピック。** 小さく焦点が絞られた PR の方が早くマージできます。
- **大きな変更は先に相談。** UX やアーキテクチャを変える機能は、コードを書く前に Issue を立てましょう。

### 開発ループ

入口を統一するため、すべて `Makefile` 経由で実行します:

```bash
brew install xcodegen   # 未インストールの場合
make generate   # project.yml → .xcodeproj（新規ファイル追加後は必須）
make build      # iOS シミュレータ向けビルド
make test       # ユニットテスト実行
make ci         # generate → build → test（CI と同じ）
```

XcodeGen は生成時にファイルを glob するため、**新規ファイルを追加したら必ず `make generate`** を実行してください。

### コーディング規約

- SwiftUI + Swift 6 並行性。UI に触る状態は `@MainActor`。
- `ModelStore` を単一の信頼できる情報源（SSOT）に。推定ロジックは `ModelHeuristics` に純粋関数として集約。
- Preview とテストは `MockModelService` を使い、**テストで通信しない**こと。
- `mlx-swift-examples` は `exactVersion: 2.29.1` 固定のまま（理由は README 参照）。
- モデル追加は `Sources/Models/ModelCatalog.swift` に `ModelDescriptor` を 1 つ足すだけ。

### PR チェックリスト

- [ ] `make ci` が通る（generate → build → test）
- [ ] 新規ファイル追加時は `make generate` 済み
- [ ] 新しい純粋ロジックにはユニットテストを追加（`ModelHeuristics` / `Modality.infer` 等）
- [ ] UI 変更はスクリーンショットか短いクリップを添付
- [ ] ユーザーから見える変更があれば README / README.ja.md も更新
