import 'dart:math';

/// 企画書5-4-2：表示ステータス値の計算。
/// 装備の数値 × タウンの補正 × レベルの補正 × 美術品の補正。
/// ゲームプレイ判定（受注条件・報酬）には一切使わない、表示専用の値。
class DisplayStat {
  /// [level] は表示用レベル（無課金者はキャップ済み、課金者は本来のレベル）を渡す
  /// ことで、キャップ中の表示との整合性を保つ（開発者確認済み、2026-08-24）。
  /// [artworkMultiplier] は図鑑（美術品）実装までは1.0固定（補正なし）。
  static double calculate({
    required double equipmentValue,
    required int townLevel,
    required int level,
    double artworkMultiplier = 1.0,
  }) {
    return equipmentValue * _townMultiplier(townLevel) * pow(1.01, level) * artworkMultiplier;
  }

  static double _townMultiplier(int townLevel) {
    var multiplier = 1.0;
    for (var t = 1; t <= townLevel; t++) {
      multiplier *= (t % 5 == 0) ? 1.10 : 1.02;
    }
    return multiplier;
  }
}
