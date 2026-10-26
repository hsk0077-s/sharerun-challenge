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

    // 연결된 것만 보여 주고, 한 대로 합쳐서 말한다. 건강 데이터와 시계 앱은 사용자가
    // 구분할 필요가 없다. Health Connect 연결은 브랜드를 가리지 않으므로 이름은 일반 표현을 쓴다.
    final appName = apps
        .map((w) => w.label)
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    final String headline;
    final String note;
    if (healthLinked && apps.isNotEmpty) {
      headline = '스마트워치 연결됨';
      note = '걸음·심박을 받고, 시계 앱으로도 기록해요';
    } else if (healthLinked) {
      headline = '스마트워치 연결됨';
      note = '걸음·심박을 휴대폰으로 받아요';
    } else {
      headline = appName.isEmpty ? '시계 앱 연결됨' : '$appName 연결됨';
      note = '시계에서 바로 기록해요';
    }

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
                      if (anyConnected) ...[
                        Text(
                          headline,
                          key: healthLineKey,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          note,
                          style: TextStyle(
                              fontSize: 12, height: 1.4, color: c.muted),
                        ),
                      ] else
                        Text(
                          '걸음·심박을 시계에서 바로 기록해요',
                          style: TextStyle(
                              fontSize: 12, height: 1.4, color: c.muted),
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
