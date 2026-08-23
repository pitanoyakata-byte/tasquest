# PROGRESS.md — タスクエスト（仮称）開発記録

CLAUDE.mdの規約に基づき、作業のたびにここへ日時・やったこと・次にやることを追記する。

---

## 2026-08-23（初回セッション）

### やったこと

- 企画書v15・CLAUDE.md・screens.mdを読み込み、要件を確認。
- 開発コンテナにFlutter SDK（stable channel）を導入（`/tmp/flutter_sdk`。ユーザーの手元PCには別途導入が必要、後述）。
- `flutter create` でプロジェクト雛形を作成（Android/iOS/Web対応）。
- 技術選定（CLAUDE.md「未決定の技術選定」に対する回答）：
  - 状態管理：**Riverpod**（`flutter_riverpod`）。コード生成なしのシンプルな`AsyncNotifier`構成。
  - 画面遷移：**go_router**。
  - ローカル永続化（Firebase導入までの仮の保存先）：`shared_preferences`。将来Firestoreに差し替える前提で`UserRepository`インターフェースを挟んである。
  - ディレクトリ構成：機能別（`lib/features/{onboarding,checkin,quest_active,reward,home}`）＋共通基盤（`lib/core`）＋データ層（`lib/data`）。
- i18nテキストID基盤を実装（`lib/core/i18n/`）。`assets/i18n/{ja,en,ko,zh-Hans,de,fr,it,es}.json` を8言語分すべて作成し、テキストIDで文言を引く`tt(ref, id)`ヘルパーを用意。今回追加した約34個のテキストIDはすべて8言語分そろえた。
- コアゲームループ（画面仕様書1〜5章のうち、mode=normal/tutorialの範囲）を実装：
  - `welcome`（オンボーディング）
  - `checkin`（気分5択・チュートリアルガイド文）
  - `quest_active`（ロックタイマー、1秒更新、経過で自動遷移）
  - `reward`（やったボタン→気分→達成度0〜10→報酬確定→結果表示。**報酬は演出より先にサーバー側相当のロジックで確定**してから表示する設計にしてあり、企画書5-3-1の「演出と結果の食い違いを作らない」原則を満たす）
  - `home`（ステータス3種の表示、おすすめクエスト一覧＝固定のサンプル3件）
- 起動時の画面分岐（画面仕様書0-2）を`GoRouter`のスプラッシュ画面で実装。`hasSeenWelcome` / `appState` / ロック経過判定で自動的に正しい画面へ振り分ける。
- 経験値カーブ（企画書5-2：必要経験値(L) = 50 × 1.122^(L-1)、1回の報酬 = 必要経験値/2、クイック枠は/4）と無課金レベルキャップ（Lv50、経験値自体は常に加算し表示のみクランプ）を実装。
- `flutter analyze` → 0件、`flutter test`（Welcome→Checkin遷移のスモークテスト）→ 全パス。

### 意図的にPhase1のスコープ外にしたもの（あとで実装する）

- **Firebase／Firestore／Firebase Authentication**：Firebaseプロジェクト未作成のため。現在はSharedPreferencesのローカル保存のみ。`UserRepository`インターフェースを挟んであるので、Firestore版の実装を追加してDIを差し替えるだけで移行できる想定。
- **RevenueCat課金・広告（AdMob）**：「広告を見てスキップ」「広告を見て報酬2倍」ボタンは、実際にSDKが繋がっていない状態で偽の演出を出すと企画書の「誠実性」原則に反するため、Phase1では表示していない。SDK導入時に追加する。
- **報酬演出（釘落とし）**：物理演算演出は未実装。現在は結果を即座にテキスト表示するのみ（結果を先に確定してから見せる、という誠実性の原則自体は満たした簡易版）。
- **大連続クエスト・数値記録テンプレート・図鑑・称号・マイページ・設定画面・consent（CMP/ATT）・paywall**：画面仕様書6章以降は未着手。
- **クエストのクールタイム（1時間）判定**：Phase1のサンプルクエストには未実装。

### 次にやること（次回セッションの入り口）

1. Firebaseプロジェクトを作成し（ユーザー側の作業。手順は下記「あなたにお願いしたいこと」参照）、`firebase_core`・`cloud_firestore`・`firebase_auth`を導入。`LocalUserRepository`と同じインターフェースを実装する`FirestoreUserRepository`を追加し、匿名認証でサインインする処理を足す。
2. マイページ（ステータスタブ）・設定タブの雛形を追加し、下部タブバーで3画面を行き来できるようにする。
3. クエストのクールタイム判定・広告ゲート（4件目以降）など、ホーム画面の未実装ロジックを足していく。

### あなたにお願いしたいこと（Firebase関連・初心者向け手順）

1. https://console.firebase.google.com/ にアクセスし、Googleアカウントでログイン。
2. 「プロジェクトを追加」から新規プロジェクトを作成（プロジェクト名は仮で「tasquest」等でOK、後から変更可）。
3. 作成したプロジェクトで以下を有効化：
   - Authentication → 「始める」→ Sign-in method タブで「匿名」を有効化
   - Firestore Database → 「データベースの作成」→ 本番環境モード（あとでセキュリティルールは詰める）
4. プロジェクトが作成できたら、そのプロジェクトIDを教えてください。次のセッションでFlutterアプリ側にFirebase連携（`flutterfire configure`相当の設定ファイル生成）を進めます。

---
