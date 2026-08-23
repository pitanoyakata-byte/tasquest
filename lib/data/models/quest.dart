import 'quest_genre.dart';

/// クエストのマスタデータ（画面仕様書 0-1 の quests/{questId} 相当）。
/// Phase1では運営提供クエストのみをアプリ内に固定データとして持つ。
class Quest {
  const Quest({
    required this.id,
    required this.nameTextId,
    required this.genre,
    required this.durationMinutes,
    required this.lockDurationMinutes,
    this.isQuickTier = false,
    this.isTutorial = false,
  });

  final String id;
  final String nameTextId;
  final QuestGenre genre;
  final int durationMinutes;
  final int lockDurationMinutes;
  final bool isQuickTier;
  final bool isTutorial;
}

/// チュートリアル用クエスト。ロック時間はごく短時間（画面仕様書3章の特記事項）。
const tutorialQuest = Quest(
  id: 'tutorial',
  nameTextId: 'quest.tutorial.name',
  genre: QuestGenre.body,
  durationMinutes: 1,
  lockDurationMinutes: 0, // 秒単位はlockDurationのSecondsで別管理
  isTutorial: true,
);

/// チュートリアルのロック時間（秒）。数秒程度に設定する。
const tutorialLockDurationSeconds = 5;

/// Phase1で用意する運営提供クエストのサンプル一覧。
const sampleQuests = <Quest>[
  Quest(
    id: 'morning_stretch',
    nameTextId: 'quest.sample.morning_stretch.name',
    genre: QuestGenre.body,
    durationMinutes: 10,
    lockDurationMinutes: 10,
  ),
  Quest(
    id: 'reading',
    nameTextId: 'quest.sample.reading.name',
    genre: QuestGenre.mind,
    durationMinutes: 10,
    lockDurationMinutes: 10,
  ),
  Quest(
    id: 'room_cleanup',
    nameTextId: 'quest.sample.room_cleanup.name',
    genre: QuestGenre.life,
    durationMinutes: 15,
    lockDurationMinutes: 15,
  ),
];
