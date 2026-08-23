/// クエストのジャンル。対応するステータス（体力・知力・生活力）と1対1で紐づく。
enum QuestGenre {
  body,
  mind,
  life;

  /// マイページ等での表示に使うテキストID。
  String get statTextId => switch (this) {
        QuestGenre.body => 'stat.body',
        QuestGenre.mind => 'stat.mind',
        QuestGenre.life => 'stat.life',
      };
}
