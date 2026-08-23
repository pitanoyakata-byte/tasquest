/// アプリが対応する言語コード。
/// CLAUDE.mdで定めた8言語（ja/en/ko/zh-Hans/de/fr/it/es）に対応する。
enum AppLocale {
  ja('ja'),
  en('en'),
  ko('ko'),
  zhHans('zh-Hans'),
  de('de'),
  fr('fr'),
  it('it'),
  es('es');

  const AppLocale(this.code);

  final String code;

  static AppLocale fromCode(String code) {
    return AppLocale.values.firstWhere(
      (locale) => locale.code == code,
      orElse: () => AppLocale.en,
    );
  }
}
