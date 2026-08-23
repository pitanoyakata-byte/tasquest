import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';
import 'app_translations.dart';

/// 画面側から `tt(ref, 'text.id')` の形でテキストIDを解決するためのヘルパー。
/// 翻訳データ読み込み中・エラー時はテキストIDをそのまま返し、抜け漏れに気づけるようにする。
String tt(WidgetRef ref, String textId, [Map<String, String>? params]) {
  final translations = ref.watch(translationsProvider).valueOrNull;
  return translations?.t(textId, params) ?? textId;
}

/// 現在選択中の言語。端末のロケールから初期値を推測し、
/// 対応外の言語だった場合は英語にフォールバックする。
final localeProvider = StateProvider<AppLocale>((ref) {
  final deviceLocale = PlatformDispatcher.instance.locale;
  final code = deviceLocale.countryCode == 'CN' || deviceLocale.scriptCode == 'Hans'
      ? 'zh-Hans'
      : deviceLocale.languageCode;
  final supported = AppLocale.values.map((l) => l.code);
  return AppLocale.fromCode(supported.contains(code) ? code : 'en');
});

/// 選択中言語の翻訳テーブルを非同期で読み込む。
final translationsProvider = FutureProvider<AppTranslations>((ref) async {
  final locale = ref.watch(localeProvider);
  return AppTranslations.load(locale);
});
