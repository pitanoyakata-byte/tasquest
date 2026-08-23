// アプリ起動時の基本フローを検証するスモークテスト。
// 初回起動ではWelcome画面が表示され、受注ボタンからCheckin画面へ遷移することを確認する。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tasquest/app.dart';
import 'package:tasquest/data/auth/auth_uid_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Firebase未接続のテスト環境向けに、認証済みuidを固定値でoverrideする。
  // リポジトリはデフォルトのLocalUserRepository（ProviderScope標準）のまま使う。
  ProviderScope buildTestApp() {
    return ProviderScope(
      overrides: [
        authUidProvider.overrideWith((ref) async => 'test-uid'),
      ],
      child: const TasQuestApp(),
    );
  }

  testWidgets('初回起動はWelcome画面から始まり、受注ボタンでCheckin画面へ遷移する',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Accept Quest'), findsOneWidget);

    await tester.tap(find.text('Accept Quest'));
    await tester.pumpAndSettle();

    expect(find.text('How are you feeling right now?'), findsOneWidget);
  });
}
