import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/locale_provider.dart';
import '../../data/models/checkin_args.dart';
import '../../data/models/quest.dart';

/// 画面仕様書1章：初回起動時のみ表示するWelcome画面。
/// 導線は「クエストを受注する」ボタンの1つのみ。
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.pets, size: 96, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                tt(ref, 'welcome.mascot_greeting'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tt(ref, 'welcome.tutorial_quest_title'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(tt(ref, 'welcome.tutorial_quest_description')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  context.go(
                    '/checkin',
                    extra: const CheckinArgs(quest: tutorialQuest, isTutorial: true),
                  );
                },
                child: Text(tt(ref, 'welcome.accept_button')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
