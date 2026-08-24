# タスクエスト（仮称） 画面仕様書

企画書（第13版以降の最新版）で確定した内容をもとに、Claude Codeでの実装に使うための詳細画面仕様。
企画書が「何を作るか」の合意文書なら、こちらは「どう実装するか」の作業指示書という位置づけ。
不明点や企画書との矛盾に気づいた場合は、実装前に必ず確認すること。

---

## 0. 全体構成

### 0-0. 基盤方針

- **認証**：Firebase Authenticationの匿名認証でアプリ利用を開始する。サインアップ画面は挟まない。課金やクラウドバックアップなど、匿名のままでは提供できない機能に触れた時点で、Apple／Googleアカウント等への紐付け（アカウントリンク）を促す。
- **課金基盤**：RevenueCatを使い、Apple（StoreKit）・Googleの両サブスクリプション基盤を統合管理する。RevenueCatのWebhookでFirestoreの`subscriptionStatus`を更新する構成とする。
- **多言語対応**：日本語・英語・韓国語・簡体字・ドイツ語・フランス語・イタリア語・スペイン語の8言語。UIテキストをIDで管理し、言語コードごとのJSONファイル（例：`ja.json`, `en.json`）で切り替える方式とする。
- **法務・プラットフォーム対応**：ストア審査・プライバシー規制への対応は「あれば良い」ではなく実装必須の項目として扱う。購入復元・解約管理導線、CMP（EU同意管理）、ATT（iOSトラッキング許諾）、プライバシーポリシー等。詳細は企画書20章、画面仕様は`consent`（12章）・`paywall`（11章）・`settings`（7章）を参照。

### 0-1. データモデル（Firestore想定・ドラフト）

実装時に調整してよい前提のドラフト。コレクション名・フィールド名は仮。

```
users/{uid}
  displayName: string
  locale: "ja" | "en" | "ko" | "zh-Hans" | "de" | "fr" | "it" | "es"
  authProvider: "anonymous" | "apple" | "google"  // アカウントリンク状況
  subscriptionStatus: "free" | "softTrial" | "paid"   // RevenueCat側は別途「trialing」も持ちうる。ここはアプリ内表示用の簡略ステータス
  nativeTrialOfferShownAt: timestamp | null   // ストア公式トライアルを提示したタイミング（オンボーディング直後）
  nativeTrialDeclinedAt: timestamp | null     // 提示に対し「今はやらない」を選んだタイミング。これが記録された場合のみソフトトライアルを開始する
  softTrialStartedAt: timestamp | null        // 独自14日間ソフトトライアルの開始時刻
  softTrialEndsAt: timestamp | null           // softTrialStartedAt + 14日
  stats:
    body:  { level: int, exp: int }   // 体力
    mind:  { level: int, exp: int }   // 知力
    life:  { level: int, exp: int }   // 生活力
  equipmentValue: { body: number, mind: number, life: number }
    // 5-3の「装備」枠。各ステータスの現在の最高上乗せ数値（絶対値、％ではない）。ドロップ時に現在値より高ければ更新（下がることはない、付け替え・売却なし）。5-4-2の表示ステータス計算式の「装備の数値」に使う
  townLevels: { body: int, mind: int, life: int }
    // 5-7の「町の成長（グレードアップ）」。体力＝ジム、知力＝研究施設、生活力＝自宅の各建物のタウンレベル（グレードアップボタンをタップした回数）。5の倍数のたびに見た目が変わる
  appState: "normal" | "questInProgress" | "bundleInProgress"
  activeQuestInstanceId: string | null
  activeBundleInstanceId: string | null
  dailyQuestCount: int                // 当日の受注済みクエスト数（無課金者の広告ゲート判定用。上限はなく、4件目以降は受注前に広告視聴が必須）
  dailyQuestCountDate: date           // ↑のカウントをリセットする基準日
  createdAt: timestamp

quests/{questId}                       // 運営提供クエストのマスタ
  name: string
  genre: "body" | "mind" | "life"
  durationMinutes: int                 // 10〜15
  cooldownMinutes: int                 // 60固定
  timeWindow: { startHour: int, endHour: int } | null  // 時間帯解放クエスト用。判定は端末のローカルタイムゾーン基準
  isQuickTier: boolean                 // クイック枠（企画書5-2-1）。早起きクエスト等、10〜15分の継続行動を伴わない報告型クエストはtrue。経験値・図鑑アイテムのドロップ率が通常より低くなる
  isUserCreated: false

users/{uid}/customQuests/{questId}      // ユーザー自作クエスト（課金限定）
  同上フィールド + isUserCreated: true

users/{uid}/questInstances/{instanceId} // 受注済み・進行中・完了したクエストの記録
  questId: string
  acceptedAt: timestamp
  lockDurationMinutes: int
  status: "locked" | "reportPending" | "completed"
  moodAtAccept: int (1〜5)
  achievementScore: int (0〜10) | null
  bundleInstanceId: string | null      // 大連続クエストの一部である場合のみ
  isTutorial: boolean
  rewardExp: int | null
  rewardEquipmentId: string | null

bundleSets/{setId}                      // プリセット（運営提供、全ユーザー共通）
  theme: string                         // 例:"朝のルーティーン"
  name: string
  candidateQuestIds: string[]           // 候補プール（約10件）

users/{uid}/myBundleSets/{setId}        // マイセット（ユーザーが保存した組み合わせ）
  theme: string
  name: string                          // 初期値はプリセット名、変更可
  selectedQuestIds: string[]            // 実際に選んだクエスト
  lastAcceptedAt: timestamp | null      // クールタイム（1時間）判定用

users/{uid}/bundleInstances/{instanceId}
  bundleSetId: string
  acceptedAt: timestamp
  moodAtAccept: int
  questInstanceIds: string[]
  endedAt: timestamp | null

artworks/{artworkId}                    // 図鑑アイテムのマスタ（Phase2・運営が用意する美術品カタログ）
  title: string                          // 作品名
  artist: string                         // 作者
  year: string                           // 制作年代（不明な場合は「◯世紀頃」等の文字列も許容）
  imageUrl: string                       // 使用画像。商用利用が明確に許可されたソースのみ（企画書5-4-1）
  valueAmount: int                       // コレクション価値（架空通貨「ドルドル」建て）。現実の市場価格は一切参照せず、この世界オリジナルの価値観として運営が独自に設定する（企画書5-4-1）
  statBoostPercent: { stat: "body"|"mind"|"life", percent: number }  // 図鑑コレクションのステータス補正％（5-4-1・5-4-2の美術品の補正に使用）。運営が独自に設定
  equipmentValue: number                 // 装備用の上乗せ数値（絶対値、5-3・5-4-2の「装備の数値」に使用）。statBoostPercentとは別軸で運営が独自に設定
  rarityStars: int (1〜5)                // valueAmountの高さに連動して設定する
  genre: "body" | "mind" | "life"        // ドロップの重み付け（5-3）に使うジャンル分類

users/{uid}/artworks/{artworkId}        // 図鑑（Phase2）。美術品ごとの入手記録（累計）
  count: int                             // 入手回数（重複含む）。5-4-2の美術品補正の指数として使う
  firstObtainedAt: timestamp
  lastObtainedAt: timestamp

users/{uid}/diaryEntries/{date}         // 日記（課金限定、ローカル保存＋課金者はクラウド同期）
  text: string
  photoUrl: string | null

users/{uid}/recordTemplates/{templateId} // 数値記録テンプレート（課金限定・自作クエストの一種、最大10個/ユーザー）
  title: string                          // A: 項目名
  unit: string                           // B: 単位
  displayType: "cumulative" | "trend"    // C: 積み上げ or 推移グラフ
  linkedStat: "body" | "mind" | "life"   // D: 経験値の紐付け先ステータス
  createdAt: timestamp
  lastRecordedDate: date | null          // クールダウンを持たない系統のため「1日1回」判定に使う（4-4のクールタイムの代わり）

users/{uid}/recordEntries/{entryId}     // 数値記録テンプレートの記録1件
  templateId: string
  recordedAt: timestamp
  moodAtStart: int (1〜5)
  value: number                          // 記録した数値（報酬計算には使わない。報酬は記録した行為そのものに対して発生）
  rewardExp: int                         // 固定報酬。templates.linkedStatのステータスに加算
```

### 0-2. アプリ状態モデル（起動時の分岐に使う）

`users/{uid}.appState` を起点に、起動時は必ずこの判定を行う。

| appState | 判定 | 遷移先 |
|---|---|---|
| `normal` | - | ホーム |
| `questInProgress` | `activeQuestInstanceId` のロック時間が未経過 | クエスト実行中画面（残り時間表示） |
| `questInProgress` | ロック時間が経過済み | 達成報告・報酬画面 |
| `bundleInProgress` | - | 大連続クエスト実行中画面（リスト。各クエストの状態は個別のタイムスタンプで判定） |

force-quit・バックグラウンドは通常のプロセス終了として扱い、特別なハンドリングは不要（企画書14-5-1）。

### 0-3. 画面一覧

| 画面ID | 画面名 | 課金/無課金 |
|---|---|---|
| `welcome` | オンボーディングWelcome | 共通 |
| `checkin` | 体調・モチベーションチェック | 共通（通常／チュートリアル／大連続の3モード） |
| `quest_active` | クエスト実行中 | 共通（通常／チュートリアル） |
| `reward` | 達成報告・報酬 | 共通（通常／チュートリアル／大連続） |
| `home` | ホーム | 共通 |
| `my_page` | マイページ | 共通（一部タブ内容が課金で変化） |
| `settings` | 設定 | 共通 |
| `bundle_list` | 大連続クエスト一覧 | 課金限定 |
| `bundle_select` | 大連続クエスト選択・編集 | 課金限定 |
| `bundle_active` | 大連続クエスト実行中 | 課金限定 |
| `paywall` | 課金画面 | 無課金・トライアル中ユーザー向け |
| `consent` | 同意管理（CMP・ATT） | 共通（初回起動時のみ。対象外条件のユーザーには表示されない） |

---

## 1. `welcome` — オンボーディングWelcome

**役割**：初回起動時のみ表示。チュートリアルクエストへの導線。

**表示要素**
| 要素 | 型 | 内容・由来 |
|---|---|---|
| マスコット挨拶メッセージ | Text | 固定文言（多言語対応） |
| チュートリアルクエスト説明 | Text | 「はじめの一歩」の説明、1〜2行 |
| 受注ボタン | Button | 「クエストを受注する」の1つのみ。他の導線は置かない |

**状態変数**：なし（初回起動判定はアプリ起動時のローカルフラグ or `users/{uid}` ドキュメントの存在有無で行う）

**遷移表**
| 操作 | 遷移先 |
|---|---|
| 受注ボタンタップ | `checkin`（mode=tutorial） |

---

## 2. `checkin` — 体調・モチベーションチェック

**役割**：クエスト受注直前のワンタッチ入力。4モード（`normal` / `tutorial` / `bundle` / `recordTemplate`）で表示内容の一部が変わる。

**表示要素**
| 要素 | 型 | 内容・由来 |
|---|---|---|
| 気分アイコン選択 | 5択のタップ選択（1〜5） | ユーザー入力 |
| マスコットの反応 | Text（アニメーション可） | 選んだ気分に応じて分岐。気分が低いほど否定せず優しく受け止める文言（企画書18章のセルフ・コンパッション根拠） |
| チュートリアルガイド文 | Text | `mode == tutorial` の場合のみ表示：「これは今の気分を教えるところだよ」 |
| 受注確定ボタン | Button | |

**状態変数**
- `mode: "normal" | "tutorial" | "bundle" | "recordTemplate"`（画面遷移時にパラメータで受け取る）
- `selectedMood: int`
- `targetQuestId`（normal/tutorial）、`targetBundleSetId`（bundle）、または `targetTemplateId`（recordTemplate）

**遷移表**
| 現在のmode | 操作 | 遷移先 |
|---|---|---|
| normal | 受注確定 | `quest_active`（mode=normal） |
| tutorial | 受注確定 | `quest_active`（mode=tutorial） |
| bundle | 受注確定 | `bundle_active` |
| recordTemplate | 受注確定 | `reward`（mode=recordTemplate）。ロック・待機時間がないため`quest_active`を経由しない |

**データ書き込み**
- normal/tutorial: `questInstances` に新規ドキュメント作成（`status: "locked"`, `moodAtAccept`, `acceptedAt: now`）。`users.appState = "questInProgress"`, `activeQuestInstanceId` を設定。`dailyQuestCount` を+1（無課金者の広告ゲート判定に使用。4件目以降は`home`側で受注前に広告視聴が必須）。
- bundle: `bundleInstances` 新規作成（`moodAtAccept`）。選択済み各クエストぶんの `questInstances` を一括作成し `bundleInstanceId` を付与。`users.appState = "bundleInProgress"`。
- recordTemplate: この時点ではまだ書き込まない（`reward`側で`recordEntries`を作成する）。

---

## 3. `quest_active` — クエスト実行中

**役割**：受注済みクエストのロックタイマー表示。normal / tutorial の2モード（大連続クエストは`bundle_active`が別途担当）。

**表示要素**
| 要素 | 型 | 内容・由来 |
|---|---|---|
| クエスト名 | Text | `quest.name` |
| 残り時間タイマー | Text（円形プログレス等） | `questInstance.acceptedAt + lockDurationMinutes - now` を毎秒更新 |
| ガイド文 | Text | mode=tutorialなら「アプリを閉じてもいいし、待っていてもいいよ」 |
| 広告視聴スキップ導線 | Button | `mode == normal` のみ表示（tutorialでは非表示） |

**状態変数**
- `mode: "normal" | "tutorial"`
- `questInstanceId`
- ローカルタイマー（表示更新用。ロック判定自体はサーバー時刻基準で行い、クライアントの時計に依存しない）

**遷移表**
| 操作・条件 | 遷移先 |
|---|---|
| タイマー終了（自動） | `reward`（同mode） |
| 広告視聴でスキップ（normalのみ） | `reward`（mode=normal） |
| アプリを閉じる／force-quit | 何もしない（次回起動時に0-2の判定に従う） |

**特記**：`lockDurationMinutes` は tutorial の場合ごく短時間（数秒〜十数秒程度）にマスターデータ側で設定する。

---

## 4. `reward` — 達成報告・報酬

**役割**：達成報告と報酬演出。normal / tutorial / bundle_end / recordTemplate の4モード。

**表示要素**
| 要素 | 型 | 内容・由来 |
|---|---|---|
| 「やった」ボタン | Button | タップで達成度入力欄が開く（recordTemplateでは数値入力欄が開く） |
| 気持ちアイコン | 5択 | normal/tutorialで表示。bundle_endでも表示（大連続クエスト全体に対して1回のみ、個々のクエストでは聞かない）。recordTemplateでも表示 |
| 達成度0〜10スライダー | Slider | normal/tutorial/bundle_endのみ。「記録のみ・報酬に影響しません」の注記を必ず表示 |
| 数値入力欄 | NumberField | recordTemplateのみ。`recordTemplate.unit` を単位として表示。ここに入力した値も報酬計算には一切使わない（記録した行為そのものに対して固定報酬が発生） |
| 報酬演出（釘落とし） | 物理演算アニメーション＋Text | 上から球を落とし、ランダム配置の釘に当たりながら落下する演出。何が当たるか（経験値量・装備・図鑑アイテム）は演出開始前にサーバー側で確定し、演出はその結果を可視化するだけ。「当たったように見えて実は外れ」という演出と結果の食い違いは絶対に作らない（企画書5-3-1）。recordTemplateは固定報酬のため釘落とし演出自体は行わず、簡易な「記録できたね」演出に留める |
| 広告視聴で2倍ボタン | Button | normalのみ表示。tutorial・bundle_end・recordTemplateでは非表示 |
| チュートリアル締めの説明文 | Text | mode=tutorialのみ：「これが基本の流れだよ。これから自分の生活の中でこれをやっていくよ」 |
| bundle完了一覧 | List | mode=bundle_endのみ：完了した各クエストの報酬一覧＋達成したクエスト数 |
| ホームに戻るボタン | Button | |

**状態変数**
- `mode: "normal" | "tutorial" | "bundle_end" | "recordTemplate"`
- `questInstanceId`（normal/tutorial）、`bundleInstanceId`（bundle_end）、または `targetTemplateId`（recordTemplate）
- `achievementScore: int`（normal/tutorial/bundle_end）
- `recordValue: number`（recordTemplateのみ）
- `moodAfter: int`

**遷移表**
| 操作 | 遷移先 |
|---|---|
| ホームに戻るタップ（mode=normal/bundle_end/recordTemplate） | `home` |
| ホームに戻るタップ（mode=tutorial、初回のみ） | `consent`（未表示の場合のみ）→ `paywall`（source=onboarding）→ `home` |

**データ書き込み**：`questInstance.status = "completed"`, `achievementScore` 保存、経験値を確定して `users.stats` を更新。`users.appState = "normal"`, `activeQuestInstanceId = null`。
recordTemplateの場合：`recordEntries` に新規ドキュメント作成（`templateId`, `recordedAt: now`, `moodAtStart`, `value: recordValue`, `rewardExp`）。`recordTemplate.lastRecordedDate` を当日日付に更新。`users.stats[recordTemplate.linkedStat]` に `rewardExp` を加算。

**美術品ドロップ時の書き込み（企画書5-3・5-4）**：装備・図鑑アイテムが当選した場合、(1) `users/{uid}/artworks/{artworkId}` を作成またはインクリメント（`count`を+1、`lastObtainedAt: now`）。(2) 当選した`artworks.equipmentValue`が、対応するステータスの`users.equipmentValue[stat]`より高ければ更新（下がることはない）。この2つは常にセットで実行し、装備枠が更新されるかどうかに関わらず図鑑への記録は必ず行う。

**無課金レベルキャップの適用点（企画書5-6）**：経験値の加算自体は常に行う。表示用の `level` を計算する関数は、無課金ユーザーの場合はレベル50を上限にクランプして返す（生の経験値は保持し続ける）。

**経験値カーブ（企画書5-2）**：`必要経験値(L) = 50 × 1.122^(L-1)`、`1回のクエストで得られる経験値(L) = 必要経験値(L) / 2`。Lはそのクエストのジャンルに対応するステータスの現在レベル。

**クイック枠クエストの報酬（企画書5-2-1）**：10〜15分の継続行動を伴わず報告のみで完了するクエスト（`quest.isQuickTier == true`。数値記録テンプレート・早起きクエストが該当）は、経験値を通常の半分（`必要経験値(L) / 4`）とする。recordTemplateの固定報酬もこの式に基づき、`recordTemplate.linkedStat` の現在レベルから算出する。釘落とし演出（企画書5-3-1）における装備・図鑑アイテムの当選領域も、クイック枠は通常クエストより狭く設定する。

**数値記録テンプレートの日次制限（企画書4-6）**：`recordTemplate.lastRecordedDate` が当日と一致する場合、マイページの数値記録タブでそのテンプレートをタップ不可にする（クールダウンを持たない系統のクエストは1日1回までという共通原則）。

**表示ステータス値の計算式（企画書5-4-2）**：マイページ等に表示する体力・知力・生活力は、`users.equipmentValue[stat] × タウンの補正 × レベルの補正 × 美術品の補正` で算出する。

- 装備の数値：`users.equipmentValue[stat]`（絶対値）をそのまま使う。
- タウンの補正：対応する建物の`users.townLevels[stat]`をTとして、1〜Tの各タウンレベルのうち5の倍数は1.10、それ以外は1.02を該当回数だけ累乗しすべて掛け合わせる。T=0（未グレードアップ）の場合は1（補正なし）。
- レベルの補正：`(1.01) ^ L`。**Lは表示用レベル（無課金者はレベルキャップでクランプされた値、課金者は本来のレベル）を使う**。無課金者がキャップ到達後も裏側では経験値・本来のレベルは計算され続けるが、表示ステータス値の計算にはキャップ後の表示レベルを使い、課金した瞬間に本来のレベルへ計算が切り替わる（開発者確認済み、2026-08-24）。
- 美術品の補正：`users/{uid}/artworks/*` の各ドキュメントについて `(1 + artworks[artworkId].statBoostPercent) ^ count` を計算し、対応するステータスに属するものすべてを掛け合わせる。
- 計算例：体力レベル56・`equipmentValue.body`=1000・`townLevels.body`=11・美術品（1%×4個、5%×4個）の場合、レベル補正1.01^56≈1.746、タウン補正（1〜11のうち5の倍数は5・10の2回）1.10^2×1.02^9≈1.446、美術品補正1.01^4×1.05^4≈1.265。表示ステータス＝1000×1.446×1.746×1.265≈約3193。
- 用途の限定：この表示ステータス値はクエストの受注条件・報酬など通常のゲームプレイ判定には一切使わない（企画書5-5）。唯一の例外はPhase2のレイドボスでのダメージ貢献量算出（詳細は実装時に判断）。

---

## 5. `home` — ホーム

**役割**：メインハブ。

**表示要素**
| 要素 | 型 | 内容・由来 |
|---|---|---|
| マスコット挨拶・状態表示 | Text/Image | |
| 背景シーン（町の成長） | Image | 3ステータスに対応する3つの建物（体力＝ジム、知力＝研究施設、生活力＝自宅）を配置。それぞれ`users.townLevels[stat]`が5の倍数の時のみ見た目が切り替わる（企画書5-7・12章） |
| 「グレードアップ」ボタン（体力・知力・生活力ぶん、最大3個） | Button | 通常は非表示。対応するステータスの`users.stats[stat].level`が5の倍数に達した時のみ、その建物のボタンが出現する。タップで`users.townLevels[stat]`を+1し、対応する建物のみ次段階へ進化、その建物のマスコットが特別な反応をする |
| おすすめクエスト一覧 | List | 行動履歴に基づくパーソナライズ（課金無課金共通・企画書14-4／17章MVP項目）。時間帯解放クエストがあれば優先表示 |
| ボディ・ダブリングの気配表示 | Text | 「今、同じくらいの時間に◯人がこのクエストに挑戦中」（企画書6-1。Checkin画面側に出す設計だったが、ホームで先出しする案も実装時に検討可） |
| 前日実績バッジ | Text | 「昨日◯人が挑戦」 |
| 下部タブ | TabBar | ホーム／マイページ／設定（＋課金者は大連続クエストへの導線） |
| 起動5分以内ボーナスの表示 | Badge等 | 起動時刻を記録し、5分以内の受注で軽い後押し演出 |

**遷移表**
| 操作 | 遷移先 |
|---|---|
| クエストをタップ | 無課金者かつ `dailyQuestCount >= 3` の場合、遷移前に広告視聴を挟む（視聴完了で`checkin`へ、途中離脱ならホームに留まる）。それ以外は `checkin`（mode=normal） |
| いずれかの「グレードアップ」ボタンをタップ | 画面遷移なし。その場で該当する建物のみ見た目を更新（タウンレベルが5の倍数の時のみ）し、そのステータスの表示ステータス値にタウン補正を反映、対応するマスコットが特別演出を行う |
| 「大連続クエスト」タップ（課金者のみ表示） | `bundle_list` |
| 無課金者が大連続クエストの案内をタップ | `paywall` |
| 下部タブ：マイページ | `my_page` |
| 下部タブ：設定 | `settings` |

---

## 6. `my_page` — マイページ

**役割**：振り返り・成長確認。タブ切り替え式。

**表示要素（共通）**
| タブ | 内容 |
|---|---|
| ステータス | 体力・知力・生活力の表示ステータス値（企画書5-4-2、装備×タウン×レベル×美術品の掛け算）とレベルバー、合計レベル（企画書5-5）。無課金はキャップ上限で表示が止まる |
| 振り返り | 直近の実績サマリー。無課金は直近1週間分のみ、課金は週次サマリー（企画書16-6）＋全履歴 |
| 図鑑（Phase2） | 装備（パブリックドメインの美術品、企画書5-4-1）の収集状況。各アイテムに作品名・作者・コレクション価値（架空通貨「ドルドル」）を表示。収集済みアイテムの価値を合計した「コレクション総評価額」をタブ上部に表示する。無課金はレベルキャップ帯までのみ解放（総評価額も解放済み分のみ集計） |
| 数値記録（課金限定・Phase2） | `recordTemplates`一覧（最大10個）と、テンプレートごとの積み上げ数／推移グラフ。無課金者はタブごと非表示（一覧に出さず`paywall`へ誘導するCTAのみ表示）。推移グラフは望まない人の目に自然と入らないよう、このタブの中でもテンプレートを選んで開いた先に置く（一覧に常時表示しない）。テンプレート新規作成もここから行う（項目名A・単位B・表示形式C・紐付けステータスDを入力） |

**遷移表**：下部タブから `home` `settings` へ。無課金ユーザーが「全履歴を見る」等の課金限定表示をタップした場合は `paywall` へ。数値記録タブでテンプレートをタップすると、そのテンプレートの記録フロー（`checkin`→`reward`と同一コンポーネントを再利用、mode=recordTemplate）に遷移する。当日すでに記録済みのテンプレートは「本日は記録済み」と表示しタップ不可にする。

---

## 7. `settings` — 設定

**表示要素**：BGM/効果音音量、言語切替、通知設定、サブスクリプション管理、アカウント・データ管理、プライバシーポリシー・利用規約へのリンク、広告の同意設定を変更する導線（CMP再表示、企画書20-3）。

**サブスクリプション管理の詳細（企画書20-1）**：無課金・トライアル中ユーザーがタップした場合は`paywall`へ。課金中ユーザーがタップした場合は、OSネイティブのサブスクリプション管理画面（iOS: `https://apps.apple.com/account/subscriptions` へのディープリンク、Android: Google Play の定期購入管理画面へのディープリンク）を開く。アプリ内に独自の解約フローは作らない。

---

## 8. `bundle_list` — 大連続クエスト一覧（課金限定）

**役割**：プリセット／マイセットのカード一覧。

**表示要素**
| 要素 | 型 | 内容 |
|---|---|---|
| マイセットカード一覧 | List | `myBundleSets` を表示。クールタイム中のものは受注不可の表示 |
| プリセット／テーマ一覧 | List | `bundleSets`（未カスタマイズのテーマ） |
| 「新しく作る」導線 | Button | |

**遷移表**
| 操作 | 遷移先 |
|---|---|
| 既存マイセット／プリセットのカードをタップ | `bundle_select`（現在の組み合わせがチェック済みの状態） |
| 「新しく作る」でテーマを選ぶ | `bundle_select`（候補未選択の状態） |

---

## 9. `bundle_select` — 大連続クエスト選択・編集（課金限定）

**表示要素**
| 要素 | 型 | 内容 |
|---|---|---|
| 候補クエスト一覧 | Checkbox List | テーマの `candidateQuestIds` ＋ユーザーの自作クエスト |
| セット名入力欄 | TextField | 初期値はプリセット名／既存マイセット名 |
| 自作クエスト追加導線 | Button | 4-2の自作クエスト作成フローへ |
| 受注するボタン | Button | |

**遷移表**
| 操作 | 遷移先 |
|---|---|
| 「受注する」タップ | `checkin`（mode=bundle）。この時点で選択内容を `myBundleSets` に自動登録（新規 or 上書き） |

---

## 10. `bundle_active` — 大連続クエスト実行中（課金限定）

**表示要素**
| 要素 | 型 | 内容 |
|---|---|---|
| クエストリスト | List | 各行が `未着手 / ロック中 / 完了報告待ち / 完了済み` のいずれかの状態を表示 |
| 「大連続クエストを終える」ボタン | Button | 下部固定 |

**遷移表**
| 操作 | 遷移先 |
|---|---|
| 完了報告待ちの行をタップ | その場で達成度0〜10の入力UIを開く（画面遷移なし、その場で報酬確定してリスト更新） |
| 「大連続クエストを終える」タップ | `reward`（mode=bundle_end） |

---

## 11. `paywall` — 課金画面

**役割**：トライアル・サブスクリプションへの導線。企画書16章の方針に基づく、ストア公式トライアルを主導線としつつ、断った場合のみ独自ソフトトライアルへ切り替える2段構え。

**表示要素**
| 要素 | 型 | 内容 |
|---|---|---|
| ビジョン訴求メッセージ | Text | オンボーディングで把握した目的やトライアル中の実績を反映（可能な範囲で動的差し込み） |
| プラン選択 | 2択カード | 年額（デフォルト選択、「2ヶ月分お得」バッジ）／月額。いずれもストア公式の無料トライアル付きサブスクリプションとしてRevenueCat経由で購入フローを起動する |
| 「今はやらない」導線 | Button/Link | 強制せず、いつでも閉じられる。オンボーディング直後の初回表示でこれが選ばれた場合のみ、`nativeTrialDeclinedAt` を記録し、独自ソフトトライアル（`softTrialStartedAt`）を開始する |
| 機能比較 | List/Table | 企画書15章の無課金・課金差分を要約表示 |
| 価格・期間・自動更新の明記 | Text | 「年額◯◯円／自動更新、いつでも解約可」等をプラン選択カードの近くに常時表示（企画書20-1、Apple Guideline 3.1.2対応） |
| 「購入を復元」ボタン | Button | 画面下部に常時表示。RevenueCatの`restorePurchases`を呼び出す（企画書20-1） |

**呼び出し元・source別の挙動（企画書16-4）**
| source | 呼び出しタイミング | 「今はやらない」を選んだ時の挙動 |
|---|---|---|
| `onboarding` | オンボーディングのチュートリアル直後（初回のみ） | ソフトトライアルを開始し `home` へ |
| `soft_trial_day7` / `day10` / `day13` | ソフトトライアル中の該当日 | 単に画面を閉じてソフトトライアルを継続 |
| `soft_trial_day14` | ソフトトライアル終了直前 | 画面を閉じてソフトトライアル終了、無課金状態に戻る |
| `feature_gate` | ソフトトライアル終了後、課金限定機能にアクセスした瞬間 | 画面を閉じて元の画面に戻る（機能は使えないまま） |

---

## 12. `consent` — 同意管理（CMP・ATT）

**役割**：広告表示・IDFA取得前に必要な同意取得（企画書20-3）。オンボーディングのチュートリアル完了直後、`paywall`（source=onboarding）より前に一度だけ挟む。

**表示要素**
| 要素 | 型 | 内容 |
|---|---|---|
| CMPダイアログ | Google認定UMP SDK | EU/EEA/UKと判定されたユーザーにのみ表示。広告のパーソナライズ可否の同意を取得する |
| ATTダイアログ | iOS標準ダイアログ | iOSユーザーにのみ表示。IDFA取得・トラッキング許諾を確認する |

**状態変数**：なし（各SDKが対象判定・表示を行う。アプリ側は表示完了を待つだけでよい）

**遷移表**
| 操作・条件 | 遷移先 |
|---|---|
| 対象外ユーザー（該当地域外・Android等でATT不要） | 画面を表示せず即座に次へ |
| 各ダイアログへの回答完了（許可・拒否いずれの場合も） | `paywall`（source=onboarding） |

**データ書き込み**：なし。同意状態はCMP SDK・OS側が管理し、Firestoreへの保存は不要。

---

## 13. 未確定・実装時に詰める必要がある点

- 装備ドロップ確率の実際の乱数テーブル化（5-3のジャンル重み50/25/25を、釘落とし演出の当選領域の配置に落とし込む）
- 図鑑アイテム（`artworks`）の実際の作品選定・画像ソースの利用条件確認・コレクション価値テーブルの作成（企画書5-4-1）
- 通知・広告SDKの詳細選定（Firebase Cloud Messaging・AdMobの具体的な設定。課金基盤はRevenueCatに決定済み）
- ソフトトライアル終了後に再度ストア公式トライアルを提示してよいか（ストア規約上の可否を含む）の運用判断
- アプリ名の商標・重複確認
- Apple Featuring Nominationsの申請スケジュール管理（企画書11-2、新規リリース時は最低2週間前・推奨3ヶ月前）
- ASOのキーワード・スクリーンショット文言の最終確定（企画書11-3）
- Firebase・RevenueCat・AdMobが扱うデータの棚卸しと、Apple/Googleのプライバシー申告文の作成（企画書20-3）
- プライバシーポリシー・利用規約ページの作成・公開（企画書20-3）
- Google Play Console／App Store Connectでの対象オーディエンス（年齢層）申告の実施（企画書20-4）
- プロモーション動画（企画書11-4）の実制作
- 無課金者の広告ゲート（4件目以降のクエスト受注前の広告視聴）に使うAdMob広告フォーマットの選定（リワード広告かインタースティシャルか）
