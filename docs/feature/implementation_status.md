# 現在の機能実装・API接続一覧

更新日: 2026-09-03

この文書は、現在の `codetrain-app` に実装されている画面・機能と、APIへ接続する際の差し替え箇所を一覧化したものです。APIの入出力仕様そのものは [`docs/API_DESIGN.md`](../API_DESIGN.md) を正とします。

## 全体状況

- アプリの起動と画面表示は実装済みです。
- 現在の画面データ取得・保存はすべてモックRepositoryを使用しています。FlutterアプリからAPIへ通信する具体的なAPI Client / Data Source / API版Repositoryはまだありません。
- `CodeTrainApp` がComposition RootとしてRepositoryを解決し、`HomePage` 以下へ注入します。API版を実装した場合も、原則として `lib/app/app.dart` の注入先を差し替えます。
- APIレスポンスをアプリ内モデルへ変換するDTOは、トップナビゲーション、学習、タスク、フレンドの一部に実装済みです。
- `pubspec.yaml` には現在、HTTP通信ライブラリや認証ライブラリは追加されていません。

## 機能一覧

| 機能 | 現在の実装 | 現在のデータ元 | API接続時の候補 | 主な実装箇所 |
| --- | --- | --- | --- | --- |
| アプリ全体・タブ切り替え | Calendar / Learn / Home / Task / Friend の5タブ、260msのフェード＋横スライド、トップ・ボトムナビゲーションの共通表示を実装済み | 画面内の状態 | API不要 | `lib/features/home/presentation/home_page.dart`、`lib/shared/widgets/` |
| トップナビゲーション | レベル、経験値進捗、ハートを表示済み。ホーム画面の全タブ共通レイアウト上部に表示 | `MockTopNavigationRepository` | `GET /v1/me` の `progress` | `lib/shared/widgets/code_train_top_navigation.dart`、`lib/features/home/` |
| ホームダッシュボード | 日付、連続学習日数、当日のタスク消化ゲージ、月間進捗、最大3件のホーム対象タスク、スワイプ切り替え、言語アイコン、開始操作を実装済み | `MockHomeDashboardRepository`、`MockTaskRepository` | `GET /v1/home`。連続学習日数は `GET /v1/me` の `progress.streak_days` を利用する想定 | `lib/features/home/presentation/home_tab_page.dart`、`lib/features/home/domain/` |
| 学習 | スキル／学習項目の検索・絞り込み、学習開始、四択回答、正誤・正解・解説・XP表示、5問ごとのフィードバック、直近5問の振り返りを実装済み | `MockLearnRepository` | `GET /v1/skills`、`GET /v1/questions?skill_node_id=...`、必要に応じて `GET /v1/questions/{id}`、回答時に `POST /v1/questions/{id}/attempts` | `lib/features/learn/presentation/`、`lib/features/learn/domain/`、`lib/features/learn/data/` |
| タスク管理 | 複数タスクの一覧、開始、ホーム対象の最大3件選択、作成、編集、5スロット設定、削除を実装済み | `MockTaskRepository`、開始通知は `MockTaskLauncher` | 選択肢は `GET /v1/task-slots/options`。ただし一覧・保存・削除は現行 `/v1/task-slots` では複数タスクを表現できず、タスク単位APIの追加が必要 | `lib/features/task/presentation/task_page.dart`、`lib/features/task/domain/`、`lib/features/task/data/` |
| Calendar | タブとプレースホルダー表示のみ。カレンダーのデータ表示や操作は未実装 | なし | `GET /v1/calendar` | `lib/features/calendar/presentation/calendar_page.dart` |
| Friend | モーダルでの公開用ユーザーID完全一致検索、関係別絞り込み、連続学習日数、申請送信・取消、承認・拒否、メニューからのフレンド解除を実装済み | `MockFriendRepository` | `GET /v1/users/by-code/{user_code}`、`GET /v1/friends`、`/v1/friend-requests`、`DELETE /v1/friends/{user_id}` の暫定契約 | `lib/features/friend/presentation/`、`lib/features/friend/domain/`、`lib/features/friend/data/` |

## RepositoryとAPIの差し替え方

現在の構造は次のとおりです。

```text
Widget / Page
    ↓ 依存するのは domain のRepository interface
Repository interface
    ↓ 現在はモック実装
data/MockRepository ── DTO.fromJson() → domain model
```

API版へ接続するときは、対象featureの `data/` にAPI Client / Data Source / DTO変換を配置し、同じRepository interfaceを実装します。画面WidgetにJSONのkey、HTTPステータス、通信処理を追加しない方針です。

### 差し替え手順

1. `docs/API_DESIGN.md` に合わせたAPI Client / Data Sourceを対象featureの `data/` に追加する。
2. APIレスポンスをDTOで受け、DTOから既存のdomain modelへ変換する。
3. `TopNavigationRepository`、`HomeDashboardRepository`、`LearnRepository`、`TaskRepository`、`FriendRepository` のAPI版実装を作成する。
4. タスク開始用に `TaskLauncher` のAPI版実装を作成する。開始APIの具体仕様は現在未確定です。
5. `lib/app/app.dart` でモック実装をAPI版へ差し替える。
6. 認証、共通エラー、タイムアウトなどはAPI Client / Data Source側で統一して扱い、画面へはRepositoryの結果またはドメイン用エラーとして渡す。

## 機能別の接続詳細

### トップナビゲーション

- Repository: `TopNavigationRepository.fetchStatus()`
- モック: `MockTopNavigationRepository`
- DTO: `MeResponseDto` / `MeProgressDto`
- 接続先: `GET /v1/me`
- APIレスポンスの `progress.xp`、`progress.level`、`progress.hearts` を `TopNavigationStatus` へ変換します。
- 現在のAPI設計レスポンスには `experience_progress` と `max_hearts` がないため、進捗率とハート上限の取得方法は未確定です。現状はモックで `0.62` と `5` を与えています。
- `GET /v1/me` が `USER_NOT_FOUND` を返した場合の初回作成フロー（`POST /v1/me`）も、アプリ側には未実装です。

### ホームダッシュボード

- Repository: `HomeDashboardRepository.fetchDashboard()`
- モック: `MockHomeDashboardRepository`
- ドメインモデル: `HomeDashboard`、`HomeStudyTask`、`HomeTaskProgress`、`HomeMonthlyProgress`
- 接続先: `GET /v1/home`、連続学習日数は `GET /v1/me` の `progress.streak_days`
- `GET /v1/home` の `activity_date`、`tasks`、`monthly_progress`、`study_tasks` を表示用モデルへ変換するAPI版DTOが必要です。
- `TaskLauncher.start()` は現在何もしないモックです。ホームの再生ボタンは `study_tasks.task_no` を開始対象にする想定ですが、問題取得または開始エンドポイントの具体仕様は未確定です。
- 復習期限件数 `review.due_count` の表示導線は保留中です。

### 学習

- Repository: `LearnRepository.fetchCatalog()`、`fetchQuestionsForSkillNode()`、`submitAttempt()`
- モック: `MockLearnRepository`
- DTO: `LearnSkillsResponseDto`、`LearnQuestionDetailDto`、`LearnAttemptResponseDto` など
- 接続先:
  - 学習項目: `GET /v1/skills`
  - 問題取得: `GET /v1/questions?skill_node_id=...`、必要に応じて `GET /v1/questions/{id}`
  - 回答送信: `POST /v1/questions/{id}/attempts`
- 回答時は `selected_keys` と `duration_ms` を送信し、`is_correct`、`correct_keys`、`explanation`、`xp_gained` を `LearnAttemptResult` へ変換します。
- 問題は現在モックに含まれる問題セットを繰り返し出題します。API版では一覧取得、ページング、問題枯渇時の扱いをRepository側で決めます。
- 読み込み失敗・回答送信失敗の表示枠は実装済みですが、API通信によるエラー変換は未実装です。

### タスク管理

- Repository: `TaskRepository.fetchCatalog()`、`saveTask()`、`deleteTask()`
- モック: `MockTaskRepository`
- 起動境界: `TaskLauncher.start()`、モックは開始通知のみで実処理なし
- DTO: `TaskSlotDto`、`LearningTaskDto`、`TaskOptionDto`
- 継続利用するAPI: `GET /v1/task-slots/options`
- 現行API設計の `/v1/task-slots` はユーザー単位の5スロットを扱うため、アプリの要件である「複数タスク」「`task_id`」「名前」「`is_home_task`」「ホーム対象最大3件」と一致しません。
- API接続前に、タスク単位の一覧・作成・更新・削除APIを追加し、`TaskRepository` の各操作へ対応させる必要があります。詳細な不足事項は [`docs/API_DESIGN.md`](../API_DESIGN.md) のタスク画面節に記載されています。

### フレンド

- Repository: `FriendRepository.fetchUsers()`、`searchUserByCode()`、`sendRequest()`、`cancelRequest()`、`acceptRequest()`、`declineRequest()`、`removeFriend()`
- モック: `MockFriendRepository`
- DTO: `FriendUserDto`
- 接続先: `GET /v1/users/by-code/{user_code}`、`GET /v1/friends`、`/v1/friend-requests`、`DELETE /v1/friends/{user_id}` の暫定契約
- ユーザー検索はモーダル内で公開用ユーザーIDの完全一致検索を行い、結果を最大1件表示します。
- `streak_days` は承認済みフレンドだけに表示し、検索結果、送信申請、受信申請には表示しません。
- API接続前に検索可能な公開範囲、ブロック機能、申請・解除後の保持期間を確定する必要があります。

## API設計にあるが、現在のアプリ画面では未接続の機能

| API | 用途 | 現在の状態 |
| --- | --- | --- |
| `POST /v1/me` | 初回ログイン時のユーザー作成 | アプリ側未実装 |
| `PATCH /v1/me` | 表示名・アイコン更新 | 現在は画面導線なし |
| `GET /v1/me/stats` | 種別×言語ごとの正答率 | 現在は画面導線なし |
| `GET /v1/srs/due` | 復習期限問題の取得 | 復習画面・導線未実装 |
| `GET /v1/calendar` | 日別タスク消化状況・連続日数 | Calendar画面未実装 |
| `/v1/admin/*` | 問題レビュー用API | `codetrain-app` の対象外。`codetrain-admin` 向け |

## API接続前に確認が必要な事項

- API Clientで使用する通信・認証方式。API設計上の認証は `Authorization: Bearer <Cognito JWT>`、ローカル開発時は `X-Dev-User` です。
- `GET /v1/me` で経験値進捗率とハート上限をどのように返すか。
- XP配点、ハート回復、streak判定タイムゾーン、SRS更新規則。
- ホームの再生ボタンおよびタスク画面の開始ボタンが呼び出す開始API。
- 複数タスクを扱うタスク単位APIの仕様。
- フレンド検索の公開範囲、ブロック機能、申請・解除後の保持期間。
- APIエラーをRepositoryがどのドメインエラーへ変換し、各画面でどう表示するか。

## 関連ドキュメント

- [`docs/API_DESIGN.md`](../API_DESIGN.md): APIのエンドポイント、JSON、認証、エラーコード、未確定事項
- [`docs/feature/README.md`](README.md): 機能仕様書一覧
- [`docs/feature/top_navigation.md`](top_navigation.md)
- [`docs/feature/home_dashboard.md`](home_dashboard.md)
- [`docs/feature/learning.md`](learning.md)
- [`docs/feature/task_management.md`](task_management.md)
- [`docs/feature/friends.md`](friends.md)
- [`docs/feature/bottom_navigation.md`](bottom_navigation.md)
