# タスク管理

## 仕様

- 複数の学習タスクを表示し、追加・編集・削除できる。
- 1つのタスクは名前と5つのスロットを持つ。
- 一覧には登録済みの学習タスクを全件表示する。
- 作成したタスクのうち、ホーム画面で開始する対象を最大3件まで設定できる。
- ホーム登録の切り替えや既存タスクの更新では、タスク一覧の表示順を変更しない。
- 各タスクはタスク画面の「開始」ボタンから直接開始できる。開始対象の識別子はタスク単位APIの `task_id` を利用する。
- タスク行には名前、設定済みスロット数、5スロットの設定状態を表示する。
- タスクの追加は画面下部のモーダルで行い、既存タスクの編集は一覧の直下に展開して行う。各スロットは個別に設定する。
- 問題種別、言語、難易度は `GET /v1/task-slots/options` に存在する組み合わせから選ぶ。
- 難易度は学習画面と同じLv.1〜Lv.5の範囲スライダー方式で選択し、初期状態の「おすすめ」は API の `minimum_difficulty: null` と `maximum_difficulty: null` に対応する。範囲を指定した場合は `minimum_difficulty` と `maximum_difficulty` を保存する。
- 白背景、区切り線、紫のアクセントを基本とし、カード型UIとグラデーションは使用しない。
- スロットの言語選択は、学習画面と同じ横スクロールのプログラミング言語ロゴUIを使用する。選択可能な言語は問題種別に対応するものだけを表示する。

## データ構成

- `TaskRepository` をタスク単位の取得・保存・削除の境界とする。
- APIレスポンス形状はDTOからドメインモデルへ変換する。
- 現在は `MockTaskRepository` を使用し、Composition Rootで注入する。

## 構成

- 画面: `lib/features/task/presentation/task_page.dart`
- ドメインモデル: `lib/features/task/domain/task_configuration.dart`
- Repository: `lib/features/task/domain/task_repository.dart`
- DTO・モック実装: `lib/features/task/data/`
- 言語選択UI: `lib/shared/widgets/programming_language_selector.dart`

## 実装状況

モックデータによる複数タスクの一覧、タスク画面からの開始操作、ホーム開始対象の最大3件選択、追加用モーダル、一覧下に展開する編集UI、学習画面と共通の言語ロゴ選択による5スロット設定、削除を実装済み。検索と問題種別フィルターは画面から削除済み。

現行の `GET /v1/task-slots` などはユーザー単位の5スロットだけを扱い、複数タスクを識別する `task_id` と `name` がない。API接続前にタスク単位の取得・作成・更新・削除エンドポイントを追加する必要がある。
