# ログイン

## 仕様

- アプリ起動時、未認証の場合はログイン画面を表示する。
- メールアドレスとパスワードによるログイン、Googleログインを選択できる。
- パスワード入力欄には表示・非表示の切り替えを設ける。
- ログイン成功後は既存のホーム画面を表示する。
- 白背景、紫のアクセント、既存フォントを使用し、グラデーションとカード型UIは使用しない。
- 認証処理は `AuthRepository` を境界とし、画面から具体的な認証サービスを参照しない。

## 現在の実装

- `MockAuthRepository` は入力値を保存・送信せず、メモリ上でモックの認証結果を返す。
- メールアドレスは基本的な形式、パスワードは6文字以上であることを画面で検証する。
- 認証状態はアプリ実行中だけ保持し、アプリ再起動時にはログイン画面へ戻る。
- Firebase SDK、プラットフォーム設定、外部通信はまだ追加していない。

## Firebase接続時の差し替え

- `features/authentication/data/` に Firebase Authentication を利用する `AuthRepository` 実装を追加する。
- メール／パスワードとGoogleの各操作を同じRepository interfaceへ接続する。
- Firebase IDトークンを `AuthSession.idToken` として返し、API Clientが `Authorization: Bearer <token>` に使用する。
- 認証後に `GET /v1/me` を呼び、`USER_NOT_FOUND` の場合は `POST /v1/me` で初回ユーザーを作成する。
- 現在のAPI設計はCognito JWTを指定しているため、Firebase接続前にバックエンドのトークン検証方式を確定し、`docs/API_DESIGN.md` を更新する。

## 主な実装箇所

- `lib/features/authentication/presentation/login_page.dart`
- `lib/features/authentication/domain/auth_repository.dart`
- `lib/features/authentication/data/mock_auth_repository.dart`
- `lib/app/app.dart`
