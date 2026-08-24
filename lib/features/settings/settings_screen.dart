import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_locale.dart';
import '../../core/i18n/locale_provider.dart';

/// 画面仕様書7章：設定画面。Phase2で実際に動くのは言語切替のみ。
/// 音量・通知・サブスクリプション管理・アカウント管理・利用規約等は、
/// 対応するSDK/画面（AdMob・RevenueCat・paywall等）が未導入のため、
/// 「準備中」であることを明示するプレースホルダーとする
/// （動かないボタンを動くように見せない、CLAUDE.mdの誠実性の方針）。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return SafeArea(
      child: ListView(
        children: [
          _SectionHeader(title: tt(ref, 'settings.section.language')),
          ListTile(
            title: Text(tt(ref, 'settings.section.language')),
            subtitle: Text(_localeDisplayName(currentLocale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, ref, currentLocale),
          ),
          const Divider(),
          _SectionHeader(title: tt(ref, 'settings.section.sound')),
          _NotReadyTile(title: tt(ref, 'settings.volume_bgm'), ref: ref),
          _NotReadyTile(title: tt(ref, 'settings.volume_se'), ref: ref),
          const Divider(),
          _SectionHeader(title: tt(ref, 'settings.section.notification')),
          _NotReadyTile(title: tt(ref, 'settings.notification_toggle'), ref: ref),
          const Divider(),
          _SectionHeader(title: tt(ref, 'settings.section.subscription')),
          _NotReadyTile(title: tt(ref, 'settings.subscription_manage'), ref: ref),
          const Divider(),
          _SectionHeader(title: tt(ref, 'settings.section.account')),
          _NotReadyTile(title: tt(ref, 'settings.account_data_management'), ref: ref),
          const Divider(),
          _SectionHeader(title: tt(ref, 'settings.section.legal')),
          _NotReadyTile(title: tt(ref, 'settings.legal.privacy_policy'), ref: ref),
          _NotReadyTile(title: tt(ref, 'settings.legal.terms'), ref: ref),
        ],
      ),
    );
  }

  String _localeDisplayName(AppLocale locale) => switch (locale) {
        AppLocale.ja => '日本語',
        AppLocale.en => 'English',
        AppLocale.ko => '한국어',
        AppLocale.zhHans => '简体中文',
        AppLocale.de => 'Deutsch',
        AppLocale.fr => 'Français',
        AppLocale.it => 'Italiano',
        AppLocale.es => 'Español',
      };

  void _showLanguagePicker(BuildContext context, WidgetRef ref, AppLocale current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: RadioGroup<AppLocale>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                ref.read(localeProvider.notifier).state = value;
              }
              Navigator.of(context).pop();
            },
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final locale in AppLocale.values)
                  RadioListTile<AppLocale>(
                    value: locale,
                    title: Text(_localeDisplayName(locale)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _NotReadyTile extends StatelessWidget {
  const _NotReadyTile({required this.title, required this.ref});

  final String title;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.lock_clock_outlined, size: 20),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(ref, 'settings.not_ready_message'))),
        );
      },
    );
  }
}
