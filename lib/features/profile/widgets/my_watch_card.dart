import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/router/route_names.dart';
import '../../../core/navigation/app_route_nav.dart';
import '../../../core/theme/theme.dart';
import '../../../data/api/identity_api_client.dart';
import '../../../data/models/user_model.dart';
import '../../../screens/device_connection_screen.dart';
import '../../auth/login_connection_providers.dart';

/// 이 계정에 연결된 워치 앱 목록. 못 받으면 빈 목록으로 보여 준다(마이 화면이 막히면 안 됨).
final connectedWatchAppsProvider =
    FutureProvider.autoDispose<List<ConnectedWatch>>((ref) async {
  try {
    return await ref.read(identityApiClientProvider).listWatchDevices();
  } catch (_) {
    return const [];
  }
});

/// 마이 화면 맨 위의 워치 카드. 지금 연결된 것을 보여 주고 연결·관리 화면으로 간다.
class MyWatchCard extends ConsumerWidget {
  const MyWatchCard({super.key});

  static const cardKey = Key('my-watch-card');
  static const buttonKey = Key('my-watch-card-button');
  static const healthLineKey = Key('my-watch-health-line');
  static const appLineKey = Key('my-watch-app-line');

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    await AppRouteNav.push<void>(
      context,
      RouteNames.watchSettings,
      materialBuilder: (_) => const DeviceConnectionScreen(),
    );
    ref.invalidate(connectedWatchAppsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.srcTokens.colors;
    final watchType =
        ref.watch(activeUserProfileProvider).value?.watchType ?? WatchType.none;
    final apps = ref.watch(connectedWatchAppsProvider).value ?? const [];
    final healthLinked = watchType != WatchType.none;
    final anyConnected = healthLinked || apps.isNotEmpty;

    final healthLine = healthLinked
        ? '건강 데이터: ${watchType.displayLabel} 연동됨'
        : '건강 데이터: 연동 안 됨';
    final appLine = apps.isEmpty
        ? '워치 앱: 연결된 시계 없음'
        : '워치 앱: ${apps.length}대 연결됨'
            '${apps.any((w) => w.label.isNotEmpty) ? ' · ${apps.map((w) => w.label).where((l) => l.isNotEmpty).join(', ')}' : ''}';

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Material(
        key: cardKey,
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(context, ref),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: anyConnected ? c.outline : c.primary),
            ),
            child: Row(
              children: [
                Icon(Icons.watch_rounded, size: 32, color: c.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anyConnected ? '내 워치' : '워치로 더 정확하게 달리기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        healthLine,
                        key: healthLineKey,
                        style: TextStyle(fontSize: 12, height: 1.4, color: c.muted),
                      ),
                      Text(
                        appLine,
                        key: appLineKey,
                        style: TextStyle(fontSize: 12, height: 1.4, color: c.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  key: buttonKey,
                  onPressed: () => _open(context, ref),
                  child: Text(anyConnected ? '관리' : '연결하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
