# CodeTrain — 配信API設計

`codetrain-api`（配信API）が Flutter アプリ（`codetrain-app`）とレビュー画面（`codetrain-admin`）に提供するエンドポイントの設計。

- 実装: `codetrain-api/internal/handler/` `internal/service/` `internal/repository/`
- 共有ドメイン型: `codetrain-core/pkg/domain`
- 関連: [DB_SCHEMA.md](DB_SCHEMA.md)（テーブル定義） / [DESIGN.md](DESIGN.md) §6（データモデル） / [OPEN_ISSUES.md](OPEN_ISSUES.md)（未確定パラメータ）
- ステータス: 設計中（`GET /healthz` / `GET /v1/skills` / `GET /v1/me` のみ実装済み。他は本ドキュメントで新規設計）
- 対象画面: ホーム / 学習 / タスク / カレンダー / プロフィール（`codetrain-app`）＋ レビューキュー（`codetrain-admin`）

---

## 1. 概要

| 項目 | 内容 |
| --- | --- |
| ベース URL | `/v1`（ヘルスチェックのみ `/healthz`） |
| 形式 | JSON（`Content-Type: application/json`） |
| 認証方式 | `Authorization: Bearer <Cognito JWT>`。`sub` クレームが `app_user.external_id` に対応する（[DB_SCHEMA.md](DB_SCHEMA.md) §5 `app_user`） |
| ローカル開発 | `AUTH_MODE=dev` では `X-Dev-User: <任意の文字列>` ヘッダを `sub` として扱う（署名検証なし。`internal/middleware/auth.go`） |
| レビュアー権限 | `/v1/admin/*` は認証必須に加え「レビュアー権限」を要求する。権限モデル（ロール表現・付与方法）は未確定（[OPEN_ISSUES.md](OPEN_ISSUES.md) C-5 / D-2） |
| 日時 | ISO 8601 / `timestamptz` は UTC の `2026-09-02T03:04:05Z` 形式、日付のみは `date`（`YYYY-MM-DD`） |
| ページング | カーソル方式。クエリ `cursor` / `limit`（default 20, max 100）。レスポンスに `next_cursor`（次頁が無ければ `null`） |
| 未確定のゲームパラメータ | XP配点・ハート回復・streak判定タイムゾーン・推奨難易度アルゴリズムは [OPEN_ISSUES.md](OPEN_ISSUES.md) B-3 / B-4 / B-10 で未確定。本設計はエンドポイントの入出力形のみを定め、数値ロジックは実装時に確定する |

### 1.1 共通レスポンス規約

成功時はエンドポイントごとの JSON をそのまま返す。一覧系は `{"<資源名>": [...], "next_cursor": ...}` の形を統一して使う。

失敗時は共通のエラーエンベロープを使う（詳細は §4）。

```json
{
  "error": {
    "code": "QUESTION_NOT_FOUND",
    "message": "問題が見つかりません"
  }
}
```

---

## 2. API 一覧

### ユーザー / プロフィール

| 種別 | エンドポイント | 概略 | 認証是非 |
| --- | --- | --- | --- |
| GET | `/v1/me` | 自分のプロフィールと進捗を取得する（既存） | 必須 |
| POST | `/v1/me` | 初回ログイン時にユーザーを作成する（JITプロビジョニング） | 必須 |
| PATCH | `/v1/me` | 表示名・アイコンを更新する | 必須 |
| GET | `/v1/me/stats` | 種別×言語ごとの正答率を取得する（プロフィール画面用） | 必須 |

### フレンド

> **クライアント要件によるAPI追加（2026-09-03）**: Friend画面で、公開ユーザーの検索、関係別一覧、申請送信・取消、承認・拒否、フレンド解除を行う。検索・一覧では `id`、公開用の `user_code`、`display_name`、`avatar_url`、ログインユーザーとの `relationship` のみを返し、`email` と `external_id` は返さない。`user_code` はユーザー作成時にサーバーが一意な値を発行し、`GET /v1/me` と `POST /v1/me` のユーザー情報にも追加する必要がある。以下はクライアントが必要とする暫定契約であり、バックエンド実装前に公開範囲、ブロック、保持期間を確定する。

| 種別 | エンドポイント | 概略 | 認証是非 |
| --- | --- | --- | --- |
| GET | `/v1/users/by-code/{user_code}` | 公開用ユーザーIDの完全一致でユーザーを1件検索する | 必須 |
| GET | `/v1/friends?relationship=friend\|outgoing_request\|incoming_request` | 関係別にユーザーを取得する | 必須 |
| POST | `/v1/friend-requests` | フレンド申請を送信する | 必須 |
| DELETE | `/v1/friend-requests/{user_id}` | 送信した申請を取り消す | 必須 |
| POST | `/v1/friend-requests/{user_id}/accept` | 受信した申請を承認する | 必須 |
| POST | `/v1/friend-requests/{user_id}/decline` | 受信した申請を拒否する | 必須 |
| DELETE | `/v1/friends/{user_id}` | フレンド関係を解除する | 必須 |

### スキルツリー / 学習画面

| 種別 | エンドポイント | 概略 | 認証是非 |
| --- | --- | --- | --- |
| GET | `/v1/skills` | スキルとスキルノードの一覧を取得する（既存） | 不要 |
| GET | `/v1/questions` | 問題を検索する（種別・言語・難易度・タグ・キーワード） | 必須 |
| GET | `/v1/questions/{id}` | 問題を1件取得する（未回答は正解を含まない） | 必須 |
| POST | `/v1/questions/{id}/attempts` | 回答を送信し、採点・XP・streak・SRSを更新する | 必須 |
| GET | `/v1/srs/due` | 復習期限が来ている問題一覧を取得する | 必須 |

### タスク画面

> **クライアント要件によるAPI不足（2026-09-03）**: 1タスクが5スロットを持ち、そのタスクを複数保存する。現行の `/v1/task-slots` はユーザー単位の5スロットしか表現できないため、API接続前にタスクを識別する `task_id` と表示用の `name`、ホーム開始対象を示す `is_home_task`、タスク単位の一覧・作成・更新・削除APIが必要。ホーム開始対象は最大3件とする。想定レスポンスは `{"tasks":[{"id":"uuid","name":"TypeScript 基礎","is_home_task":true,"slots":[...5件]}]}`。`/v1/task-slots/options` は各スロットの選択肢取得に継続利用する。

| 種別 | エンドポイント | 概略 | 認証是非 |
| --- | --- | --- | --- |
| GET | `/v1/task-slots` | 設定済みタスクスロット（最大5）を取得する | 必須 |
| PUT | `/v1/task-slots/{slot_no}` | タスクスロットを設定する（作成/更新） | 必須 |
| DELETE | `/v1/task-slots/{slot_no}` | タスクスロットを削除する | 必須 |
| GET | `/v1/task-slots/options` | 選択可能な（種別, 言語, 難易度）候補を取得する | 必須 |

### ホーム画面

| 種別 | エンドポイント | 概略 | 認証是非 |
| --- | --- | --- | --- |
| GET | `/v1/home` | 今日のタスク一覧を取得する（初回アクセス時に当日分を割当） | 必須 |

### カレンダー画面

| 種別 | エンドポイント | 概略 | 認証是非 |
| --- | --- | --- | --- |
| GET | `/v1/calendar` | 期間内の日別タスク消化状況と連続日数を取得する | 必須 |

### レビュー（`codetrain-admin` 向け）

| 種別 | エンドポイント | 概略 | 認証是非 |
| --- | --- | --- | --- |
| GET | `/v1/admin/questions` | 管理用に問題を横断検索する（status問わず） | 必須（レビュアー） |
| GET | `/v1/admin/review-queue` | 未レビューの問題一覧を取得する | 必須（レビュアー） |
| GET | `/v1/admin/questions/{id}` | 問題の全項目（正解・生成メタデータ・レビュー履歴）を取得する | 必須（レビュアー） |
| PATCH | `/v1/admin/questions/{id}` | 問題内容を修正する（本文・コード・選択肢・正解・解説・難易度・タグ等） | 必須（レビュアー） |
| POST | `/v1/admin/questions/{id}/review` | レビュー判定を記録する（承認/却下/修正依頼） | 必須（レビュアー） |

---

## 3. エンドポイント詳細

### GET /v1/me

**概略**: 自分のプロフィールと進捗を取得する（実装済み）。
**認証是非**: 必須

**レスポンスボディ** `200 OK`
```json
{
  "user": {
    "id": "uuid",
    "external_id": "cognito-sub",
    "user_code": "engineer_taro",
    "display_name": "エンジニア太郎",
    "email": "user@example.com",
    "created_at": "2026-09-02T03:04:05Z"
  },
  "progress": {
    "xp": 120,
    "level": 3,
    "streak_days": 5,
    "last_studied_on": "2026-09-01",
    "hearts": 4,
    "current_skill_node_id": "uuid"
  }
}
```

**エラー**: `USER_NOT_FOUND`（404。未プロビジョニングのユーザー。クライアントは `POST /v1/me` を呼ぶ）

---

### POST /v1/me

**概略**: 初回ログイン時にユーザーを作成する（JITプロビジョニング）。Cognito 側で Google アカウント連携済みでも `app_user` にはまだ行が無いため、アプリ起動後の最初の一回に呼ぶ想定（[OPEN_ISSUES.md](OPEN_ISSUES.md) D-3）。
**認証是非**: 必須

**リクエストボディ**
```json
{
  "display_name": "エンジニア太郎",
  "avatar_url": "https://.../photo.jpg"
}
```
- `display_name`: 必須。JWT に `name` クレームがあればクライアント初期値として使う想定だが、サーバは常にリクエストボディの値を正とする
- `avatar_url`: 任意

**レスポンスボディ** `201 Created`（`GET /v1/me` と同じ形。`user_progress` は初期値で同時作成される）

**エラー**: `USER_ALREADY_PROVISIONED`（409。既に `external_id` が存在する）/ `VALIDATION_ERROR`（400。`display_name` 欠落）

---

### PATCH /v1/me

**概略**: 表示名・アイコンを更新する。
**認証是非**: 必須

**リクエストボディ**（部分更新。渡したフィールドのみ更新）
```json
{
  "display_name": "エンジニア次郎",
  "avatar_url": "https://.../new.jpg"
}
```

**レスポンスボディ** `200 OK`（更新後の `user`）

**エラー**: `USER_NOT_FOUND` / `VALIDATION_ERROR`

---

### GET /v1/me/stats

**概略**: 種別×言語ごとの累計回答数・正答率を取得する（`user_type_stat`。[DB_SCHEMA.md](DB_SCHEMA.md) §5）。プロフィール画面の実績表示に使う。
**認証是非**: 必須

**レスポンスボディ** `200 OK`
```json
{
  "stats": [
    {
      "question_type": "code_reading",
      "language": "typescript",
      "attempts": 42,
      "corrects": 35,
      "accuracy": 0.83,
      "last_difficulty": 3
    },
    {
      "question_type": "output_prediction",
      "language": "",
      "attempts": 10,
      "corrects": 6,
      "accuracy": 0.6,
      "last_difficulty": 2
    }
  ]
}
```
- `language: ""` は「言語を問わない」集計（[DB_SCHEMA.md](DB_SCHEMA.md) §3）
- `user_type_stat` を使わず `attempt` 集約で代替する場合も、レスポンス形は変えない（§5 の備考どおりテーブルの有無は実装詳細）

---

### フレンドAPI共通契約（暫定）

**検索・関係別一覧のユーザー要素**
```json
{
  "id": "uuid",
  "user_code": "sora_js",
  "display_name": "Sora",
  "avatar_url": "https://.../photo.jpg",
  "relationship": "friend",
  "streak_days": 7
}
```

- `relationship`: `none` / `friend` / `outgoing_request` / `incoming_request`
- `GET /v1/users/by-code/{user_code}` は `user_code` の完全一致で検索し、自分自身を検索結果へ含めない
- `streak_days` は承認済みフレンドを返す場合だけ含め、ユーザー検索、送信申請、受信申請には含めない
- 完全一致検索は `user` を1件返し、該当しない場合は `PUBLIC_USER_NOT_FOUND` とする
- 関係別一覧はページングに対応し、レスポンスに `users` と `next_cursor` を含める
- `POST /v1/friend-requests` のリクエストは `{"target_user_id":"uuid"}` とする
- 重複申請、自分自身への申請、既存フレンドへの申請は拒否する
- 承認・拒否は受信中、取消は送信中、解除はフレンド中の場合のみ許可する

---

### GET /v1/skills

**概略**: スキルとスキルノードの一覧を取得する（実装済み）。
**認証是非**: 不要

**レスポンスボディ** `200 OK`
```json
{
  "skills": [
    {
      "id": "uuid",
      "slug": "js-basics",
      "name": "JavaScript 基礎",
      "description": "...",
      "display_order": 1,
      "nodes": [
        {
          "id": "uuid",
          "skill_id": "uuid",
          "prerequisite_node_ids": [],
          "slug": "values-and-types",
          "name": "値と型",
          "difficulty": 1,
          "display_order": 1
        }
      ]
    }
  ]
}
```

---

### GET /v1/questions

**概略**: 問題を検索する。学習画面の「問題を選ぶ」「検索する」両方に使う。`status=published` のみを返す。
**認証是非**: 必須（`unanswered_only` の判定にログインユーザーが要るため）

**クエリパラメータ**

| パラメータ | 型 | 説明 |
| --- | --- | --- |
| `skill_node_id` | uuid | 指定ノードの問題に絞る |
| `type` | question_type | 問題タイプで絞る |
| `language` | string | `code_language` で絞る |
| `difficulty` | int(1-5) | 難易度で絞る |
| `tag` | string（複数可） | `tags` に含む問題に絞る |
| `q` | string | `title` / `body` の部分一致検索 |
| `unanswered_only` | bool | true で自分が未回答の問題のみ（default false） |
| `cursor` / `limit` | string / int | ページング |

**レスポンスボディ** `200 OK`
```json
{
  "questions": [
    {
      "id": "uuid",
      "type": "code_reading",
      "difficulty": 2,
      "title": "配列メソッドの挙動",
      "code_language": "typescript",
      "tags": ["array", "es2020"],
      "skill_node_id": "uuid",
      "answered": false
    }
  ],
  "next_cursor": null
}
```
一覧では `correct_keys` / `explanation` / `body` / `choices` を含めない（軽量化。詳細は `GET /v1/questions/{id}`）。

---

### GET /v1/questions/{id}

**概略**: 問題を1件取得する。
**認証是非**: 必須

**レスポンスボディ** `200 OK`
```json
{
  "id": "uuid",
  "skill_node_id": "uuid",
  "type": "output_prediction",
  "difficulty": 2,
  "title": "配列メソッドの挙動",
  "body": "次のコードの出力として正しいものを選べ",
  "code": "console.log([1,2,3].map(x => x * 2))",
  "code_language": "javascript",
  "choices": [
    {"key": "a", "text": "[1,2,3]"},
    {"key": "b", "text": "[2,4,6]"}
  ],
  "tags": ["array"],
  "attribution": {
    "repo_full_name": "llm-generated",
    "license_spdx": "N/A"
  },
  "answered": false,
  "correct_keys": null,
  "explanation": null
}
```
- `answered=false` の場合、`correct_keys` / `explanation` は `null`（採点前に正解を渡さないため。`codetrain-core/pkg/domain` の `Question` コメントと整合）
- `answered=true`（`attempt` に既存回答がある）の場合、`correct_keys` / `explanation` を含める

**エラー**: `QUESTION_NOT_FOUND`（404。存在しない、または `status != published`）

---

### POST /v1/questions/{id}/attempts

**概略**: 回答を送信する。`attempt` を1行 INSERT し、同一トランザクションで `user_progress`（XP・hearts）・`user_type_stat`・`srs_state`・対応する `daily_task`（存在すれば `completed_at`/`attempt_id`）を更新する（[DB_SCHEMA.md](DB_SCHEMA.md) §7 ステップ3）。
**認証是非**: 必須

**リクエストボディ**
```json
{
  "selected_keys": ["b"],
  "duration_ms": 8200
}
```

**レスポンスボディ** `201 Created`
```json
{
  "attempt_id": "uuid",
  "is_correct": true,
  "correct_keys": ["b"],
  "explanation": "map は各要素に関数を適用した新配列を返す",
  "xp_gained": 10,
  "progress": {
    "xp": 130,
    "level": 3,
    "streak_days": 5,
    "last_studied_on": "2026-09-02",
    "hearts": 4,
    "current_skill_node_id": "uuid"
  },
  "daily_task_completed": {
    "slot_no": 2,
    "activity_date": "2026-09-02"
  }
}
```
- `daily_task_completed` は、この回答が今日の `daily_task` の未消化スロットに一致した場合のみ含む（それ以外は `null`）。復習（SRS）目的の再回答など、当日タスクに紐付かない回答では `null`
- 同一問題への複数回回答は許容する（`attempt` に一意制約は無い。[DB_SCHEMA.md](DB_SCHEMA.md) §5 `attempt` 備考）。ただし `daily_task` の消化判定は「スロットに対応する最初の正しい回答」等の具体規則が必要で、[OPEN_ISSUES.md](OPEN_ISSUES.md) B-3 に委ねる

**エラー**: `QUESTION_NOT_FOUND` / `VALIDATION_ERROR`（`selected_keys` が `choices` の `key` に無い値を含む）

---

### GET /v1/srs/due

**概略**: 復習期限（`srs_state.due_on <= 今日`）が来ている問題一覧を取得する（[DESIGN.md](DESIGN.md) §6 `srs_state`）。学習画面の「復習」タブに使う。
**認証是非**: 必須

**クエリパラメータ**: `limit`（default 20）

**レスポンスボディ** `200 OK`
```json
{
  "questions": [
    {
      "id": "uuid",
      "type": "code_reading",
      "difficulty": 2,
      "title": "配列メソッドの挙動",
      "code_language": "typescript",
      "tags": ["array"],
      "due_on": "2026-09-01"
    }
  ]
}
```
`due_on` が古い順（期限超過が長いものを優先）。

---

### GET /v1/task-slots

**概略**: 設定済みのタスクスロット（最大5）を取得する（`user_task`）。
**認証是非**: 必須

**レスポンスボディ** `200 OK`
```json
{
  "slots": [
    {"slot_no": 1, "question_type": "code_reading", "language": "typescript", "difficulty": null},
    {"slot_no": 2, "question_type": "output_prediction", "language": "", "difficulty": 3}
  ]
}
```
未設定のスロット番号は配列に含まれない。`difficulty: null` は「サーバが推奨レベルを解決する」（[DB_SCHEMA.md](DB_SCHEMA.md) §5 `user_task`）。

---

### PUT /v1/task-slots/{slot_no}

**概略**: タスクスロットを設定する（`slot_no` 1〜5。存在しなければ作成、あれば更新＝upsert）。
**認証是非**: 必須

**リクエストボディ**
```json
{
  "question_type": "code_reading",
  "language": "typescript",
  "difficulty": null
}
```
- `language` 省略時は `""`（言語を問わない）
- `(question_type, language, difficulty)` の組み合わせは `GET /v1/task-slots/options` の候補に存在する必要がある（`difficulty: null` のときは `question_type`/`language` の組み合わせのみ検証）

**レスポンスボディ** `200 OK`（設定後のスロット1件）

**エラー**: `TASK_SLOT_NO_INVALID`（404 or 400。`slot_no` が1〜5の範囲外）/ `TASK_SLOT_OPTION_INVALID`（422。`available_task_option` に存在しない組み合わせ）

---

### DELETE /v1/task-slots/{slot_no}

**概略**: タスクスロットを削除する。
**認証是非**: 必須

**レスポンス**: `204 No Content`

**エラー**: `TASK_SLOT_NO_INVALID`（404。該当スロットが未設定）

---

### GET /v1/task-slots/options

**概略**: タスク設定画面で選択可能な（種別, 言語, 難易度）の組み合わせを取得する（`available_task_option` ビュー。[DB_SCHEMA.md](DB_SCHEMA.md) §6）。
**認証是非**: 必須

**レスポンスボディ** `200 OK`
```json
{
  "options": [
    {"question_type": "code_reading", "language": "typescript", "difficulty": 1},
    {"question_type": "code_reading", "language": "typescript", "difficulty": 2},
    {"question_type": "output_prediction", "language": "", "difficulty": 1}
  ]
}
```
`published` な問題バンクに実在する組み合わせのみを返す（設定できるが割当不能、を防ぐ）。

---

### GET /v1/home

**概略**: ホーム画面の「今日のタスク」を取得する。初回アクセス時、当日分の `daily_task` 行が無ければサーバが冪等に割り当てる（`ON CONFLICT (user_id, activity_date, slot_no) DO NOTHING`。[DB_SCHEMA.md](DB_SCHEMA.md) §7 ステップ2）。
**認証是非**: 必須

**レスポンスボディ** `200 OK`
```json
{
  "activity_date": "2026-09-02",
  "tasks": [
    {
      "id": "uuid",
      "slot_no": 1,
      "question_type": "code_reading",
      "language": "typescript",
      "difficulty": 2,
      "question": {
        "id": "uuid",
        "title": "配列メソッドの挙動",
        "type": "code_reading",
        "difficulty": 2
      },
      "completed_at": null
    }
  ],
  "monthly_progress": {
    "studied_days": 16,
    "max_days": 30
  },
  "study_tasks": [
    {
      "task_no": 1,
      "languages": ["csharp", "typescript", "ruby"]
    },
    {
      "task_no": 2,
      "languages": ["typescript"]
    }
  ],
  "review": {
    "due_count": 12
  }
}
```
- `tasks` の要素数 = そのユーザーの `user_task` 設定スロット数（0〜5）。未設定なら空配列
- 各タスクの `question` は割り当てられた問題のプレビュー（回答は `POST /v1/questions/{id}/attempts` で行う）
- `monthly_progress` は当月の学習日数と進捗上限を返す。`max_days` は暦月の日数と30の小さい方とし、通常の2月は28、31日ある月は30とする。
- `tasks` は個別の問題割当、`study_tasks` はホーム画面で切り替える学習タスク（その日に学習する言語のまとまり）を表す。`study_tasks` は `task_no` 順で返し、各タスクの `languages` をそのまま一つの言語アイコン列として表示する。
- `study_tasks` の各要素は、タスク切り替え時に言語一覧をまとめて切り替えるための表示単位である。言語の追加枠はクライアントが表示する。
- ホームの再生ボタンは選択中の `study_tasks.task_no` を開始対象の識別子として利用し、タスク画面からの開始はタスク単位APIの `task_id` を利用する。開始時に問題を取得するAPIまたは開始エンドポイントの具体仕様は、タスク単位のAPI設計と合わせて確定する。
- `review.due_count` は `/v1/srs/due` で取得できる復習期限到来問題の件数とする。復習画面では必要に応じて `/v1/srs/due` を呼び出す。

**エラー**: `NO_AVAILABLE_QUESTION`（422。あるスロットの条件に合う未回答 `published` 問題が枯渇。フォールバック方針は [OPEN_ISSUES.md](OPEN_ISSUES.md) B-10 未確定のため、該当スロットを欠番として返す挙動も許容し実装時に確定する）

---

### GET /v1/calendar

**概略**: カレンダー画面用に、期間内の日別タスク消化状況と連続日数を取得する。`daily_task` から算出する（[DB_SCHEMA.md](DB_SCHEMA.md) §7〜§8）。
**認証是非**: 必須

**クエリパラメータ**: `from`（date, 必須）/ `to`（date, 必須）

**レスポンスボディ** `200 OK`
```json
{
  "days": [
    {
      "date": "2026-09-01",
      "total_slots": 3,
      "completed_slots": 3,
      "completed": true,
      "tasks": [
        {
          "task_id": "uuid",
          "name": "TypeScript 基礎",
          "total_questions": 3,
          "completed_questions": 3,
          "contents": [
            {
              "question_type": "code_reading",
              "language": "typescript",
              "difficulty": 1,
              "question_count": 2
            },
            {
              "question_type": "output_prediction",
              "language": "",
              "difficulty": 2,
              "question_count": 1
            }
          ]
        }
      ]
    },
    {
      "date": "2026-09-02",
      "total_slots": 3,
      "completed_slots": 1,
      "completed": false,
      "tasks": []
    }
  ],
  "streak_days": 5,
  "last_studied_on": "2026-09-01"
}
```
- `completed` = 当日の全 `daily_task` 行が `completed_at IS NOT NULL`（[DB_SCHEMA.md](DB_SCHEMA.md) §5 `daily_task` 備考）
- `days` は `daily_task` 行が存在する日のみ（未アクセスの日は配列に含まれない）
- `tasks` は当日に割り当てられたタスク単位の学習内容と問題数を返す。タスク画面で設定した問題種別・言語・難易度を `contents` に集約し、同じ組み合わせの件数を `question_count` とする。
- `total_questions` / `completed_questions` はタスク単位の問題数と完了数を返す。過去日の表示が現在のタスク編集に影響されないよう、当日割当時の設定または `daily_task` と問題情報から復元した値を使用する。
- タスク単位APIの `task_id` / `name` が確定するまでは `tasks` の実装も保留とし、API接続前に両方の契約を一致させる。
- `streak_days` は §8 のクエリ（gaps-and-islands）による逆算値、または `user_progress.streak_days` キャッシュのいずれか（実装時に選択。値は一致する想定）

---

### GET /v1/admin/questions

**概略**: レビュー画面向けに `status` を問わず問題を横断検索する。
**認証是非**: 必須（レビュアー）

**クエリパラメータ**: `status` / `type` / `language` / `skill_id` / `q` / `cursor` / `limit`

**レスポンスボディ** `200 OK`
```json
{
  "questions": [
    {
      "id": "uuid",
      "status": "needs_review",
      "type": "bug_finding",
      "difficulty": 3,
      "title": "オフバイワンエラー",
      "created_at": "2026-09-01T10:00:00Z"
    }
  ],
  "next_cursor": null
}
```

---

### GET /v1/admin/review-queue

**概略**: 未レビュー（`review_queue.decision IS NULL`）の問題一覧を取得する（[DB_SCHEMA.md](DB_SCHEMA.md) §5 `review_queue`）。
**認証是非**: 必須（レビュアー）

**クエリパラメータ**: `cursor` / `limit`

**レスポンスボディ** `200 OK`
```json
{
  "items": [
    {
      "review_id": "uuid",
      "question_id": "uuid",
      "title": "オフバイワンエラー",
      "type": "bug_finding",
      "difficulty": 3,
      "queued_at": "2026-09-01T10:00:00Z"
    }
  ],
  "next_cursor": null
}
```

---

### GET /v1/admin/questions/{id}

**概略**: レビューに必要な全項目（正解・生成メタデータ・出典・レビュー履歴）を取得する。
**認証是非**: 必須（レビュアー）

**レスポンスボディ** `200 OK`
```json
{
  "id": "uuid",
  "status": "needs_review",
  "type": "bug_finding",
  "difficulty": 3,
  "title": "オフバイワンエラー",
  "body": "...",
  "code": "for (let i = 0; i <= arr.length; i++) { ... }",
  "code_language": "javascript",
  "choices": [{"key": "a", "text": "..."}],
  "correct_keys": ["a"],
  "explanation": "...",
  "tags": ["loop"],
  "skill_node_id": "uuid",
  "raw_source_id": "00000000-0000-0000-0000-000000000001",
  "prompt_version": "v3",
  "model_id": "claude-haiku-4-5",
  "gen_tokens": 812,
  "generated_at": "2026-09-01T09:55:00Z",
  "review_history": [
    {
      "id": "uuid",
      "reviewer_id": "uuid",
      "decision": null,
      "notes": null,
      "created_at": "2026-09-01T10:00:00Z"
    }
  ]
}
```
`review_history` は `review_queue` の当該 `question_id` 全行（新しい順）。`decision: null` の行が現在の未レビュー行。

**エラー**: `QUESTION_NOT_FOUND`

---

### PATCH /v1/admin/questions/{id}

**概略**: 問題内容を修正する（レビュー時の難易度調整・文言修正など）。渡したフィールドのみ更新する。
**認証是非**: 必須（レビュアー）

**リクエストボディ**（すべて任意、部分更新）
```json
{
  "title": "オフバイワンエラー（修正版）",
  "body": "...",
  "code": "...",
  "code_language": "javascript",
  "choices": [{"key": "a", "text": "..."}],
  "correct_keys": ["a"],
  "explanation": "...",
  "difficulty": 2,
  "tags": ["loop", "off-by-one"],
  "skill_node_id": "uuid"
}
```

**レスポンスボディ** `200 OK`（更新後の問題全項目。§3 `GET /v1/admin/questions/{id}` と同形）

**エラー**: `QUESTION_NOT_FOUND` / `VALIDATION_ERROR`（`difficulty` が1〜5外、`correct_keys` が `choices` に無い等）

---

### POST /v1/admin/questions/{id}/review

**概略**: レビュー判定を記録する。`review_queue` に新規行を INSERT し、`decision` に応じて `question.status` を遷移させる（[DESIGN.md](DESIGN.md) §5 フロー図）。
**認証是非**: 必須（レビュアー）

**リクエストボディ**
```json
{
  "decision": "approved",
  "notes": "コードの意図通り。難易度は妥当"
}
```
`decision`: `approved`（→ `question.status = published`）/ `rejected`（→ `rejected`）/ `needs_edit`（→ `needs_review` のまま。`notes` に修正依頼を書く運用）

**レスポンスボディ** `201 Created`
```json
{
  "id": "uuid",
  "question_id": "uuid",
  "reviewer_id": "uuid",
  "decision": "approved",
  "notes": "コードの意図通り。難易度は妥当",
  "reviewed_at": "2026-09-02T04:00:00Z"
}
```

**エラー**: `QUESTION_NOT_FOUND` / `REVIEW_ALREADY_DECIDED`（409。当該問題に未レビュー行が存在しない＝既に判定済み）/ `VALIDATION_ERROR`（`decision` が3値以外）

---

## 4. エラーコード一覧

すべてのエラーは以下のエンベロープで返す。

```json
{
  "error": {
    "code": "STRING_CODE",
    "message": "日本語の説明文"
  }
}
```

### 共通コード（複数エンドポイントで共通）

| コード | HTTP ステータス | 説明 |
| --- | --- | --- |
| `VALIDATION_ERROR` | 400 | リクエストボディ・クエリパラメータが不正 |
| `UNAUTHORIZED` | 401 | 認証トークンが無い、または無効 |
| `FORBIDDEN` | 403 | 認証は成功しているが権限が不足（例: レビュアー権限が無い一般ユーザーが `/v1/admin/*` を叩いた） |
| `NOT_FOUND` | 404 | リソースが存在しない（汎用。個別コードが定義されている場合はそちらを優先） |
| `CONFLICT` | 409 | 状態競合（汎用） |
| `INTERNAL_ERROR` | 500 | サーバ内部エラー。詳細はクライアントに返さずログにのみ出力する（既存 `handler.internalError` の方針を踏襲） |

### 業務固有コード

| コード | HTTP ステータス | 説明 |
| --- | --- | --- |
| `USER_NOT_FOUND` | 404 | 認証済みだが `app_user` に未登録（`POST /v1/me` が必要） |
| `USER_ALREADY_PROVISIONED` | 409 | `POST /v1/me` を、既に登録済みの `external_id` で呼んだ |
| `PUBLIC_USER_NOT_FOUND` | 404 | 指定した公開用ユーザーIDに完全一致する検索可能なユーザーが存在しない |
| `FRIEND_REQUEST_CONFLICT` | 409 | 重複申請、自分自身への申請、既存フレンドへの申請、または現在の関係状態と操作が一致しない |
| `FRIEND_RELATION_NOT_FOUND` | 404 | 対象ユーザーまたは操作対象の申請・フレンド関係が存在しない |
| `QUESTION_NOT_FOUND` | 404 | 問題が存在しない、または（一般ユーザーからは）`status != published` |
| `TASK_SLOT_NO_INVALID` | 400 / 404 | `slot_no` が1〜5の範囲外、または該当スロットが未設定（DELETE時） |
| `TASK_SLOT_OPTION_INVALID` | 422 | 指定した（種別, 言語, 難易度）が `available_task_option` に存在しない |
| `NO_AVAILABLE_QUESTION` | 422 | タスクスロットの条件に合う未回答 `published` 問題が枯渇。フォールバック方針は [OPEN_ISSUES.md](OPEN_ISSUES.md) B-10 で未確定 |
| `REVIEW_ALREADY_DECIDED` | 409 | レビュー対象の問題に未レビュー行（`decision IS NULL`）が存在しない＝既に判定済み |

---

## 5. 未確定事項との対応

本設計のうち、値やアルゴリズムを断定していない箇所は以下に委ねる。

| 箇所 | 未確定事項 | 参照 |
| --- | --- | --- |
| `POST /v1/questions/{id}/attempts` の `xp_gained` | XP配点表 | [OPEN_ISSUES.md](OPEN_ISSUES.md) B-3 |
| `progress.hearts` の回復 | ハート上限・消費・回復間隔 | B-3 |
| `daily_task` の判定タイムゾーン | 連続日数の判定基準（ユーザーローカル or 固定） | B-3 |
| `GET /v1/home` の難易度未指定スロット解決 | 推奨難易度アルゴリズム、未回答問題枯渇時のフォールバック | B-10 |
| `srs_state` の間隔更新規則 | SM-2 初期値・不正解時のリセット規則 | B-4 |
| `/v1/admin/*` の権限モデル | レビュアーロールの表現・付与方法 | C-5 / D-2 |
| フレンド機能 | 検索可能な公開範囲、ブロック機能、申請・解除後の保持期間 | 新規検討事項 |
