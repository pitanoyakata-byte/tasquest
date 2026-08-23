import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/auth/auth_uid_provider.dart';
import 'data/auth/firebase_anonymous_auth.dart';
import 'data/repositories/firestore_user_repository.dart';
import 'data/user_profile_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ProviderScope(
      overrides: [
        // 本番はFirebase匿名認証・Firestoreを使う。
        // テスト側は別途フェイク実装でoverrideする（test/widget_test.dart参照）。
        authUidProvider.overrideWith((ref) => ensureAnonymousSignIn()),
        userRepositoryProvider.overrideWithValue(FirestoreUserRepository()),
      ],
      child: const TasQuestApp(),
    ),
  );
}
