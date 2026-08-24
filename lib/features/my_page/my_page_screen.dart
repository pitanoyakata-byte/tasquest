import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/locale_provider.dart';
import '../../data/models/quest_genre.dart';
import '../../data/models/stat_progress.dart';
import '../../data/quest_history_provider.dart';
import '../../data/user_profile_controller.dart';

/// 画面仕様書6章：マイページ。Phase2ではステータス・振り返りの2タブのみ実装する
/// （図鑑・称号・数値記録タブはPhase2のさらに先の予定、ROADMAP.md参照）。
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Consumer(
        builder: (context, ref, _) {
          return Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: tt(ref, 'my_page.tab.status')),
                  Tab(text: tt(ref, 'my_page.tab.reflection')),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: [_StatusTab(), _ReflectionTab()],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusTab extends ConsumerWidget {
  const _StatusTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileControllerProvider).valueOrNull;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalLevel = profile.stats.values.fold<int>(0, (sum, stat) => sum + stat.level);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tt(ref, 'my_page.total_level_label'),
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('Lv.$totalLevel', style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final genre in QuestGenre.values)
            _StatCard(
              genre: genre,
              stat: profile.stats[genre] ?? StatProgress.initial(),
              isPaidUser: profile.isPaidUser,
            ),
        ],
      ),
    );
  }
}

class _StatCard extends ConsumerWidget {
  const _StatCard({required this.genre, required this.stat, required this.isPaidUser});

  final QuestGenre genre;
  final StatProgress stat;
  final bool isPaidUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final required = StatProgress.expRequiredForLevel(stat.level);
    final progress = required == 0 ? 0.0 : (stat.exp / required).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tt(ref, genre.statTextId), style: Theme.of(context).textTheme.titleMedium),
                Text('Lv.${stat.displayLevel(isPaidUser: isPaidUser)}'),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReflectionTab extends ConsumerWidget {
  const _ReflectionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileControllerProvider).valueOrNull;
    final historyAsync = ref.watch(questHistoryProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (profile != null && !profile.isPaidUser)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                tt(ref, 'my_page.reflection.free_notice'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('$error')),
              data: (history) {
                if (history.isEmpty) {
                  return Center(child: Text(tt(ref, 'my_page.reflection.empty')));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final instance = history[index];
                    return Card(
                      child: ListTile(
                        title: Text(tt(ref, instance.questNameTextId)),
                        subtitle: Text(_formatDate(instance.acceptedAt)),
                        trailing: instance.achievementScore == null
                            ? null
                            : Text(tt(ref, 'my_page.reflection.achievement_label',
                                {'score': '${instance.achievementScore}'})),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}
