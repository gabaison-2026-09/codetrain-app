# 初回タスク提案

## 目的

アカウント新規作成後に学習目的や経験を質問し、回答に合う最初の学習タスクを提案する。既存ユーザーのログイン時には表示しない。

## 画面仕様

- アカウント作成成功後、ホーム画面を表示する前に開始する。
- 1画面に1問を表示し、上部の進捗バー、回答、戻るボタン、次へボタンだけで構成する。
- 白背景、紫のアクセント、既存フォントを使用し、グラデーションは使用しない。
- 選択肢は高さを統一した大きな単一選択ボタンとし、言語には既存のプログラミング言語アイコンを表示する。
- プログラミング歴だけは5段階のスライダーで回答する。
- 全問回答後に提案されたタスク名と5つのスロットを表示する。
- 「はじめる」で提案タスクを保存し、ホーム画面へ移動する。
- 読み込み中は操作を無効化し、提案または保存に失敗した場合は同じ操作を再実行できる。

## 質問と回答ID

画面表示文言とAPIへ送るIDを分離する。APIへは以下のIDだけを送信し、自由入力は扱わない。

| 質問 | フィールド | 回答ID |
| --- | --- | --- |
| 何を作りたい？ | `goal` | `web_service` / `mobile_app` / `game` / `automation` / `data_analysis` |
| どの言語をやりたい？ | `language` | `typescript` / `ruby` / `javascript` / `csharp` |
| 何のために学ぶ？ | `purpose` | `first_development` / `work` / `career` / `personal_project` / `review` |
| プログラミング歴は？ | `experience` | `none` / `less_than_six_months` / `six_months_to_one_year` / `one_to_three_years` / `over_three_years` |

## データ構成

- `TaskRecommendationRepository` を回答送信とタスク提案取得の境界とする。
- Repositoryは `TaskRecommendationAnswers` を受け取り、保存前の `LearningTask` を返す。
- 確定した提案は既存の `TaskRepository.saveTask()` で保存する。
- 現在は `MockTaskRecommendationRepository` がメモリ上で提案を生成する。
- API接続時は `features/onboarding/data/` にAPI Client、DTO、API版Repositoryを追加し、画面を変更せず差し替える。

## バックエンド要件

### 処理境界

- `POST /v1/task-recommendations` で正規化済みの回答IDを受け取り、保存前のタスク案を同期的に返す。
- 認証後のユーザー作成（`POST /v1/me`）が完了していることを前提とする。
- 回答値、生成途中の特徴量、タスク案をDB、キャッシュ、分析基盤へ保存しない。
- 通常のアクセスログにもリクエストボディを記録しない。
- ユーザーが提案を確定した場合だけ、`PUT /v1/task-slots/{slot_no}` で5スロットを保存する。
- 将来、外部の生成AIや分析サービスへ回答を送る場合は、送信項目、提供先、保持期間、費用を確定し、実装前に別途確認する。

### 提案ロジック

- 提案結果は名前、`is_home_task`、5件のスロットを持つ。
- スロットは `GET /v1/task-slots/options` で返せる組み合わせだけを使用する。
- 難易度はLv.1〜Lv.5とし、`minimum_difficulty <= maximum_difficulty` を満たす。
- 作りたいものをタスク名、学習テーマ、問題種別の配分、経験と目的を難易度、希望言語を言語指定へ反映する。
- 指定言語で5スロットを構成できない場合は、言語指定なしの問題を組み合わせる。
- 有効な5スロットを構成できない場合は、不完全な提案を返さず `RECOMMENDATION_NOT_AVAILABLE` とする。
- 同じ回答と同じ利用可能問題セットに対して、説明できる一貫した結果を返すことを基本とする。

### 保存時の検証

- クライアントから返送されたタスク案を信頼せず、名前、スロット数、問題種別、言語、難易度を再検証する。
- ホーム対象タスクがすでに3件ある場合の扱いは、既存タスクを暗黙に解除せず、保存を拒否する。
- 認証ユーザー以外のタスクとして保存できないようにする。

## データ利用とプライバシー

- 回答は初回タスクを提案する目的にだけ使用する。
- 回答自体は保持せず、ユーザーが確定したタスクだけをユーザーデータとして保存する。
- 権限要求、広告、トラッキング、課金、外部サービス連携は追加しない。
- 本番API接続前に、プライバシーポリシーへ利用目的と「回答を保持しない」ことを反映する。

## 主な実装箇所

- `lib/features/onboarding/domain/task_recommendation.dart`
- `lib/features/onboarding/data/mock_task_recommendation_repository.dart`
- `lib/features/onboarding/presentation/task_recommendation_page.dart`
- `lib/app/app.dart`

## 実装状況

モックRepositoryを利用した4問の質問、プログラミング歴スライダー、提案確認、タスク保存、ホーム遷移を実装済み。API通信と回答の外部送信は未実装。
