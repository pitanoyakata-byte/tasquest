import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/quest.dart';
import '../models/quest_genre.dart';
import '../models/quest_instance.dart';
import '../models/stat_progress.dart';
import '../models/user_profile.dart';
import 'user_repository.dart';

/// SharedPreferencesにJSON形式で保存するローカル実装。
/// Firebase未導入のPhase1における仮の永続化先。
class LocalUserRepository implements UserRepository {
  static const _storageKey = 'user_profile_v1';

  @override
  Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      return UserProfile.initial();
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _fromJson(json);
  }

  @override
  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_toJson(profile)));
  }

  Map<String, dynamic> _toJson(UserProfile profile) {
    final active = profile.activeQuestInstance;
    return {
      'hasSeenWelcome': profile.hasSeenWelcome,
      'appState': profile.appState.name,
      'isPaidUser': profile.isPaidUser,
      'stats': profile.stats.map((genre, stat) => MapEntry(genre.name, stat.toJson())),
      'activeQuestInstance': active == null
          ? null
          : {
              'id': active.id,
              'questId': active.questId,
              'questNameTextId': active.questNameTextId,
              'genre': active.genre.name,
              'acceptedAt': active.acceptedAt.toIso8601String(),
              'lockDurationSeconds': active.lockDurationSeconds,
              'moodAtAccept': active.moodAtAccept,
              'isTutorial': active.isTutorial,
              'isQuickTier': active.isQuickTier,
              'achievementScore': active.achievementScore,
              'completed': active.completed,
              'rewardExp': active.rewardExp,
            },
    };
  }

  UserProfile _fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>? ?? {};
    final stats = <QuestGenre, StatProgress>{
      for (final genre in QuestGenre.values)
        genre: statsJson.containsKey(genre.name)
            ? StatProgress.fromJson(statsJson[genre.name] as Map<String, dynamic>)
            : StatProgress.initial(),
    };

    final activeJson = json['activeQuestInstance'] as Map<String, dynamic>?;
    final activeQuestInstance = activeJson == null
        ? null
        : QuestInstance(
            id: activeJson['id'] as String,
            questId: activeJson['questId'] as String,
            questNameTextId: activeJson['questNameTextId'] as String,
            genre: QuestGenre.values.byName(activeJson['genre'] as String),
            acceptedAt: DateTime.parse(activeJson['acceptedAt'] as String),
            lockDurationSeconds: activeJson['lockDurationSeconds'] as int,
            moodAtAccept: activeJson['moodAtAccept'] as int,
            isTutorial: activeJson['isTutorial'] as bool,
            isQuickTier: activeJson['isQuickTier'] as bool,
            achievementScore: activeJson['achievementScore'] as int?,
            completed: activeJson['completed'] as bool? ?? false,
            rewardExp: activeJson['rewardExp'] as int?,
          );

    return UserProfile(
      hasSeenWelcome: json['hasSeenWelcome'] as bool? ?? false,
      appState: AppRunState.values.byName(json['appState'] as String? ?? 'normal'),
      stats: stats,
      activeQuestInstance: activeQuestInstance,
      isPaidUser: json['isPaidUser'] as bool? ?? false,
    );
  }
}

/// Phase1で使う運営提供クエストの参照用マップ（questIdからQuestを引く）。
final questCatalog = {
  for (final quest in [tutorialQuest, ...sampleQuests]) quest.id: quest,
};
