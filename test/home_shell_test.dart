// ホーム画面の下部タブ（ホーム／マイページ／設定）の遷移を検証するテスト。
// SharedPreferencesのプラグインインスタンスはテストバイナリ内でキャッシュされるため、
// widget_test.dartとは別ファイルに分離している（ファイル単位で別プロセスになる）。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tasquest/app.dart';
import 'package:tasquest/data/auth/auth_uid_provider.dart';

void main() {
  testWidgets('ホームの下部タブからマイページ・設定に遷移できる', (WidgetTester tester) async {
    // hasSeenWelcome=trueの状態を直接仕込み、起動直後にホームへ遷移させる。
    SharedPreferences.setMockInitialValues({
      'user_profile_v1.test-uid': '{'
          '"hasSeenWelcome":true,'
          '"appState":"normal",'
          '"isPaidUser":false,'
          '"stats":{'
          '"body":{"level":1,"exp":0},'
          '"mind":{"level":1,"exp":0},'
          '"life":{"level":1,"exp":0}'
          '},'
          '"activeQuestInstance":null'
          '}',
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authUidProvider.overrideWith((ref) async => 'test-uid')],
        child: const TasQuestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recommended Quests'), findsOneWidget);

    await tester.tap(find.text('My Page'));
    await tester.pumpAndSettle();
    expect(find.text('Status'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsWidgets);
  });
}
