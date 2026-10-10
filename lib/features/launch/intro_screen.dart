import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'intro_store.dart';

/// 첫 설치 때 한 번 나오는 소개 3장. 설정의 "소개 다시 보기"에서도 연다([replay]).
/// 말하는 것은 이미 정해진 규칙뿐이고, 숫자는 모두 서버 기준과 같다.
class IntroScreen extends StatefulWidget {
  const IntroScreen({
    required this.onFinished,
    this.replay = false,
    this.store = const IntroStore(),
    super.key,
  });

  /// 끝났을 때(건너뛰기·시작하기·로그인·닫기) 호출한다. 이미 "봤음"으로 저장된 뒤다.
  final VoidCallback onFinished;
  final bool replay;
  final IntroStore store;

  static const skipKey = Key('intro-skip');
  static const nextKey = Key('intro-next');
  static const shareCoinKey = Key('intro-share-coin');
  static const startKey = Key('intro-start');
  static const loginKey = Key('intro-login');
  static const closeKey = Key('intro-close');

  static const titles = [
    '걸으면 SHARE가 쌓여요',
    '한 걸음이 나눔이 된다',
    '내 기록은 어느 폰에서나 그대로예요',
  ];

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _last = 2;

  Future<void> _finish() async {
    await widget.store.markSeen();
    if (!mounted) return;
    widget.onFinished();
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _last;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3FAF6),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.tealAccent, size: 20),
                    const SizedBox(width: 6),
                    const Text(
                      '쉐어런',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const Spacer(),
                    if (!isLast)
                      TextButton(
                        key: IntroScreen.skipKey,
                        onPressed: _finish,
                        child: const Text('건너뛰기'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) => setState(() => _page = index),
                  children: const [
                    _IntroPage(
                      title: '걸으면 SHARE가 쌓여요',
                      body: '100걸음마다 10 SHARE를 받아요. 모은 SHARE로 대회에 참가할 수 있어요.',
                      note: 'SHARE는 현금으로 바꿀 수 없는 활동 보상이고, 하루에 받을 수 있는 양에 한도가 있어요.',
                      graphic: _ShareGraphic(),
                    ),
                    _IntroPage(
                      title: '한 걸음이 나눔이 된다',
                      body: '검증된 모든 달리기, 1km마다 회사가 100원을 기부해요. 내가 보탠 만큼은 앱에서 확인할 수 있어요.',
                      note: '회사의 월 기부 예산 안에서 진행돼요. 예산을 다 쓴 달은 "기부 목표 달성"으로 알려 드려요.',
                      graphic: _DonationGraphic(),
                    ),
                    _IntroPage(
                      title: '내 기록은 어느 폰에서나 그대로예요',
                      body: '걷기·달리기 기록은 서버에 저장돼요. 폰을 바꿔도 로그인하면 이어져요.',
                      note: null,
                      graphic: _SnailGraphic(),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i <= _last; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.tealAccent
                            : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  children: [
                    if (!isLast)
                      _PrimaryButton(
                        key: IntroScreen.nextKey,
                        label: '다음',
                        color: AppColors.tealAccent,
                        textColor: Colors.white,
                        onPressed: _next,
                      )
                    else if (widget.replay)
                      _PrimaryButton(
                        key: IntroScreen.closeKey,
                        label: '닫기',
                        color: AppColors.tealAccent,
                        textColor: Colors.white,
                        onPressed: _finish,
                      )
                    else ...[
                      _PrimaryButton(
                        key: IntroScreen.startKey,
                        label: '시작하기',
                        color: AppColors.angelGold,
                        textColor: AppColors.textBlack,
                        onPressed: _finish,
                      ),
                      TextButton(
                        key: IntroScreen.loginKey,
                        onPressed: _finish,
                        child: const Text('이미 계정이 있어요 · 로그인'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
    super.key,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.title,
    required this.body,
    required this.note,
    required this.graphic,
  });

  final String title;
  final String body;
  final String? note;
  final Widget graphic;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          graphic,
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              height: 1.3,
              fontWeight: FontWeight.w900,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: AppColors.textBlack,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 10),
            Text(
              note!,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _ShareGraphic extends StatelessWidget {
  const _ShareGraphic();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            key: IntroScreen.shareCoinKey,
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFF2D27A), AppColors.angelGold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('S', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('SHARE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _Card(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('100걸음', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.arrow_forward_rounded, color: AppColors.tealAccent),
                ),
                Text('10 SHARE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.tealAccent)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DonationGraphic extends StatelessWidget {
  const _DonationGraphic();

  @override
  Widget build(BuildContext context) {
    Widget km(String label) => Row(
          children: [
            const Icon(Icons.favorite, color: AppColors.angelGold, size: 28),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.angelGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text('+100원', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ],
        );
    return Column(
      children: [
        const SizedBox(height: 8),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              km('1km'),
              const SizedBox(height: 12),
              km('2km'),
              const SizedBox(height: 12),
              km('3km'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _Card(
          child: Row(
            children: [
              Icon(Icons.volunteer_activism_outlined, color: AppColors.tealAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '회사 이름으로 기부돼요 · 내가 내는 돈은 없어요 · 내 기여는 앱에서 확인',
                  style: TextStyle(fontWeight: FontWeight.w700, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SnailGraphic extends StatelessWidget {
  const _SnailGraphic();

  @override
  Widget build(BuildContext context) {
    Widget step(String label, {bool unknown = false}) => Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: unknown ? AppColors.borderLight : Colors.white,
                child: unknown
                    ? const Text('?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textGrey))
                    : ClipOval(
                        child: Image.asset(
                          'assets/images/characters/chibi_snail_disappointed.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
    return Column(
      children: [
        ClipOval(
          child: ColoredBox(
            color: Colors.white,
            child: Image.asset(
              'assets/images/characters/chibi_snail_disappointed.png',
              height: 150,
              width: 150,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const SizedBox(height: 150, width: 150),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const _Card(
          child: Text(
            '아직 순위가 없어서 살짝 시무룩해요… 같이 달려 볼래요?',
            style: TextStyle(fontWeight: FontWeight.w700, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            step('지금\n달팽이'),
            const Icon(Icons.chevron_right, color: AppColors.textGreyLight),
            step('등급을\n받으면', unknown: true),
            const Icon(Icons.chevron_right, color: AppColors.textGreyLight),
            step('티어가\n오르면', unknown: true),
          ],
        ),
      ],
    );
  }
}
