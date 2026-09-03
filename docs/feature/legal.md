# ライセンス表示

## 概要

アプリ内で使用しているプログラミング言語アイコンの出典、ライセンス本文、追加の帰属表示、商標・非提携に関する注意事項を表示する。

## 仕様

- ホーム画面のコンテンツ末尾に「オープンソースライセンス」リンクを表示する。
- リンクはホーム画面の右下寄りに控えめに表示する。
- リンクをタップすると、アプリ内のライセンス画面へ遷移する。
- ライセンス画面はカード型UIを使用せず、白背景のフラットなセクションで表示する。
- ライセンス画面では、DeviconのMIT License本文を表示する。
- PHP、Ruby、Rustのロゴについては、著作権者、適用されるCreative Commonsライセンス、ライセンスURLを表示する。
- プログラミング言語の名称・ロゴの商標権が各権利者に帰属すること、およびCodeTrainによる承認・後援・提携を示すものではないことを表示する。
- ライセンス表示は外部サイトへの遷移を必須とせず、アプリ内で閲覧・選択コピーできるものとする。

## 主な実装箇所

- `lib/features/legal/presentation/open_source_licenses_page.dart`
- `lib/features/home/presentation/home_tab_page.dart`
- `THIRD_PARTY_NOTICES.md`
- `assets/icons/programming_languages/LICENSE`
- `assets/icons/programming_languages/SOURCE.md`

## 実装状況

- [x] ホーム画面下部のライセンス画面リンク
- [x] アプリ内ライセンス表示画面
- [x] Devicon MIT License本文の表示
- [x] PHP、Ruby、Rustの追加帰属表示
- [x] 商標・非提携に関する注意書き
