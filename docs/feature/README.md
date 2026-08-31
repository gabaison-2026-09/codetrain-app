# 機能仕様書一覧

`docs/feature/` 配下の機能仕様書を一覧で管理する。各機能の詳細な仕様、構成、実装状況はリンク先の仕様書を参照する。

| 機能 | 仕様書 | 用途 | 主な実装箇所 |
| --- | --- | --- | --- |
| ボトムナビゲーション | [`bottom_navigation.md`](bottom_navigation.md) | ホーム画面下部に Calendar、Learn、Home、Task、Profile の5つのタブを表示し、選択状態に応じて対応する簡易画面へ切り替える。 | `lib/shared/widgets/code_train_bottom_navigation.dart`、`lib/features/home/presentation/home_page.dart` |

## 更新ルール

- 新しい機能仕様書を追加した場合は、この一覧にも機能名、用途、主な実装箇所を追記する。
- 仕様の詳細や実装状況は、各機能の仕様書に記載する。
- 機能名と仕様書のファイル名は、対応関係が分かるように揃える。
