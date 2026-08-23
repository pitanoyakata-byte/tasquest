import '../models/user_profile.dart';

/// ユーザー状態の読み書きを行うリポジトリのインターフェース。
/// Phase1はローカル実装（[LocalUserRepository]）のみ。
/// Firebase導入時はこのインターフェースを実装するFirestore版に差し替える。
abstract class UserRepository {
  Future<UserProfile> load();
  Future<void> save(UserProfile profile);
}
