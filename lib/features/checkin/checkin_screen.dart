import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/locale_provider.dart';
import '../../data/models/checkin_args.dart';
import '../../data/models/quest.dart';
import '../../data/user_profile_controller.dart';

/// 画面仕様書2章：体調・モチベーションチェック（Phase1はnormal/tutorialモードのみ）。
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key, required this.args});

  final CheckinArgs args;

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  int? _selectedMood;
  bool _submitting = false;

  static const _moodEmojis = ['😞', '😐', '🙂', '😃', '🤩'];

  @override
  Widget build(BuildContext context) {
    final mood = _selectedMood;
    return Scaffold(
      appBar: AppBar(title: Text(widget.args.quest.nameTextId.isEmpty
          ? ''
          : tt(ref, widget.args.quest.nameTextId))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tt(ref, 'checkin.mood_prompt'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final value = i + 1;
                  final selected = mood == value;
                  return InkWell(
                    borderRadius: BorderRadius.circular(32),
                    onTap: () => setState(() => _selectedMood = value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.transparent,
                      ),
                      child: Text(_moodEmojis[i], style: const TextStyle(fontSize: 32)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              if (mood != null)
                Text(
                  tt(ref, 'checkin.mood_reaction_$mood'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              if (widget.args.isTutorial) ...[
                const SizedBox(height: 16),
                Text(
                  tt(ref, 'checkin.tutorial_guide'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: mood == null || _submitting ? null : _confirm,
                child: Text(tt(ref, 'checkin.confirm_button')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    final controller = ref.read(userProfileControllerProvider.notifier);
    if (widget.args.isTutorial) {
      await controller.markWelcomeSeen();
    }
    await controller.acceptQuest(
      quest: widget.args.quest,
      moodAtAccept: _selectedMood!,
      lockDurationSecondsOverride:
          widget.args.isTutorial ? tutorialLockDurationSeconds : null,
    );
    if (!mounted) return;
    context.go('/quest_active');
  }
}
