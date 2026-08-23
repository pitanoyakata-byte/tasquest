import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/checkin_args.dart';
import '../../data/models/user_profile.dart';
import '../../data/user_profile_controller.dart';
import '../../features/checkin/checkin_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/quest_active/quest_active_screen.dart';
import '../../features/reward/reward_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _SplashScreen()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(
        path: '/checkin',
        builder: (context, state) => CheckinScreen(args: state.extra as CheckinArgs),
      ),
      GoRoute(path: '/quest_active', builder: (context, state) => const QuestActiveScreen()),
      GoRoute(path: '/reward', builder: (context, state) => const RewardScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );
});

/// 起動時の画面分岐（画面仕様書 0-2）を1回だけ判定し、適切な画面へ遷移する。
class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  bool _dispatched = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileControllerProvider);
    final profile = profileAsync.valueOrNull;

    if (profile != null && !_dispatched) {
      _dispatched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(_resolveInitialLocation(profile));
      });
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  String _resolveInitialLocation(UserProfile profile) {
    if (!profile.hasSeenWelcome) return '/welcome';

    if (profile.appState == AppRunState.questInProgress) {
      final instance = profile.activeQuestInstance;
      if (instance == null) return '/home';
      return instance.isLockElapsed ? '/reward' : '/quest_active';
    }

    return '/home';
  }
}
