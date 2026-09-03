# codetrain_app

CodeTrain の Flutter アプリ。

## Getting Started

Flutter が初めての場合は以下を参照してください。

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [online documentation](https://docs.flutter.dev/)

## 環境（接続先）の切り替え

API の接続先とローカル／本番の認証方式は、起動時の `--dart-define` で切り替えます。
仕様は [`docs/API_DESIGN.md`](docs/API_DESIGN.md) を正とし、設定の解決は
[`lib/core/env/app_config.dart`](lib/core/env/app_config.dart) が担当します。

| dart-define | 説明 | 既定値 |
| --- | --- | --- |
| `API_BASE_URL` | API のベース URL（`/v1` は含めない） | 未指定時は `http://10.0.2.2:8080`（Android エミュレータからホストを指すアドレス） |
| `AUTH_MODE` | `dev` / `prod`。`dev` は `X-Dev-User` ヘッダー、`prod` は `Authorization: Bearer <token>` を付与 | `dev` |
| `DEV_USER` | `AUTH_MODE=dev` のとき `X-Dev-User` に載せる文字列 | `local-dev-user` |
| `AUTH_BEARER_TOKEN` | `AUTH_MODE=prod` の暫定トークン（取得方式が未決定のため当面 dart-define で渡す） | 未指定（ヘッダー無し） |

`API_BASE_URL` を指定すると環境は `dev`、未指定（フォールバック）なら `local`、
`AUTH_MODE=prod` なら `prod` として解決されます。

### 例

```bash
# ローカルの codetrain-api（AUTH_MODE=dev）に接続する既定の開発起動
flutter run

# iOS シミュレータ・実機・Web はフォールバック URL に到達できないため明示指定が必要
flutter run --dart-define=API_BASE_URL=http://localhost:8080

# ステージング等の共有開発サーバー（dev 認証）
flutter run \
  --dart-define=API_BASE_URL=https://staging.example.com \
  --dart-define=DEV_USER=engineer_taro

# 本番相当（Bearer 認証）
flutter run \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=AUTH_MODE=prod
```

デバッグ起動時は解決結果を `AppConfig: ...` として起動ログに出力します。

`flutter build`（apk / ipa / web）でも同じ `--dart-define` を付与します。
CI やリリースビルドでは `--dart-define-from-file` に設定ファイルをまとめる運用も可能です。

> `Authorization: Bearer <token>` のトークン取得方式（Cognito / Firebase Authentication）は
> 未決定です。決定後に [`lib/core/network/auth_header_provider.dart`](lib/core/network/auth_header_provider.dart)
> の `BearerTokenAuthHeaderProvider` を実装します。
