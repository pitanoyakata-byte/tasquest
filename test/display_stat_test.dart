// 表示ステータス値の計算式（企画書5-4-2）が、企画書記載の計算例と一致するか検証する。

import 'package:flutter_test/flutter_test.dart';
import 'package:tasquest/data/models/display_stat.dart';

void main() {
  test('企画書5-4-2の計算例（体力Lv56・装備1000・タウンLv11・美術品補正1.265）と一致する', () {
    final result = DisplayStat.calculate(
      equipmentValue: 1000,
      townLevel: 11,
      level: 56,
      artworkMultiplier: 1.265, // 企画書の計算例（1.01^4 × 1.05^4）をそのまま使用
    );

    // 企画書の計算例：約3193
    expect(result, closeTo(3193, 5));
  });

  test('タウンレベル0（未グレードアップ）は補正なし', () {
    final result = DisplayStat.calculate(equipmentValue: 500, townLevel: 0, level: 1);
    expect(result, closeTo(500 * 1.01, 0.01));
  });
}
