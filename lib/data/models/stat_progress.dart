import 'dart:math';

/// 体力・知力・生活力それぞれのレベル・経験値の状態。
/// 企画書5-2の経験値カーブ：必要経験値(L) = 50 × 1.122^(L-1)
class StatProgress {
  const StatProgress({required this.level, required this.exp});

  factory StatProgress.initial() => const StatProgress(level: 1, exp: 0);

  final int level;

  /// 現在レベル内で貯まっている経験値（次のレベルアップに必要な分に対する内訳）。
  final int exp;

  /// レベル[level]に到達するために必要な累積経験値ではなく、
  /// 「そのレベルから次のレベルに上がるために必要な経験値」を返す。
  static int expRequiredForLevel(int level) {
    return (50 * pow(1.122, level - 1)).round();
  }

  /// 通常クエスト1回で得られる経験値（必要経験値の半分）。
  static int normalQuestReward(int level) => (expRequiredForLevel(level) / 2).round();

  /// クイック枠クエスト1回で得られる経験値（必要経験値の1/4）。
  static int quickTierQuestReward(int level) => (expRequiredForLevel(level) / 4).round();

  /// 経験値を加算し、レベルアップが発生すれば繰り上げた新しい状態を返す。
  StatProgress addExp(int amount) {
    var newLevel = level;
    var newExp = exp + amount;
    var required = expRequiredForLevel(newLevel);
    while (newExp >= required) {
      newExp -= required;
      newLevel += 1;
      required = expRequiredForLevel(newLevel);
    }
    return StatProgress(level: newLevel, exp: newExp);
  }

  /// 無課金者向けの表示用レベル（企画書5-6：レベル50でキャップ）。
  /// 生の経験値・実際のレベルはそのまま保持し、表示だけをクランプする。
  int displayLevel({required bool isPaidUser, int cap = 50}) {
    if (isPaidUser) return level;
    return min(level, cap);
  }

  Map<String, dynamic> toJson() => {'level': level, 'exp': exp};

  factory StatProgress.fromJson(Map<String, dynamic> json) => StatProgress(
        level: json['level'] as int,
        exp: json['exp'] as int,
      );
}
