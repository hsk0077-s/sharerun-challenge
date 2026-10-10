import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app.dart';
import '../app/providers/app_providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../data/repositories/auth_repository.dart';
import '../features/privacy/login_devices.dart';

/// 로그인된 기기 목록과 "모든 기기에서 로그아웃".
class LoginDevicesScreen extends ConsumerStatefulWidget {
  const LoginDevicesScreen({super.key});

  static const signOutKey = Key('login-devices-sign-out');
  static const retryKey = Key('login-devices-retry');

  @override
  ConsumerState<LoginDevicesScreen> createState() => _LoginDevicesScreenState();
}

class _LoginDevicesScreenState extends ConsumerState<LoginDevicesScreen> {
  bool _working = false;

  Future<void> _signOutEverywhere() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모든 기기에서 로그아웃'),
        content: const Text(
          '이 폰을 포함해 로그인된 모든 기기에서 로그아웃돼요. '
          '다른 기기는 잠시 뒤 로그인 화면으로 돌아가요. 계속할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _working = true);
    try {
      await ref.read(securedActionApiClientProvider).signOutEverywhere();
      await ref.read(authRepositoryProvider).signOut();
      await ref.read(localAuthStoreProvider).clear();
      ref.read(persistedAuthSessionProvider.notifier).replace(null);
      if (!mounted) return;
      navigateToLoginScreen();
    } catch (_) {
      if (!mounted) return;
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃하지 못했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(loginDevicesProvider);
    return Scaffold(
      backgroundColor: AppColors.settingsBackground,
      appBar: AppBar(
        backgroundColor: AppColors.settingsBackground,
        elevation: 0,
        foregroundColor: AppColors.textBlack,
        title: Text(
          '로그인된 기기',
          style: AppTextStyles.header1.copyWith(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            '이 계정으로 앱을 연 기기예요. 기기 이름과 마지막으로 연 시각만 저장하고, '
            '위치나 IP 주소는 저장하지 않아요.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: 14),
          devices.when(
            data: (rows) => rows.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('아직 기록된 기기가 없어요.'),
                  )
                : Column(
                    children: [for (final row in rows) _DeviceTile(row)],
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Center(
              child: TextButton(
                key: LoginDevicesScreen.retryKey,
                onPressed: () => ref.invalidate(loginDevicesProvider),
                child: const Text('다시 불러오기'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            key: LoginDevicesScreen.signOutKey,
            onPressed: _working ? null : _signOutEverywhere,
            child: _working
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('모든 기기에서 로그아웃'),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile(this.device);

  final LoginDevice device;

  @override
  Widget build(BuildContext context) {
    final seen = device.lastSeenAt?.toLocal();
    final when = seen == null
        ? ''
        : '${seen.year}.${seen.month.toString().padLeft(2, '0')}.'
            '${seen.day.toString().padLeft(2, '0')} '
            '${seen.hour.toString().padLeft(2, '0')}:'
            '${seen.minute.toString().padLeft(2, '0')}';
    final name = device.model.isEmpty ? '알 수 없는 기기' : device.model;
    return Card(
      color: AppColors.surfaceWhite,
      child: ListTile(
        leading: const Icon(Icons.smartphone, color: AppColors.tealAccent),
        title: Text(
          device.current
              ? '$name (이 기기)'
              : device.isNew()
                  ? '$name · 새 기기'
                  : name,
        ),
        subtitle: Text(
          '${device.osVersion} · 앱 ${device.appVersion}\n마지막으로 연 시각 $when',
          style: AppTextStyles.caption,
        ),
        isThreeLine: true,
      ),
    );
  }
}
