import 'quest_genre.dart';

/// 受注済み・進行中・完了したクエストの記録
/// （画面仕様書 0-1 の users/{uid}/questInstances/{instanceId} 相当）。
class QuestInstance {
  QuestInstance({
    required this.id,
    required this.questId,
    required this.questNameTextId,
    required this.genre,
    required this.acceptedAt,
    required this.lockDurationSeconds,
    required this.moodAtAccept,
    required this.isTutorial,
    required this.isQuickTier,
    this.achievementScore,
    this.completed = false,
    this.rewardExp,
  });

  final String id;
  final String questId;
  final String questNameTextId;
  final QuestGenre genre;
  final DateTime acceptedAt;
  final int lockDurationSeconds;
  final int moodAtAccept;
  final bool isTutorial;
  final bool isQuickTier;
  final int? achievementScore;
  final bool completed;
  final int? rewardExp;

  /// ロック時間が経過済みかどうか。サーバー時刻基準が本来の設計だが、
  /// Phase1（ローカル動作のみ）では端末時刻で判定する。
  bool get isLockElapsed =>
      DateTime.now().isAfter(acceptedAt.add(Duration(seconds: lockDurationSeconds)));

  Duration get remaining {
    final end = acceptedAt.add(Duration(seconds: lockDurationSeconds));
    final diff = end.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  QuestInstance copyWith({
    int? achievementScore,
    bool? completed,
    int? rewardExp,
  }) {
    return QuestInstance(
      id: id,
      questId: questId,
      questNameTextId: questNameTextId,
      genre: genre,
      acceptedAt: acceptedAt,
      lockDurationSeconds: lockDurationSeconds,
      moodAtAccept: moodAtAccept,
      isTutorial: isTutorial,
      isQuickTier: isQuickTier,
      achievementScore: achievementScore ?? this.achievementScore,
      completed: completed ?? this.completed,
      rewardExp: rewardExp ?? this.rewardExp,
    );
  }
}
