import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/locale_provider.dart';
import '../../data/models/checkin_args.dart';
import '../../data/models/quest.dart';
import '../../data/models/quest_genre.dart';
import '../../data/models/stat_progress.dart';
import '../../data/user_profile_controller.dart';

/// 画面仕様書5章：ホーム画面。おすすめクエスト一覧（固定データ）、3ステータスの表示、
/// 町の成長（体力=ジム／知力=研究施設／生活力=自宅）のグレードアップ導線を実装する。
/// 下部タブ（[HomeShell]）のbody部分として使うため、Scaffold/AppBarは持たない。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileControllerProvider).valueOrNull;

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final availableGradeUps =
        QuestGenre.values.where((genre) => profile.isGradeUpAvailable(genre)).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tt(ref, 'home.greeting'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _StatsRow(stats: profile.stats, isPaidUser: profile.isPaidUser),
          if (availableGradeUps.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...availableGradeUps.map((genre) => _GradeUpButton(genre: genre)),
          ],
          const SizedBox(height: 24),
          Text(tt(ref, 'home.recommended_title'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...sampleQuests.map((quest) => _QuestCard(quest: quest)),
        ],
      ),
    );
  }
}

class _GradeUpButton extends ConsumerWidget {
  const _GradeUpButton({required this.genre});

  final QuestGenre genre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.tonalIcon(
        onPressed: () async {
          await ref.read(userProfileControllerProvider.notifier).gradeUpTown(genre);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tt(ref, 'home.grade_up_celebration', {'stat': tt(ref, genre.statTextId)}),
              ),
            ),
          );
        },
        icon: const Icon(Icons.upgrade),
        label: Text(tt(ref, 'home.grade_up_button', {'stat': tt(ref, genre.statTextId)})),
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.stats, required this.isPaidUser});

  final Map<dynamic, StatProgress> stats;
  final bool isPaidUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: stats.entries.map((entry) {
        final genre = entry.key;
        final stat = entry.value;
        return Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(tt(ref, genre.statTextId), style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Lv.${stat.displayLevel(isPaidUser: isPaidUser)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  const _QuestCard({required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(tt(ref, quest.nameTextId)),
        subtitle: Text(tt(ref, 'home.quest_card_duration', {'minutes': '${quest.durationMinutes}'})),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.go('/checkin', extra: CheckinArgs(quest: quest, isTutorial: false));
        },
      ),
    );
  }
}
