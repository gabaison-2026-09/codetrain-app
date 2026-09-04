# アプリ名称

## 仕様

- ユーザー向けのアプリ名称は `CodeYomel` とする。
- ログイン画面、アカウント作成画面、ライセンス画面、Flutterのアプリタイトル、Android/iOSのホーム画面ラベルで同じ名称を表示する。
- 既存コードへの影響を限定するため、`CodeTrainApp` などのクラス名、`codetrain_app` パッケージ名、Bundle ID、Application IDは変更しない。

## 主な実装箇所

- `lib/app/app.dart`
- `lib/features/authentication/presentation/`
- `lib/features/legal/presentation/open_source_licenses_page.dart`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

## 実装状況

ユーザーに表示されるアプリ名称を `CodeTrain` から `CodeYomel` へ変更済み。
