// アプリ起動時の基本フローを検証するスモークテスト。
// 初回起動ではWelcome画面が表示され、受注ボタンからCheckin画面へ遷移することを確認する。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tasquest/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('初回起動はWelcome画面から始まり、受注ボタンでCheckin画面へ遷移する',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TasQuestApp()));
    await tester.pumpAndSettle();

    expect(find.text('Accept Quest'), findsOneWidget);

    await tester.tap(find.text('Accept Quest'));
    await tester.pumpAndSettle();

    expect(find.text('How are you feeling right now?'), findsOneWidget);
  });
}
