import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/locale_provider.dart';
import '../../data/user_profile_controller.dart';

/// 画面仕様書3章：クエスト実行中画面。ロックタイマーを1秒ごとに更新し、
/// 経過したら自動で達成報告・報酬画面へ遷移する。
class QuestActiveScreen extends ConsumerStatefulWidget {
  const QuestActiveScreen({super.key});

  @override
  ConsumerState<QuestActiveScreen> createState() => _QuestActiveScreenState();
}

class _QuestActiveScreenState extends ConsumerState<QuestActiveScreen> {
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileControllerProvider).valueOrNull;
    final instance = profile?.activeQuestInstance;

    if (instance == null) {
      // 状態が消えている（例：直接URLアクセス等）場合はホームへ戻す。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (instance.isLockElapsed && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/reward');
      });
    }

    final remaining = instance.remaining;
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: Text(tt(ref, 'quest_active.title'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tt(ref, instance.questNameTextId),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Text(tt(ref, 'quest_active.remaining_time_label')),
              const SizedBox(height: 8),
              Text(
                '$minutes:$seconds',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 32),
              if (instance.isTutorial)
                Text(
                  tt(ref, 'quest_active.tutorial_guide'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              // 広告視聴でのスキップ導線はAdMob未導入のためPhase1では未実装（PROGRESS.md参照）。
            ],
          ),
        ),
      ),
    );
  }
}
