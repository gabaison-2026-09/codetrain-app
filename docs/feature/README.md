# 機能仕様書一覧

`docs/feature/` 配下の機能仕様書を一覧で管理する。各機能の詳細な仕様、構成、実装状況はリンク先の仕様書を参照する。

| 機能 | 仕様書 | 用途 | 主な実装箇所 |
| --- | --- | --- | --- |
| ボトムナビゲーション | [`bottom_navigation.md`](bottom_navigation.md) | ホーム画面下部に Calendar、Learn、Home、Task、Profile の5つのタブを表示し、選択状態に応じて対応する画面へ切り替える。選択中の拡大円は分離前は白、分離後はタブごとの淡い色と同系色の輪郭線で表示し、分離時に触覚フィードバックを発生させる。 | `lib/shared/widgets/code_train_bottom_navigation.dart`、`lib/features/*/presentation/*_page.dart` |
| トップナビゲーション | [`top_navigation.md`](top_navigation.md) | ホーム画面上部にプロフィール、レベル、経験値進捗、ハートを表示する。 | `lib/shared/widgets/code_train_top_navigation.dart`、`lib/features/home/presentation/home_page.dart`、`lib/features/home/data/`、`lib/features/home/domain/` |
| ホームダッシュボード | [`home_dashboard.md`](home_dashboard.md) | 日付、連続学習日数、当月の学習進捗、学習状況、学習タスク切り替え用の再生ボタン、選択タスクの言語アイコンを表示する。 | `lib/features/home/presentation/home_tab_page.dart`、`lib/features/home/data/`、`lib/features/home/domain/` |
| 学習画面 | [`learning.md`](learning.md) | スキルと学習項目を選び、四択問題へ継続的に回答し、正誤・解説に加えて5問ごとの正解数・獲得XPを確認しながら学習する。 | `lib/features/learn/presentation/`、`lib/features/learn/data/`、`lib/features/learn/domain/` |

## 更新ルール

- 新しい機能仕様書を追加した場合は、この一覧にも機能名、用途、主な実装箇所を追記する。
- 仕様の詳細や実装状況は、各機能の仕様書に記載する。
- 機能名と仕様書のファイル名は、対応関係が分かるように揃える。
