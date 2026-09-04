# タスク管理

## 仕様

- ユーザーが持つ学習タスクは1つだけとし、新しいタスクの追加や既存タスクの削除は行わない。
- 単一の学習タスクは5つのスロットを持ち、すべてのスロットを設定して保存する。
- タスク画面に5スロットの設定内容と設定済み数を常に表示し、各スロットを個別に編集する。
- タスク画面に追加・削除・ホーム登録・開始の操作は表示しない。学習開始はホーム画面で選択したスロットから行う。
- 問題種別、言語、難易度は `GET /v1/task-slots/options` に存在する組み合わせから選ぶ。
- 難易度は学習画面と同じLv.1〜Lv.5の範囲スライダー方式で選択し、初期状態の「おすすめ」は API の `minimum_difficulty: null` と `maximum_difficulty: null` に対応する。範囲を指定した場合は `minimum_difficulty` と `maximum_difficulty` を保存する。
- 白背景、区切り線、紫のアクセントを基本とし、カード型UIとグラデーションは使用しない。
- スロットの言語選択は、学習画面と同じ横スクロールのプログラミング言語ロゴUIを使用する。選択可能な言語は問題種別に対応するものだけを表示する。

## データ構成

- `TaskRepository` を単一タスクと5スロットの取得・保存の境界とする。
- APIレスポンス形状はDTOからドメインモデルへ変換する。
- 現在は `MockTaskRepository` を使用し、Composition Rootで注入する。

## 構成

- 画面: `lib/features/task/presentation/task_page.dart`
- ドメインモデル: `lib/features/task/domain/task_configuration.dart`
- Repository: `lib/features/task/domain/task_repository.dart`
- DTO・モック実装: `lib/features/task/data/`
- 言語選択UI: `lib/shared/widgets/programming_language_selector.dart`

## 実装状況

単一の学習タスクを5スロットとして直接編集するUIを実装済み。タスクの追加・削除・ホーム登録は画面から削除し、`MockTaskRepository` も保存時に常に単一タスクを更新する。API接続時は現行の `/v1/task-slots` をそのまま単一タスクの5スロットとして扱う。
