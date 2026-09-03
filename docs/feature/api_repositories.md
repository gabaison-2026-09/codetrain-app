# API Repository

## 目的

`docs/API_DESIGN.md` のバックエンド実装完了後、Composition Rootで実装を差し替えるだけで接続できるよう、admin/Auth系を除くHTTP通信とDTO変換を先行実装する。

## 構成

- 共通通信・エラー変換・疎通確認: `lib/core/network/`
- ユーザー、プロフィール、ホーム: `lib/features/home/data/`
- スキル、問題、回答、SRS: `lib/features/learn/data/`
- タスクスロット: `lib/features/task/data/`
- カレンダー: `lib/features/calendar/data/`
- フレンド暫定契約: `lib/features/friend/data/`

各実装は共通の `ApiClient` を直接、またはfeature固有のData Sourceを介して受け取る。`ApiClient` は `http.Client` をコンストラクタ注入でき、テストでは `MockClient` を使用する。Composition Rootは今回変更せず、実行中のアプリは引き続きMock Repositoryを使用する。

## 暫定対応と既知の制約

- `GET /v1/me` に `experience_progress` と `max_hearts` がないため、`ApiTopNavigationRepository` のコンストラクタ既定値（0、5）を変換境界で使用する。契約追加後はレスポンス値へ置き換える。
- `Document/API_DESIGN.md` の `GET /v1/home` に月間進捗がない場合、学習日数0と対象月の日数（最大30）を変換境界で補う。
- `/v1/task-slots` はユーザー単位の5スロットだけを表すため、API版では単一の仮想タスクとして既存 `TaskRepository` を満たす。複数タスク、名前、ホーム対象最大3件はタスク単位APIの設計更新後に対応する。
- フレンドAPIはバックエンド未実装の暫定契約である。公開範囲、ブロック、申請・解除後の保持期間が確定したら契約と実装を同時に更新する。

## テスト

`test/features/*/data/` と `test/core/network/` で設計書のJSON例を `MockClient` から返し、HTTP method/path/query/body、DTOからドメインへの変換、エラーエンベロープから `ApiException` への変換を検証する。実サーバーには接続しない。
