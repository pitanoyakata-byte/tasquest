import '../models/quest_instance.dart';
import '../models/user_profile.dart';

/// ユーザー状態の読み書きを行うリポジトリのインターフェース。
/// [uid] はFirebase AuthenticationのユーザーID（匿名認証を含む）。
/// テスト・オフライン時は[LocalUserRepository]、本番は[FirestoreUserRepository]を使う。
abstract class UserRepository {
  Future<UserProfile> load(String uid);
  Future<void> save(String uid, UserProfile profile);

  /// 完了済みクエストの履歴を新しい順に取得する（マイページ「振り返り」タブ用）。
  /// [since]を指定すると、それ以降に受注したものだけに絞る
  /// （企画書15章：無課金者は直近1週間分のみ閲覧可能）。
  Future<List<QuestInstance>> fetchQuestHistory(String uid, {DateTime? since});
}
