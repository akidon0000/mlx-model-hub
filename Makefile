# MLX Model Hub — 開発ループの統一入口
# AI / 人間どちらも、ビルド・テストはここから叩く。

PROJECT  = MLXModelHub.xcodeproj
SCHEME   = MLXModelHub
BUILD_DEST = generic/platform=iOS Simulator
# テストは起動済みシミュレータで実行。未指定なら最初のブート済みを使う。
TEST_DEST ?= platform=iOS Simulator,name=iPhone 17 Pro

.PHONY: generate build test ci clean

generate: ## project.yml から .xcodeproj を再生成（新規ファイル追加後は必須）
	xcodegen generate

build: ## iOS シミュレータ向けビルド
	xcodebuild build -project $(PROJECT) -scheme $(SCHEME) -destination '$(BUILD_DEST)'

test: ## ユニットテスト実行
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination '$(TEST_DEST)'

ci: generate build test ## CI と同じ流れ（generate → build → test）

clean:
	rm -rf ~/Library/Developer/Xcode/DerivedData/MLXModelHub-*
