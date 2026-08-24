import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/locale_provider.dart';
import '../home/home_screen.dart';
import '../my_page/my_page_screen.dart';
import '../settings/settings_screen.dart';

/// 画面仕様書0-3：ホーム／マイページ／設定を下部タブで行き来する外枠。
/// 各タブのAppBarタイトルはここで共通管理し、中身（body）だけを切り替える。
final _selectedTabIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _tabs = [
    _TabInfo(titleTextId: 'app.title', icon: Icons.home_outlined, selectedIcon: Icons.home),
    _TabInfo(
      titleTextId: 'common.tab.my_page',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
    _TabInfo(
      titleTextId: 'common.tab.settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(_selectedTabIndexProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tt(ref, _tabs[selectedIndex].titleTextId))),
      body: IndexedStack(
        index: selectedIndex,
        children: const [HomeScreen(), MyPageScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            ref.read(_selectedTabIndexProvider.notifier).state = index,
        destinations: [
          for (final tabInfo in _tabs)
            NavigationDestination(
              icon: Icon(tabInfo.icon),
              selectedIcon: Icon(tabInfo.selectedIcon),
              label: tt(ref, tabInfo.titleTextId),
            ),
        ],
      ),
    );
  }
}

class _TabInfo {
  const _TabInfo({required this.titleTextId, required this.icon, required this.selectedIcon});

  final String titleTextId;
  final IconData icon;
  final IconData selectedIcon;
}
