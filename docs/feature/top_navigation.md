# トップナビゲーション

## 仕様

- ホーム画面上部に、プロフィール・レベル・経験値進捗・ハートを表示する。
- プロフィールは円形のアウトラインとユーザーアイコンで表示する。
- 初期表示は `Lv.12`、経験値進捗 62%、ハート5個中3個を右端から淡い赤の塗りつぶしで表示する。
- 未充填のハートは枠線なしの淡い灰色で表示する。
- カード本体を画面の上端・左右端まで広げ、内部のコンテンツ余白は維持する。
- ノッチやステータスバー領域にもカードの白背景を描画し、内部コンテンツのみ安全領域の下に配置する。
- 端末幅に合わせて左右の余白とレベル表示・ハート表示の間隔を調整する。

## データ構成

- 表示データは `TopNavigationStatus` に集約し、Widget は表示用の値だけを受け取る。
- `TopNavigationRepository` をデータ取得の境界とし、現在は `MockTopNavigationRepository` を使用する。
- `HomePage` に Repository を注入できるため、バックエンド接続時は API 取得用の実装を渡す。

## 構成

- 共通 Widget: `lib/shared/widgets/code_train_top_navigation.dart`
- 表示位置: `lib/features/home/presentation/home_page.dart`
- データモデル: `lib/features/home/domain/top_navigation_status.dart`
- Repository: `lib/features/home/domain/top_navigation_repository.dart`
- モック実装: `lib/features/home/data/mock_top_navigation_repository.dart`

## 実装状況

`CodeTrainTopNavigation` として実装済み。`HomePage` の全タブ共通レイアウト上部に表示している。
