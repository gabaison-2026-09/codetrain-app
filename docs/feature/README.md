# 機能仕様書一覧

`docs/feature/` 配下の機能仕様書を一覧で管理する。各機能の詳細な仕様、構成、実装状況はリンク先の仕様書を参照する。

現在の実装状況とAPI接続の差し替え方は [`implementation_status.md`](implementation_status.md) にまとめている。

| 機能 | 仕様書 | 用途 | 主な実装箇所 |
| --- | --- | --- | --- |
| アプリ名称 | [`app_branding.md`](app_branding.md) | ユーザー向けのアプリ名称を `CodeYomel` に統一する。 | `lib/app/app.dart`、`lib/features/authentication/`、`lib/features/legal/`、`android/app/src/main/AndroidManifest.xml`、`ios/Runner/Info.plist` |
| 認証 | [`authentication.md`](authentication.md) | メール／パスワードまたはGoogleでログインでき、メール／パスワードによるアカウント新規作成にも対応する。新規作成時のパスワード入力は自動入力候補によるキーボード切断を避ける。現在はFirebase接続前のモック認証を使用する。 | `lib/features/authentication/`、`lib/app/app.dart` |
| 初回タスク提案 | [`task_recommendation.md`](task_recommendation.md) | 新規アカウント作成後に目的、希望言語、経験などを質問し、回答に合う最初の学習タスクを提案する。 | `lib/features/onboarding/`、`lib/app/app.dart` |
| ボトムナビゲーション | [`bottom_navigation.md`](bottom_navigation.md) | ホーム画面下部に Calendar、Learn、Home、Task、Friend の5つのタブを表示し、膨らみや押し出しのない基準位置とトレイ上端より下の領域による当たり判定で選択状態に応じて対応する画面へ切り替える。選択中の拡大円は分離前は白、分離後はタブごとの淡い色と同系色の輪郭線で表示し、分離時に触覚フィードバックを発生させる。 | `lib/shared/widgets/code_train_bottom_navigation.dart`、`lib/features/*/presentation/*_page.dart` |
| トップナビゲーション | [`top_navigation.md`](top_navigation.md) | ホーム画面上部にプロフィール、レベル、経験値進捗、ハートを表示する。 | `lib/shared/widgets/code_train_top_navigation.dart`、`lib/features/home/presentation/home_page.dart`、`lib/features/home/data/`、`lib/features/home/domain/` |
| ホームダッシュボード | [`home_dashboard.md`](home_dashboard.md) | 日付、連続学習日数、当月の学習進捗、単一タスク内の5学習スロットを切り替える再生ボタン、選択スロットの学習開始、言語アイコン1個を表示する。 | `lib/features/home/presentation/home_tab_page.dart`、`lib/shared/widgets/programming_language_icon.dart`、`lib/features/home/presentation/home_page.dart`、`lib/features/home/data/`、`lib/features/home/domain/` |
| ライセンス表示 | [`legal.md`](legal.md) | ホーム画面から、プログラミング言語アイコンの出典、ライセンス、追加帰属、商標・非提携に関する注意事項をアプリ内で閲覧できる。 | `lib/features/legal/presentation/open_source_licenses_page.dart`、`lib/features/home/presentation/home_tab_page.dart`、`THIRD_PARTY_NOTICES.md` |
| カレンダー | [`calendar.md`](calendar.md) | 月を移動して学習日と完了状態を確認し、選択日のタスク進捗を表示する。 | `lib/features/calendar/presentation/`、`lib/features/calendar/data/`、`lib/features/calendar/domain/` |
| 学習画面 | [`learning.md`](learning.md) | 言語アイコンと難易度範囲スライダーから学習カテゴリー・学習項目を選び、タスク設定に対応した問題を含む四択問題へ継続的に回答し、正誤・解説に加えて5問ごとの正解数・獲得XPを確認しながら学習する。 | `lib/features/learn/presentation/`、`lib/shared/widgets/programming_language_icon.dart`、`lib/shared/widgets/programming_language_selector.dart`、`lib/features/learn/data/`、`lib/features/learn/domain/` |
| タスク管理 | [`task_management.md`](task_management.md) | 単一の学習タスクにある5スロットを、学習画面と共通の言語ロゴUIで編集する。タスクの追加・削除は行わない。 | `lib/features/task/presentation/`、`lib/features/task/data/`、`lib/features/task/domain/`、`lib/shared/widgets/programming_language_selector.dart` |
| フレンド | [`friends.md`](friends.md) | 公開用ユーザーIDの完全一致検索、関係別の絞り込み、連続学習日数の表示、申請送信・取消、受信申請の承認・拒否、フレンド解除を行う。 | `lib/features/friend/presentation/`、`lib/features/friend/data/`、`lib/features/friend/domain/` |

## 更新ルール

- 新しい機能仕様書を追加した場合は、この一覧にも機能名、用途、主な実装箇所を追記する。
- 仕様の詳細や実装状況は、各機能の仕様書に記載する。
- 機能名と仕様書のファイル名は、対応関係が分かるように揃える。
