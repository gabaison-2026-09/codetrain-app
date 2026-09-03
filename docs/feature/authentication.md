# 認証

## 仕様

- アプリ起動時、未認証の場合はログイン画面を表示する。
- メールアドレスとパスワードによるログイン、Googleログインを選択できる。
- ログイン画面から専用のアカウント新規作成画面へ遷移できる。
- アカウント新規作成ではメールアドレス、パスワード、確認用パスワードを入力し、作成成功後は初回タスク提案画面を表示する。
- 初回タスクを確定した後にホーム画面を表示する。既存ユーザーのログイン時は初回タスク提案を表示しない。
- アカウント新規作成画面からログイン画面へ戻れる。
- パスワード入力欄には表示・非表示の切り替えを設ける。
- ログイン成功後は既存のホーム画面を表示する。
- 白背景、紫のアクセント、既存フォントを使用し、グラデーションとカード型UIは使用しない。
- 認証処理は `AuthRepository` を境界とし、画面から具体的な認証サービスを参照しない。

## 現在の実装

- `MockAuthRepository` はログインとアカウント新規作成の入力値を保存・送信せず、メモリ上でモックの認証結果を返す。
- メールアドレスは基本的な形式、パスワードは6文字以上であることを画面で検証する。
- アカウント新規作成では確認用パスワードとの一致も画面で検証する。
- 認証状態はアプリ実行中だけ保持し、アプリ再起動時にはログイン画面へ戻る。
- Firebase SDK、プラットフォーム設定、外部通信はまだ追加していない。
- 初回タスク提案の回答は現在のモック実装では外部送信・永続保存しない。

## Firebase接続時の差し替え

- `features/authentication/data/` に Firebase Authentication を利用する `AuthRepository` 実装を追加する。
- メール／パスワードによるログインとアカウント新規作成、Googleログインの各操作を同じRepository interfaceへ接続する。
- Firebase IDトークンを `AuthSession.idToken` として返し、API Clientが `Authorization: Bearer <token>` に使用する。
- 認証後に `GET /v1/me` を呼び、`USER_NOT_FOUND` の場合は `POST /v1/me` で初回ユーザーを作成する。
- 現在のAPI設計はCognito JWTを指定しているため、Firebase接続前にバックエンドのトークン検証方式を確定し、`docs/API_DESIGN.md` を更新する。

## 主な実装箇所

- `lib/features/authentication/presentation/login_page.dart`
- `lib/features/authentication/presentation/create_account_page.dart`
- `lib/features/authentication/domain/auth_repository.dart`
- `lib/features/authentication/data/mock_auth_repository.dart`
- `lib/app/app.dart`
