import '../models/user_profile.dart';

/// ユーザー状態の読み書きを行うリポジトリのインターフェース。
/// [uid] はFirebase AuthenticationのユーザーID（匿名認証を含む）。
/// テスト・オフライン時は[LocalUserRepository]、本番は[FirestoreUserRepository]を使う。
abstract class UserRepository {
  Future<UserProfile> load(String uid);
  Future<void> save(String uid, UserProfile profile);
}
