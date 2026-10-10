import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../pedometer/walking_challenge_notification_service.dart';

/// 시작 화면. 사진 + 위쪽 그라데이션 + 슬로건 + 작은 로고.
class LaunchSplashView extends StatelessWidget {
  const LaunchSplashView({super.key});

  static const photoAsset = 'assets/images/splash_morning_run.jpg';
  /// 실제 로고(로그인 화면과 같은 파일). `src_logo_mark.png`는 1x1 자리표시 이미지라 쓰지 않는다.
  static const logoAsset = 'assets/images/sharerun_logo.png';
  static const slogan = '심장이 뛰는 한,\n나눔도 달린다';
  static const sloganKey = Key('launch-splash-slogan');

  static const _green = Color(0xFF0E3B2E);

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Material(
        color: _green,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              photoAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            // 위쪽에만 옅은 녹색 그라데이션(글자 자리), 아래쪽은 절반만.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _green.withValues(alpha: 0.70),
                    _green.withValues(alpha: 0.0),
                    _green.withValues(alpha: 0.0),
                    _green.withValues(alpha: 0.55),
                  ],
                  stops: const [0.0, 0.40, 0.72, 1.0],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 22, height: 2, color: Colors.white70),
                        const SizedBox(width: 8),
                        const Text(
                          'SHARE RUN',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      slogan,
                      key: sloganKey,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(blurRadius: 12, color: Color(0x99000000)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  logoAsset,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox(width: 24, height: 24),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '쉐어 런',
                                style: TextStyle(
                                  color: _green,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: SizedBox(
                        width: 90,
                        height: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                          child: LinearProgressIndicator(
                            color: Colors.white,
                            backgroundColor: Color(0x44FFFFFF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 콜드 스타트에서 홈 데이터(내 프로필)가 준비될 때까지만 시작 화면을 덮는다.
/// * 최소 대기 시간은 없다. 준비되면 바로 걷힌다.
/// * 알림을 눌러 앱이 열렸으면 처음부터 보이지 않는다.
/// * 앱으로 돌아올 때(hot start)는 위젯이 그대로라 다시 나오지 않는다.
/// * [maxWait]가 지나면 데이터가 늦어도 걷는다(사용자를 가두지 않는다).
class LaunchSplashGate extends ConsumerStatefulWidget {
  const LaunchSplashGate({
    required this.child,
    this.maxWait = const Duration(seconds: 8),
    super.key,
  });

  final Widget child;
  final Duration maxWait;

  static const splashKey = Key('launch-splash');

  @override
  ConsumerState<LaunchSplashGate> createState() => _LaunchSplashGateState();
}

class _LaunchSplashGateState extends ConsumerState<LaunchSplashGate> {
  bool _visible = true;
  Timer? _timer;

  void _hide() {
    _timer?.cancel();
    if (!mounted || !_visible) return;
    setState(() => _visible = false);
  }

  void _onNotificationLaunch() {
    if (WalkingChallengeNotificationService.launchedFromNotification.value) {
      _hide();
    }
  }

  @override
  void initState() {
    super.initState();
    WalkingChallengeNotificationService.launchedFromNotification
        .addListener(_onNotificationLaunch);
    if (WalkingChallengeNotificationService.launchedFromNotification.value) {
      _visible = false;
    }
    _timer = Timer(widget.maxWait, _hide);
    ref.listenManual(
      activeUserProfileProvider,
      (_, next) {
        if (next.hasValue || next.hasError) _hide();
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WalkingChallengeNotificationService.launchedFromNotification
        .removeListener(_onNotificationLaunch);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _visible
              ? const LaunchSplashView(key: LaunchSplashGate.splashKey)
              : const SizedBox.shrink(key: ValueKey('launch-splash-gone')),
        ),
      ],
    );
  }
}
