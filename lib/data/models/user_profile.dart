import 'quest_genre.dart';
import 'quest_instance.dart';
import 'stat_progress.dart';

/// アプリ全体の状態（画面仕様書 0-2）。
/// normal: ホームへ。questInProgress: activeQuestInstanceの経過時間で
/// クエスト実行中画面／達成報告画面のどちらに遷移するか判定する。
enum AppRunState { normal, questInProgress }

/// Phase1（ローカル動作のみ・Firebase導入前）のユーザー状態。
/// 将来Firestoreに移行する際は、このクラスの形をuserドキュメントに近づける。
class UserProfile {
  UserProfile({
    required this.hasSeenWelcome,
    required this.appState,
    required this.stats,
    this.activeQuestInstance,
    this.isPaidUser = false,
  });

  factory UserProfile.initial() => UserProfile(
        hasSeenWelcome: false,
        appState: AppRunState.normal,
        stats: {
          QuestGenre.body: StatProgress.initial(),
          QuestGenre.mind: StatProgress.initial(),
          QuestGenre.life: StatProgress.initial(),
        },
      );

  final bool hasSeenWelcome;
  final AppRunState appState;
  final Map<QuestGenre, StatProgress> stats;
  final QuestInstance? activeQuestInstance;
  final bool isPaidUser;

  UserProfile copyWith({
    bool? hasSeenWelcome,
    AppRunState? appState,
    Map<QuestGenre, StatProgress>? stats,
    QuestInstance? activeQuestInstance,
    bool clearActiveQuestInstance = false,
    bool? isPaidUser,
  }) {
    return UserProfile(
      hasSeenWelcome: hasSeenWelcome ?? this.hasSeenWelcome,
      appState: appState ?? this.appState,
      stats: stats ?? this.stats,
      activeQuestInstance:
          clearActiveQuestInstance ? null : (activeQuestInstance ?? this.activeQuestInstance),
      isPaidUser: isPaidUser ?? this.isPaidUser,
    );
  }
}
