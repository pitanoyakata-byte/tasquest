import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/locale_provider.dart';
import '../../data/models/quest_reward_result.dart';
import '../../data/user_profile_controller.dart';

/// 画面仕様書4章：達成報告・報酬画面（Phase1はnormal/tutorialモードのみ）。
///
/// 誠実性の担保（企画書5-3-1）：抽選結果に相当する経験値は
/// [UserProfileController.completeActiveQuest] 側で確定してから演出を出す。
/// 演出が先に動いて後から結果を決める、という順序には絶対にしない。
class RewardScreen extends ConsumerStatefulWidget {
  const RewardScreen({super.key});

  @override
  ConsumerState<RewardScreen> createState() => _RewardScreenState();
}

enum _RewardStep { beforeReport, inputting, result }

class _RewardScreenState extends ConsumerState<RewardScreen> {
  _RewardStep _step = _RewardStep.beforeReport;
  int? _moodAfter;
  double _achievementScore = 5;
  QuestRewardResult? _rewardResult;
  bool _wasTutorial = false;

  static const _moodEmojis = ['😞', '😐', '🙂', '😃', '🤩'];

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileControllerProvider).valueOrNull;
    final instance = profile?.activeQuestInstance;

    // 報酬確定後はactiveQuestInstanceがnullになるため、
    // 確定前の情報は_confirmReward側でローカルへ保持しておく（_wasTutorial）。
    final isTutorial = _step == _RewardStep.result ? _wasTutorial : (instance?.isTutorial ?? false);

    if (instance == null && _step != _RewardStep.result) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(tt(ref, 'reward.result_title'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(context, isTutorial),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isTutorial) {
    switch (_step) {
      case _RewardStep.beforeReport:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () => setState(() => _step = _RewardStep.inputting),
              child: Text(tt(ref, 'reward.did_it_button'), style: const TextStyle(fontSize: 20)),
            ),
          ],
        );
      case _RewardStep.inputting:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tt(ref, 'reward.mood_prompt'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final value = i + 1;
                final selected = _moodAfter == value;
                return InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () => setState(() => _moodAfter = value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.transparent,
                    ),
                    child: Text(_moodEmojis[i], style: const TextStyle(fontSize: 28)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Text(tt(ref, 'reward.achievement_label'), style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _achievementScore,
              min: 0,
              max: 10,
              divisions: 10,
              label: _achievementScore.round().toString(),
              onChanged: (v) => setState(() => _achievementScore = v),
            ),
            Text(
              tt(ref, 'reward.achievement_note'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            FilledButton(
              onPressed: _moodAfter == null ? null : _confirmReward,
              child: Text(tt(ref, 'reward.did_it_button')),
            ),
          ],
        );
      case _RewardStep.result:
        final result = _rewardResult;
        final genreLabel = result == null ? '' : tt(ref, result.genre.statTextId);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 96, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              tt(ref, 'reward.exp_gained', {
                'stat': genreLabel,
                'amount': '${result?.expGained ?? 0}',
              }),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (result?.equipmentGenre != null) ...[
              const SizedBox(height: 12),
              Text(
                tt(ref, 'reward.equipment_updated', {
                  'stat': tt(ref, result!.equipmentGenre!.statTextId),
                  'value': result.equipmentValue!.round().toString(),
                }),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (isTutorial) ...[
              const SizedBox(height: 24),
              Text(
                tt(ref, 'reward.tutorial_closing'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: Text(tt(ref, 'reward.back_to_home')),
            ),
          ],
        );
    }
  }

  Future<void> _confirmReward() async {
    final activeInstance = ref.read(userProfileControllerProvider).valueOrNull?.activeQuestInstance;
    _wasTutorial = activeInstance?.isTutorial ?? false;
    final controller = ref.read(userProfileControllerProvider.notifier);
    final result = await controller.completeActiveQuest(
      achievementScore: _achievementScore.round(),
      doubleReward: false, // 広告視聴による2倍はAdMob未導入のためPhase1では未実装。
    );
    if (!mounted) return;
    setState(() {
      _rewardResult = result;
      _step = _RewardStep.result;
    });
  }
}
