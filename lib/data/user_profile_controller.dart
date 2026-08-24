import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_uid_provider.dart';
import 'models/quest.dart';
import 'models/quest_genre.dart';
import 'models/quest_instance.dart';
import 'models/quest_reward_result.dart';
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
  final _random = Random();

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
  ///
  /// 装備ドロップ（企画書5-3）はダミー実装：釘落とし演出はPhase6で本実装予定のため、
  /// ここでは確率・上乗せ数値ともに仮の値を使い、報酬が手に入ること自体だけを再現する。
  /// 開発者確認済み（2026-08-24）：確率・数値テーブルは企画側で確定次第、差し替える。
  Future<QuestRewardResult> completeActiveQuest({
    required int achievementScore,
    required bool doubleReward,
  }) async {
    final current = state.valueOrNull;
    final active = current?.activeQuestInstance;
    if (current == null || active == null) {
      return const QuestRewardResult(expGained: 0, genre: QuestGenre.body);
    }

    final currentStat = current.stats[active.genre] ?? StatProgress.initial();
    final baseReward = active.isQuickTier
        ? StatProgress.quickTierQuestReward(currentStat.level)
        : StatProgress.normalQuestReward(currentStat.level);
    final reward = doubleReward ? baseReward * 2 : baseReward;
    final updatedStat = currentStat.addExp(reward);

    final newStats = Map<QuestGenre, StatProgress>.from(current.stats)
      ..[active.genre] = updatedStat;

    final drop = _rollDummyEquipmentDrop(
      questGenre: active.genre,
      isQuickTier: active.isQuickTier,
      rewardExp: reward,
      currentEquipmentValue: current.equipmentValue,
    );

    final newEquipmentValue = drop == null
        ? current.equipmentValue
        : (Map<QuestGenre, double>.from(current.equipmentValue)
          ..[drop.genre] = drop.value);

    await _update((p) => p.copyWith(
          appState: AppRunState.normal,
          clearActiveQuestInstance: true,
          stats: newStats,
          equipmentValue: newEquipmentValue,
        ));

    return QuestRewardResult(
      expGained: reward,
      genre: active.genre,
      equipmentGenre: drop?.genre,
      equipmentValue: drop?.value,
    );
  }

  /// 装備ドロップのダミー判定。仮の確率・数値テーブル（要調整、上記メソッドコメント参照）。
  ({QuestGenre genre, double value})? _rollDummyEquipmentDrop({
    required QuestGenre questGenre,
    required bool isQuickTier,
    required int rewardExp,
    required Map<QuestGenre, double> currentEquipmentValue,
  }) {
    const normalDropChance = 0.3; // 仮の数値
    const quickTierDropChance = 0.15; // 仮の数値（クイック枠は狭める、企画書5-2-1）
    final dropChance = isQuickTier ? quickTierDropChance : normalDropChance;
    if (_random.nextDouble() >= dropChance) return null;

    // ジャンル重み50/25/25（企画書5-3）
    final otherGenres = QuestGenre.values.where((g) => g != questGenre).toList();
    final genreRoll = _random.nextDouble();
    final targetGenre = genreRoll < 0.5
        ? questGenre
        : (genreRoll < 0.75 ? otherGenres[0] : otherGenres[1]);

    // 仮の上乗せ数値：報酬経験値の2〜7倍程度のランダム値（要調整）
    final droppedValue = (rewardExp * (2 + _random.nextInt(6))).toDouble();
    final current = currentEquipmentValue[targetGenre] ?? 0;
    if (droppedValue <= current) return null;

    return (genre: targetGenre, value: droppedValue);
  }

  /// 町のグレードアップ（企画書5-7）。対応するステータスのレベルが5の倍数に
  /// 達しているのにまだタウンレベルが追いついていない場合のみ実行される。
  Future<void> gradeUpTown(QuestGenre genre) {
    return _update((p) {
      final stat = p.stats[genre] ?? StatProgress.initial();
      final displayLevel = stat.displayLevel(isPaidUser: p.isPaidUser);
      final currentTownLevel = p.townLevels[genre] ?? 0;
      if (displayLevel ~/ 5 <= currentTownLevel) {
        return p; // グレードアップ不可（対象外タップ）
      }
      final newTownLevels = Map<QuestGenre, int>.from(p.townLevels)
        ..[genre] = currentTownLevel + 1;
      return p.copyWith(townLevels: newTownLevels);
    });
  }
}

final userProfileControllerProvider =
    AsyncNotifierProvider<UserProfileController, UserProfile>(UserProfileController.new);
