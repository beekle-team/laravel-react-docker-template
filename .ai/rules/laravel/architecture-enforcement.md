# 責務とクエリスコープの実装ルール

## エージェントの作業手順

1. 編集前に処理の所有者を決める。HTTPはController/Form Request、DBの状態遷移はEloquent、通信はGateway、複数Modelの調整は用途を限定したSupport。
2. 既存の業務メソッド・リレーション・ローカルスコープを検索して再利用する。
3. Controllerから生の更新・トランザクション・ロック・SDK呼び出しを行わない。違反は責務の所有者へ移す。クラス名を変えるだけでSupportへ押し込まない。
4. 単一Modelの状態遷移は意味のあるメソッドにし、前提条件と必要なDBロックをその中で守る。Form Requestの入力検証だけで不変条件を保証しない。
5. 複数ModelとGatewayを連携するSupportは手順に限定し、通信仕様はGateway、永続化の整合性はModelに残す。DBトランザクション中の外部通信を避け、冪等性・結果不明・再試行を設計する。
6. PHPStanとルールの回帰テストを実行する。失敗を通すためにignore・baseline・型のmixed化を追加しない。

## 境界

| 場所 | 担当 | 持ち込まないもの |
|---|---|---|
| Controller | 認可、検証済み入力の受け渡し、レスポンス | 生のDB更新、トランザクション、ロック、SDK、業務状態遷移 |
| Form Request | 入力の形式・値検証、入力に対する認可 | DB更新、外部通信 |
| Eloquent | 状態遷移、不変条件、リレーション、casts、scopes | HTTP Request/Response、Gateway・SDKの直接呼び出し |
| Gateway | 通信、provider payload、応答・例外変換 | 業務DBの更新 |
| Support | 明確な目的を持つ横断手順・出力組み立て | 単一Modelで完結する業務ロジック、汎用Service化 |

Controllerで単純な読み取りやページングを行うことは禁止しない。入力・出力のDTOは既存の型生成ルールに従う。認可の判断はPolicyに集約する。

## ローカルスコープ

- 業務上の意味がある条件や繰り返す条件はローカルスコープを優先する。単発の単純なwhereまで必ず包む必要はない。
- 名前は pending / active / forResearcher / visibleTo のように意味を示す。
- 条件構築だけを行う。get / first / paginate / count等の実行、更新、外部通信を含めない。
- request() / auth() やRequest/Auth facadeに暗黙依存しない。利用者・日時・IDは引数で渡す。
- 同じBuilderを返すかvoidとし、他のスコープと組み合わせられるようにする。
- OR条件はクロージャで括り、所有者条件・権限条件を迂回しないようにする。
- 閲覧範囲のvisibleTo等はPolicyによる操作権限チェックの代替にしない。
- Global Scopeは全取得経路に適用すべき条件に限定する。画面固有の絞り込みに使わない。
- 新規コードは #[Scope] を優先する。既存のscopeXxx形式も検査対象とし、構文の移行だけを目的に広範囲を変更しない。

例: BillingPaymentSetup::query()->forResearcher($researcher)->pending()->latest('id')->first()

## 自動検査と限界

PHPStanのLayerBoundaryRuleは呼び出し先の型を使い、Controller/Form Request/Gatewayの直接更新、ControllerのDB・ロック操作、ModelのHTTP・外部通信を検出する。QueryScopeRuleは #[Scope] とscopeXxxの両方で、ORMの実行・更新とHTTPコンテキスト依存を検出する。同名のCollection::get()や業務オブジェクトのsave()は一律に禁止しない。

標準のcomposer lintとCIのPHPStanで実行する。ルール自体の検証は php artisan test tests/Unit/PHPStan/Rules 。

動的なメソッド名、未列挙のSDK、間接的な副作用、プロパティへの直接代入、業務上の意味は完全には判定できない。PHPStan通過を「責務違反なし」の証明にせずレビューする。Rectorは構文の自動整備を担い、業務ロジックの自動移動には使わない。

導入時点の既存違反はphpstan-architecture-baseline.neonに識別子・メッセージ・ファイル・件数を限定して記録する。既存違反の一括解消は別途行い、新しい違反は増やさない。CIは比較元よりbaselineの項目・件数が増えていないことも検査する。同じファイル・同じメッセージの違反を削除と同時に追加した場合までは識別できないため、変更箇所はレビューする。
