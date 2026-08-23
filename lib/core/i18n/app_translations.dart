import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'app_locale.dart';

/// テキストIDから多言語文言を引くための翻訳テーブル。
/// assets/i18n/{言語コード}.json を読み込んで保持する。
class AppTranslations {
  AppTranslations._(this.locale, this._values);

  final AppLocale locale;
  final Map<String, String> _values;

  static Future<AppTranslations> load(AppLocale locale) async {
    final raw = await rootBundle.loadString('assets/i18n/${locale.code}.json');
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final values = decoded.map((key, value) => MapEntry(key, value as String));
    return AppTranslations._(locale, values);
  }

  /// [textId] に対応する文言を取得する。[params] が渡された場合は
  /// 文言中の `{key}` プレースホルダーを置き換える。
  String t(String textId, [Map<String, String>? params]) {
    final template = _values[textId];
    if (template == null) {
      // 未翻訳のテキストIDはID自体を表示し、抜け漏れに気づけるようにする。
      return textId;
    }
    if (params == null || params.isEmpty) {
      return template;
    }
    var result = template;
    for (final entry in params.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }
}
