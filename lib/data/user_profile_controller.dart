import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_uid_provider.dart';
import 'models/quest.dart';
import 'models/quest_genre.dart';
import 'models/quest_instance.dart';
import 'models/stat_progress.dart';
import 'models/user_profile.dart';
import 'repositories/local_user_repository.dart';
import 'repositories/user_repository.dart';

/// テスト等でoverrideしない限りローカル実装を使う。
/// 本番（main.dart）ではFirestoreUserRepositoryにoverrideする。
final userRepositoryProvider = Provider<UserRepository>((ref) => LocalUserRepository());

/// アプリ全体のユーザー状態を保持・更新するコントローラー。
/// 起動時に認証（authUidProvider）→リポジトリ読み込みの順で行い、
/// 以後の操作はここを経由して永続化する。
class UserProfileController extends AsyncNotifier<UserProfile> {
  UserRepository get _repository => ref.read(userRepositoryProvider);
  late String _uid;

  @override
  Future<UserProfile> build() async {
    _uid = await ref.watch(authUidProvider.future);
    return _repository.load(_uid);
  }

  Future<void> _update(UserProfile Function(UserProfile current) transform) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = transform(current);
    state = AsyncData(next);
    await _repository.save(_uid, next);
  }

  /// welcome画面を見た（クエストを受注した）ことを記録する。
  Future<void> markWelcomeSeen() => _update((p) => p.copyWith(hasSeenWelcome: true));

  /// クエストを受注する。画面仕様書2章のデータ書き込みに相当。
  Future<void> acceptQuest({
    required Quest quest,
    required int moodAtAccept,
    int? lockDurationSecondsOverride,
  }) {
    return _update((p) {
      final instance = QuestInstance(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        questId: quest.id,
        questNameTextId: quest.nameTextId,
        genre: quest.genre,
        acceptedAt: DateTime.now(),
        lockDurationSeconds:
            lockDurationSecondsOverride ?? quest.lockDurationMinutes * 60,
        moodAtAccept: moodAtAccept,
        isTutorial: quest.isTutorial,
        isQuickTier: quest.isQuickTier,
      );
      return p.copyWith(
        appState: AppRunState.questInProgress,
        activeQuestInstance: instance,
      );
    });
  }

  /// 達成報告を確定し、経験値を加算する。画面仕様書4章のデータ書き込みに相当。
  /// 経験値の加算自体は常に行い、表示用レベルのキャップは[StatProgress.displayLevel]側で行う（企画書5-6）。
  /// 戻り値は付与した経験値量とジャンル（報酬演出の表示に使う）。
  Future<(int rewardExp, QuestGenre genre)> completeActiveQuest({
    required int achievementScore,
    required bool doubleReward,
  }) async {
    final current = state.valueOrNull;
    final active = current?.activeQuestInstance;
    if (current == null || active == null) {
      return (0, QuestGenre.body);
    }

    final currentStat = current.stats[active.genre] ?? StatProgress.initial();
    final baseReward = active.isQuickTier
        ? StatProgress.quickTierQuestReward(currentStat.level)
        : StatProgress.normalQuestReward(currentStat.level);
    final reward = doubleReward ? baseReward * 2 : baseReward;
    final updatedStat = currentStat.addExp(reward);

    final newStats = Map<QuestGenre, StatProgress>.from(current.stats)
      ..[active.genre] = updatedStat;

    await _update((p) => p.copyWith(
          appState: AppRunState.normal,
          clearActiveQuestInstance: true,
          stats: newStats,
        ));

    return (reward, active.genre);
  }
}

final userProfileControllerProvider =
    AsyncNotifierProvider<UserProfileController, UserProfile>(UserProfileController.new);
