import 'quest_genre.dart';
import 'quest_instance.dart';
import 'stat_progress.dart';

/// アプリ全体の状態（画面仕様書 0-2）。
/// normal: ホームへ。questInProgress: activeQuestInstanceの経過時間で
/// クエスト実行中画面／達成報告画面のどちらに遷移するか判定する。
enum AppRunState { normal, questInProgress }

/// ユーザー状態（画面仕様書0-1のusers/{uid}に対応するアプリ内モデル）。
class UserProfile {
  UserProfile({
    required this.hasSeenWelcome,
    required this.appState,
    required this.stats,
    this.activeQuestInstance,
    this.isPaidUser = false,
    Map<QuestGenre, double>? equipmentValue,
    Map<QuestGenre, int>? townLevels,
  })  : equipmentValue = equipmentValue ?? _zeroDoubleMap(),
        townLevels = townLevels ?? _zeroIntMap();

  factory UserProfile.initial() => UserProfile(
        hasSeenWelcome: false,
        appState: AppRunState.normal,
        stats: {
          QuestGenre.body: StatProgress.initial(),
          QuestGenre.mind: StatProgress.initial(),
          QuestGenre.life: StatProgress.initial(),
        },
      );

  static Map<QuestGenre, double> _zeroDoubleMap() => {
        for (final genre in QuestGenre.values) genre: 0,
      };

  static Map<QuestGenre, int> _zeroIntMap() => {
        for (final genre in QuestGenre.values) genre: 0,
      };

  final bool hasSeenWelcome;
  final AppRunState appState;
  final Map<QuestGenre, StatProgress> stats;
  final QuestInstance? activeQuestInstance;
  final bool isPaidUser;

  /// 装備の上乗せ数値（企画書5-3、絶対値）。ドロップ時に現在値より高ければ更新。
  final Map<QuestGenre, double> equipmentValue;

  /// 町の成長（企画書5-7）。体力=ジム／知力=研究施設／生活力=自宅、各建物のタウンレベル。
  final Map<QuestGenre, int> townLevels;

  /// 企画書5-7：対応するステータスの表示レベルが5の倍数に達しているのに、
  /// まだタウンレベルが追いついていない（＝グレードアップ可能）かどうか。
  bool isGradeUpAvailable(QuestGenre genre) {
    final stat = stats[genre] ?? StatProgress.initial();
    final displayLevel = stat.displayLevel(isPaidUser: isPaidUser);
    final currentTownLevel = townLevels[genre] ?? 0;
    return displayLevel ~/ 5 > currentTownLevel;
  }

  UserProfile copyWith({
    bool? hasSeenWelcome,
    AppRunState? appState,
    Map<QuestGenre, StatProgress>? stats,
    QuestInstance? activeQuestInstance,
    bool clearActiveQuestInstance = false,
    bool? isPaidUser,
    Map<QuestGenre, double>? equipmentValue,
    Map<QuestGenre, int>? townLevels,
  }) {
    return UserProfile(
      hasSeenWelcome: hasSeenWelcome ?? this.hasSeenWelcome,
      appState: appState ?? this.appState,
      stats: stats ?? this.stats,
      activeQuestInstance:
          clearActiveQuestInstance ? null : (activeQuestInstance ?? this.activeQuestInstance),
      isPaidUser: isPaidUser ?? this.isPaidUser,
      equipmentValue: equipmentValue ?? this.equipmentValue,
      townLevels: townLevels ?? this.townLevels,
    );
  }
}
