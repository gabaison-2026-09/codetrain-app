# 学習画面

## 仕様

- Learn タブで、学習するスキルとスキルノードを選択する。
- スキルは名称、説明、含まれる学習項目を表示し、学習項目には難易度を表示する。件数ラベルは表示しない。
- 最初の学習項目を初期選択し、「この内容で始める」から問題画面へ進む。
- 問題数に終端は設けず、取得した問題を継続して出題する。問題画面は次のフィードバックまでの問題番号、5問単位の進捗、問題種別、言語、難易度、問題文、コード、四択を表示する。
- 選択肢を選ぶまでは回答ボタンを無効にし、回答後は正解、不正解、正解の選択肢、解説、獲得XPを表示する。
- 回答後は次の問題へ進み、5問回答するごとに正解数と獲得XPのフィードバックを表示する。
- フィードバックから「学習を続ける」を選ぶと、進捗をリセットして次の5問へ進む。
- 問題画面に閉じるボタンは表示しない。
- 問題へ回答している間はボトムナビゲーションを表示しない。5問ごとのフィードバック画面では再表示する。
- 読み込みまたは回答送信に失敗した場合は、画面内にエラーメッセージを表示する。
- トップナビゲーションとボトムナビゲーションは既存の表示と挙動を維持する。
- ホーム画面と同じ白背景を使い、通常時の配色は黒、グレー、紫に絞る。正誤表示に限り緑と赤を使用する。
- 学習選択画面はカード型の囲みを使わず、見出し、余白、区切り線でスキルを整理する。装飾用アイコン、英字見出し、サブタイトルは表示しない。

## APIとの対応

- 学習項目は `GET /v1/skills` のスキルとスキルノードを使用する。
- 選択したスキルノードの問題一覧を `GET /v1/questions?skill_node_id=...` で取得し、各問題の表示情報を `GET /v1/questions/{id}` で取得する想定とする。
- 回答は `POST /v1/questions/{id}/attempts` の `selected_keys` と `duration_ms` を送信し、`is_correct`、`correct_keys`、`explanation`、`xp_gained` を表示する。
- 現在は `LearnRepository` のモック実装を使用する。モックレスポンスもAPIのJSON形状からDTOを経由してドメインモデルへ変換する。
- API版へ接続するときは `LearnRepository` の実装を差し替え、画面Widgetへ通信処理やJSON固有の型を追加しない。

## 構成

- 画面状態と遷移: `lib/features/learn/presentation/learn_page.dart`
- 学習選択UI: `lib/features/learn/presentation/widgets/learn_selection_view.dart`
- 四択問題UI: `lib/features/learn/presentation/widgets/learn_question_view.dart`
- ドメインモデル: `lib/features/learn/domain/learn_content.dart`
- Repository: `lib/features/learn/domain/learn_repository.dart`
- DTO: `lib/features/learn/data/learn_response_dto.dart`
- モック実装: `lib/features/learn/data/mock_learn_repository.dart`

## 実装状況

スキル／学習項目の選択、問題セットの開始、四択回答、正誤と解説の表示、継続的な問題の進行、5問ごとのフィードバックをモックデータで実装済み。API通信の具体実装は未接続。
