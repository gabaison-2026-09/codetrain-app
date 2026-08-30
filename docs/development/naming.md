# 命名規約

この文書は、Dart / Flutter の class、enum、関数、変数、ファイル、ディレクトリ、Widget、状態管理、データアクセス関連の命名規則を定める。実装時は [`AGENTS.md`](../../AGENTS.md) と、変更に関係する [`docs/development/architecture.md`](architecture.md) も確認する。

## 基本規則

命名はプロジェクト全体で一貫させ、名前から役割・責務・対象が判断できることを優先する。

* class、enum、typedef、extension、mixin は `UpperCamelCase` を使用する。
* 変数、定数、関数、メソッド、引数、プロパティは `lowerCamelCase` を使用する。
* ファイル名、ディレクトリ名は `snake_case` を使用する。
* enum の値は `lowerCamelCase` を使用する。
* private な識別子には `_` プレフィックスを使用する。外部公開する必要がない要素を不用意に public にしない。

## UI / Widget の命名

画面全体を表す Widget は `XxxPage` とする。`Screen`、`View` など別の接尾辞を同じ用途で混在させない。

画面内でのみ利用する private Widget は `_XxxSection`、`_XxxHeader`、`_XxxCard` など、その役割が分かる名前にする。

複数画面で利用する共通 Widget は、用途や役割を表す具体的な名前にする。`CommonWidget`、`CustomWidget`、`BaseWidget` など責務が不明確な名前を避ける。

## コールバックとイベント処理

コールバック引数は `onXxx` とする。例: `onTap`、`onChanged`、`onSubmit`。

UI イベントを受けて内部処理を行うメソッドは `handleXxx` とする。例: `handleSubmit`、`handleRetry`。

## Boolean

boolean 値は `is`、`has`、`can`、`should` などから始め、真偽の意味が名前から分かるようにする。

## 状態管理とデータアクセス

状態管理クラスには、採用する状態管理方式に応じて `XxxNotifier`、`XxxController` など責務を表す接尾辞を使用する。状態管理方式および接尾辞はプロジェクト全体で統一し、既存方式と異なる命名方式を同じ目的で混在させない。

データアクセスを抽象化するクラスは `XxxRepository` とする。

外部 API との直接的な通信を担当するクラスは `XxxApiClient` とする。

Data Source パターンを採用する場合は、対象に応じて `XxxRemoteDataSource`、`XxxLocalDataSource` とする。

UseCase パターンを採用する場合は `XxxUseCase` とする。採用していない場合は、形式を揃えるだけの目的で UseCase 層を追加しない。

API レスポンスや永続化専用のモデルなど、ドメインモデルと区別する必要があるデータモデルには `XxxDto` など役割が分かる名前を使用する。

## 略語と語彙

略語は `id`、`url`、`api` など一般的なものに限定し、独自の省略形を不用意に作らない。

同じ概念には同じ単語を使用する。同一概念に対して `user`、`account`、`member` など異なる名称を混在させない。

`data`、`info`、`item`、`value`、`manager`、`helper`、`util` など意味が広すぎる名前は、より具体的な名前にできる場合は避ける。不必要な略称や抽象的な名前も避ける。
