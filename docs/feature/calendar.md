# カレンダー

## 仕様

- 月単位のカレンダーを表示し、日曜日始まりの7列・最大6週で配置する。
- 月見出しの左右操作で前月・翌月へ移動し、今日ボタンで当月へ戻る。
- 学習した日は直径38の円を淡い紫で塗り、同じ週で連続する学習日は円の間を背景でつなげる。週をまたぐ土曜日と日曜日はつなげない。
- 選択中の日は淡い紫の円と同じ直径・外周に濃い紫の輪郭を表示し、連続区間の初日・最終日の淵を揃える。
- 日付を選択したときは、軽い選択用の触覚フィードバックを発生させる。
- 日付を選択すると、下部に選択日と `completed_slots / total_slots` を表示する。
- 月表示自体を期間の絞り込みとして扱い、日別データの一覧は表示しない。
- 連続フリーズに関する表示は設けない。
- 背景は白とし、ホーム画面と同じ紫・黒・グレーを使用する。
- カード型UI、グラデーション、説明用の注釈文は使用しない。
- トップナビゲーションとボトムナビゲーションは既存の共通Widgetを維持する。

## データ

- `CalendarRepository.fetchActivity(from:to:)` を画面のデータ取得境界とする。
- 現在は `MockCalendarRepository` をComposition Rootから注入する。
- API接続時は `GET /v1/calendar?from=YYYY-MM-DD&to=YYYY-MM-DD` のレスポンスを `CalendarResponseDto` で受け、`CalendarActivity` へ変換する。
- APIの `streak_days` と `last_studied_on` はドメインモデルに保持するが、この画面には表示しない。

## 実装箇所

- `lib/features/calendar/presentation/calendar_page.dart`
- `lib/features/calendar/domain/`
- `lib/features/calendar/data/`
- `lib/app/app.dart`

## 実装状況

- 月移動、今日への復帰、学習日の目印、日付選択、選択日のタスク進捗表示を実装済み。
- Repository、APIレスポンスDTO、モックRepositoryを実装済み。
- API Client / Data Sourceと認証を含む実通信は未実装。
