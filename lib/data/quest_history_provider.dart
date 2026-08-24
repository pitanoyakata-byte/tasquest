import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_uid_provider.dart';
import 'models/quest_instance.dart';
import 'user_profile_controller.dart';

/// マイページ「振り返り」タブ用：完了済みクエストの履歴。
/// 無課金者は直近1週間分のみに絞る（企画書15章）。
final questHistoryProvider = FutureProvider.autoDispose<List<QuestInstance>>((ref) async {
  final uid = await ref.watch(authUidProvider.future);
  final profile = await ref.watch(userProfileControllerProvider.future);
  final since = profile.isPaidUser ? null : DateTime.now().subtract(const Duration(days: 7));
  return ref.read(userRepositoryProvider).fetchQuestHistory(uid, since: since);
});
