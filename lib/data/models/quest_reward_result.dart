import 'quest_genre.dart';

/// クエスト達成報告の結果（画面仕様書4章の報酬演出に表示する内容）。
class QuestRewardResult {
  const QuestRewardResult({
    required this.expGained,
    required this.genre,
    this.equipmentGenre,
    this.equipmentValue,
  });

  final int expGained;
  final QuestGenre genre;

  /// 装備が更新された場合のみ非null（企画書5-3）。
  final QuestGenre? equipmentGenre;
  final double? equipmentValue;
}
