# ボトムナビゲーション

## 仕様

- ホーム画面の下部にボトムナビゲーションを表示する。
- Calendar、Learn、Home、Task、Profile の5つのタブを表示する。
- タップした位置に最も近いタブを選択し、選択状態の移動アニメーションを表示する。
- 端末の下部システム領域を考慮して表示領域を確保する。

## 構成

- 共通 Widget: `lib/shared/widgets/code_train_bottom_navigation.dart`
- 表示画面: `lib/features/home/presentation/home_page.dart`

## 実装状況

既存のボトムナビゲーションの描画、タブ選択、アニメーションおよびレイアウト挙動を維持したまま、アプリ起動・画面・共通 Widget を責務ごとに分離している。
