import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_exception.dart';
import '../core/theme/theme.dart';
import '../data/api/identity_api_client.dart';
import '../features/auth/login_connection_providers.dart';
import '../features/shop/widgets/store_look.dart';

/// 워치 전용 앱 안내. 아직 만들지 않았고 "예정"인 것만 보여 준다.
/// 갤럭시 워치부터 시작하며, 아래 화면은 시안이다(실제 동작 아님).
class WatchAppPreviewScreen extends ConsumerStatefulWidget {
  const WatchAppPreviewScreen({super.key});

  static const pairingButtonKey = Key('watch-pairing-code-button');
  static const pairingCodeKey = Key('watch-pairing-code');
  static const pairingErrorKey = Key('watch-pairing-error');
  static const revokeButtonKey = Key('watch-revoke-button');
  static const revokeDoneKey = Key('watch-revoke-done');

  static const platforms = <({String name, String note, bool first})>[
    (name: '갤럭시 워치', note: '가장 먼저 만들어요', first: true),
    (name: '안드로이드 워치 (Wear OS)', note: '갤럭시 워치 다음', first: false),
    (name: '스마트 밴드 (샤오미 등)', note: '그다음 순서로 검토해요', first: false),
    (name: '가민', note: '그다음 순서로 검토해요', first: false),
    (name: '애플 워치', note: '그다음 순서로 검토해요', first: false),
  ];

  @override
  ConsumerState<WatchAppPreviewScreen> createState() =>
      _WatchAppPreviewScreenState();
}

class _WatchAppPreviewScreenState extends ConsumerState<WatchAppPreviewScreen> {
  String? _code;
  String? _error;
  var _busy = false;
  var _revoked = false;
  List<ConnectedWatch> _watches = const [];
  Duration _left = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_loadWatches());
  }

  Future<void> _loadWatches() async {
    try {
      final rows = await ref.read(identityApiClientProvider).listWatchDevices();
      if (mounted) setState(() => _watches = rows);
    } catch (_) {
      // 목록을 못 받아도 연결 코드 받기는 쓸 수 있다.
    }
  }

  Future<void> _revokeOne(ConnectedWatch watch) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(identityApiClientProvider).revokeWatchDevice(watch.id);
      await _loadWatches();
    } catch (e) {
      if (mounted) setState(() => _error = ApiErrorMessage.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final issued =
          await ref.read(identityApiClientProvider).requestWatchPairingCode();
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _code = issued.code;
        _left = issued.expiresIn;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        final next = _left - const Duration(seconds: 1);
        if (next <= Duration.zero) {
          timer.cancel();
          setState(() {
            _code = null;
            _left = Duration.zero;
          });
        } else {
          setState(() => _left = next);
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = ApiErrorMessage.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revokeAll() async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('연결된 워치를 모두 해제할까요?'),
        content: const Text(
          '이 계정에 연결한 워치가 모두 로그아웃돼요. 워치에 남은 기록은 다시 연결하기 전까지 올라가지 않아요. 휴대폰 로그인은 그대로예요.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('모두 해제')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _revoked = false;
    });
    try {
      await ref.read(identityApiClientProvider).revokeWatches();
      if (mounted) setState(() => _revoked = true);
      await _loadWatches();
    } catch (e) {
      if (mounted) setState(() => _error = ApiErrorMessage.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _countdown {
    final m = _left.inMinutes.toString().padLeft(2, '0');
    final s = (_left.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        backgroundColor: c.canvas,
        elevation: 0,
        title: Text('워치 전용 앱', style: storeText(18, c.ink, w: FontWeight.w800)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.ink),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(
            '손목에서 바로 뛸 수 있는 쉐어런 워치 앱을 준비하고 있어요. '
            '워치 앱이 설치된 시계에서 아래 연결 코드를 입력하면 연결돼요. '
            '아래 시계 화면은 시안이에요.',
            key: const Key('watch-preview-intro'),
            style: storeText(13, c.muted, h: 1.5),
          ),
          const SizedBox(height: 16),
          _pairingCard(c),
          const SizedBox(height: 16),
          for (final p in WatchAppPreviewScreen.platforms) ...[
            _PlatformRow(name: p.name, note: p.note, first: p.first),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          const StoreSectionLabel('갤럭시 워치 화면 시안'),
          const SizedBox(height: 10),
          const _WatchFaceCarousel(),
        ],
      ),
    );
  }

  Widget _pairingCard(SrcColorRoles c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('워치 연결', style: storeText(14, c.ink, w: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '워치 앱에서 아래 6자리 숫자를 입력하면 이 계정으로 연결돼요. 코드는 5분 동안, 한 번만 쓸 수 있어요. 워치는 한 대만 연결돼서, 다른 워치를 연결하면 이전 워치는 해제돼요.',
            style: storeText(12, c.muted, h: 1.5),
          ),
          const SizedBox(height: 12),
          if (_code != null) ...[
            Center(
              child: Text(
                _code!,
                key: WatchAppPreviewScreen.pairingCodeKey,
                style: storeText(36, c.ink, w: FontWeight.w900),
              ),
            ),
            Center(
              child: Text(
                '남은 시간 $_countdown',
                style: storeText(12, c.muted, w: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              key: WatchAppPreviewScreen.pairingErrorKey,
              style: storeText(12, c.muted),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: WatchAppPreviewScreen.pairingButtonKey,
              onPressed: _busy ? null : _requestCode,
              child: Text(_code == null ? '6자리 연결 코드 받기' : '새 코드 받기'),
            ),
          ),
          if (_watches.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('연결된 워치 ${_watches.length}/3',
                style: storeText(12, c.ink, w: FontWeight.w800)),
            for (final watch in _watches)
              Row(
                key: Key('watch-row-${watch.id}'),
                children: [
                  Expanded(
                      child: Text(watch.label, style: storeText(12, c.muted))),
                  TextButton(
                    key: Key('watch-revoke-${watch.id}'),
                    onPressed: _busy ? null : () => _revokeOne(watch),
                    child: const Text('해제'),
                  ),
                ],
              ),
          ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              key: WatchAppPreviewScreen.revokeButtonKey,
              onPressed: _busy ? null : _revokeAll,
              child: const Text('연결된 워치 모두 해제'),
            ),
          ),
          if (_revoked)
            Text(
              '연결된 워치를 모두 해제했어요.',
              key: WatchAppPreviewScreen.revokeDoneKey,
              style: storeText(12, c.muted),
            ),
        ],
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow(
      {required this.name, required this.note, required this.first});
  final String name;
  final String note;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: first ? c.primary : c.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: storeText(14, c.ink, w: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(note, style: storeText(12, c.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: c.muted),
              borderRadius: BorderRadius.circular(99),
            ),
            child:
                Text('예정', style: storeText(12, c.muted, w: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _WatchFaceData {
  const _WatchFaceData(this.label, this.big, this.sub, this.icon);
  final String label;
  final String big;
  final String sub;
  final IconData icon;
}

const _watchFaces = [
  _WatchFaceData('시작', '3km', '탭해서 시작', Icons.play_arrow_rounded),
  _WatchFaceData('달리는 중', '5:42', '♥ 148  ·  1.8km', Icons.directions_run),
  _WatchFaceData('일시정지', '일시정지', '탭해서 다시 시작', Icons.pause_rounded),
  _WatchFaceData('대회 알림', '1위!', '대회 2명 앞서요', Icons.emoji_events_outlined),
  _WatchFaceData('끝', '3.00km', '5:38/km · 17분', Icons.check_rounded),
];

/// 시계 화면 시안을 크게 한 장씩 넘겨 본다. 실제 워치 앱의 화면 순서와 같다.
class _WatchFaceCarousel extends StatefulWidget {
  const _WatchFaceCarousel();

  @override
  State<_WatchFaceCarousel> createState() => _WatchFaceCarouselState();
}

class _WatchFaceCarouselState extends State<_WatchFaceCarousel> {
  final _controller = PageController(viewportFraction: 0.8);
  var _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Column(
      children: [
        SizedBox(
          height: 290,
          child: PageView.builder(
            key: const Key('watch-face-carousel'),
            controller: _controller,
            itemCount: _watchFaces.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _WatchFace(data: _watchFaces[i]),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _watchFaces.length; i++)
              Container(
                width: i == _page ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: i == _page ? c.primary : c.outline,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '시안입니다. 실제 시계 화면과 조금 다를 수 있어요.',
          style: storeText(11, c.muted),
        ),
      ],
    );
  }
}

class _WatchFace extends StatelessWidget {
  const _WatchFace({required this.data});
  final _WatchFaceData data;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Column(
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0A0A0A),
            border: Border.all(color: const Color(0xFF3A3A3A), width: 8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, size: 36, color: c.primary),
              const SizedBox(height: 6),
              Text(
                data.big,
                style: storeText(data.big.length > 5 ? 26 : 40, Colors.white,
                    w: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(data.sub, style: storeText(14, const Color(0xFFB8B8B8))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(data.label, style: storeText(14, c.muted, w: FontWeight.w700)),
      ],
    );
  }
}
