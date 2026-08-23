import 'package:flutter_riverpod/flutter_riverpod.dart';

/// サインイン済みユーザーのuidを解決するプロバイダー。
/// 実装は環境ごとに異なる（本番：Firebase匿名認証／テスト：固定値）ため、
/// デフォルトでは意図的に未実装として、必ずoverrideを要求する。
final authUidProvider = FutureProvider<String>((ref) {
  throw UnimplementedError(
    'authUidProvider must be overridden (see main.dart / test setup).',
  );
});
