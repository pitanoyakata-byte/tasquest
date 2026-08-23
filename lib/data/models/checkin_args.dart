import 'quest.dart';

/// checkin画面に渡す遷移パラメータ（画面仕様書2章の状態変数に相当）。
/// Phase1では mode=normal / tutorial のみ対応する（bundle・recordTemplateは未実装）。
class CheckinArgs {
  const CheckinArgs({required this.quest, required this.isTutorial});

  final Quest quest;
  final bool isTutorial;
}
