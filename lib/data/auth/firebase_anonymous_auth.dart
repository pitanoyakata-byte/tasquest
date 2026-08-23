import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Authenticationで匿名サインインし、uidを返す。
/// すでにサインイン済みの場合はそのuidをそのまま使う
/// （画面仕様書0-0：匿名認証で開始し、必要になった時点でアカウントリンクする）。
Future<String> ensureAnonymousSignIn() async {
  final auth = FirebaseAuth.instance;
  final current = auth.currentUser;
  if (current != null) {
    return current.uid;
  }
  final credential = await auth.signInAnonymously();
  final user = credential.user;
  if (user == null) {
    throw StateError('匿名サインインに失敗しました（FirebaseAuthからuserがnullで返されました）');
  }
  return user.uid;
}
