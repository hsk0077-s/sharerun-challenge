import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_exception.dart';
import '../core/theme/theme.dart';
import '../l10n/remaining_surface.dart';
import '../data/api/identity_api_client.dart';
import '../features/auth/login_connection_providers.dart';
import '../features/shop/widgets/store_look.dart';

/// 워치 전용 앱 연결 화면. 갤럭시 워치는 지금 쓸 수 있고(연결되면 "연결됨"),
/// 나머지 시계는 "예정"으로 보여 준다.
class WatchAppPreviewScreen extends ConsumerStatefulWidget {
  const WatchAppPreviewScreen({super.key});

  static const pairingButtonKey = Key('watch-pairing-code-button');
  static const pairingCodeKey = Key('watch-pairing-code');
  static const pairingErrorKey = Key('watch-pairing-error');
  static const revokeButtonKey = Key('watch-revoke-button');
  static const revokeDoneKey = Key('watch-revoke-done');

  static List<({String name, String note, bool first})> get platforms => [
        (
          name: RemainingSurface.trNow('watch_app_preview.body', '갤럭시 워치'),
          note: '',
          first: true,
        ),
        (
          name: RemainingSurface.trNow(
              'watch_app_preview.body.3', '안드로이드 워치 (Wear OS)'),
          note: RemainingSurface.trNow('watch_app_preview.body.4', '갤럭시 워치 다음'),
          first: false,
        ),
        (
          name: RemainingSurface.trNow(
              'watch_app_preview.body.5', '스마트 밴드 (샤오미 등)'),
          note: RemainingSurface.trNow(
              'watch_app_preview.body.6', '그다음 순서로 검토해요'),
          first: false,
        ),
        (
          name: RemainingSurface.trNow('watch_app_preview.body.7', '가민'),
          note: RemainingSurface.trNow(
              'watch_app_preview.body.6', '그다음 순서로 검토해요'),
          first: false,
        ),
        (
          name: RemainingSurface.trNow('watch_app_preview.body.8', '애플 워치'),
          note: RemainingSurface.trNow(
              'watch_app_preview.body.6', '그다음 순서로 검토해요'),
          first: false,
        ),
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
        title: Text(
          RemainingSurface.tr(ctx, 'watch_app_preview.dialog', '연결된 워치를 모두 해제할까요?'),
        ),
        content: Text(
          RemainingSurface.tr(
            ctx,
            'watch_app_preview.button',
            '이 계정에 연결한 워치가 모두 로그아웃돼요. 워치에 남은 기록은 다시 연결하기 전까지 올라가지 않아요. 휴대폰 로그인은 그대로예요.',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(RemainingSurface.tr(ctx, 'watch_app_preview.button.4', '취소'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                RemainingSurface.tr(ctx, 'watch_app_preview.button.2', '모두 해제'),
              )),
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
        title: Text(
          RemainingSurface.tr(context, 'watch_app_preview.button.3', '워치 전용 앱'),
          style: storeText(18, c.ink, w: FontWeight.w800),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.ink),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(
            RemainingSurface.trNow('watch_app_preview.intro', '손목에서 바로 뛸 수 있는 쉐어런 워치 앱을 준비하고 있어요. 워치 앱이 설치된 시계에서 아래 연결 코드를 입력하면 연결돼요.'),
            key: const Key('watch-preview-intro'),
            style: storeText(13, c.muted, h: 1.5),
          ),
          const SizedBox(height: 16),
          _pairingCard(c),
          const SizedBox(height: 16),
          for (final p in WatchAppPreviewScreen.platforms) ...[
            _PlatformRow(
              name: p.name,
              note: p.note,
              first: p.first,
              connected: p.first && _watches.isNotEmpty,
            ),
            const SizedBox(height: 8),
          ],
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
          Text(
            RemainingSurface.tr(context, 'watch_app_preview.body.11', '워치 연결'),
            style: storeText(14, c.ink, w: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            RemainingSurface.tr(
              context,
              'watch_app_preview.body.12',
              '워치 앱에서 아래 6자리 숫자를 입력하면 이 계정으로 연결돼요. 코드는 5분 동안, 한 번만 쓸 수 있어요. 워치는 한 대만 연결돼서, 다른 워치를 연결하면 이전 워치는 해제돼요.',
            ),
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
                RemainingSurface.tr(
                  context,
                  'watch_app_preview.body.13',
                  '남은 시간 $_countdown',
                  {'_countdown': _countdown},
                ),
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
              child: Text(
                _code == null
                    ? RemainingSurface.tr(
                        context, 'watch_app_preview.button.5', '6자리 연결 코드 받기')
                    : RemainingSurface.tr(
                        context, 'watch_app_preview.button.6', '새 코드 받기'),
              ),
            ),
          ),
          if (_watches.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              RemainingSurface.tr(
                context,
                'watch_app_preview.button.7',
                '연결된 워치 ${_watches.length}/3',
                {'_watches.length': _watches.length},
              ),
              style: storeText(12, c.ink, w: FontWeight.w800),
            ),
            for (final watch in _watches)
              Row(
                key: Key('watch-row-${watch.id}'),
                children: [
                  Expanded(
                      child: Text(watch.label, style: storeText(12, c.muted))),
                  TextButton(
                    key: Key('watch-revoke-${watch.id}'),
                    onPressed: _busy ? null : () => _revokeOne(watch),
                    child: Text(RemainingSurface.trNow('common.disconnect', '해제')),
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
              child: Text(
                RemainingSurface.tr(
                    context, 'watch_app_preview.button.8', '연결된 워치 모두 해제'),
              ),
            ),
          ),
          if (_revoked)
            Text(
              RemainingSurface.tr(
                context,
                'watch_app_preview.button.9',
                '연결된 워치를 모두 해제했어요.',
              ),
              key: WatchAppPreviewScreen.revokeDoneKey,
              style: storeText(12, c.muted),
            ),
        ],
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({
    required this.name,
    required this.note,
    required this.first,
    required this.connected,
  });
  final String name;
  final String note;
  final bool first;

  /// 갤럭시 워치가 이 계정에 연결돼 있으면 "연결됨"을 띄운다.
  final bool connected;

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
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(note, style: storeText(12, c.muted)),
                ],
              ],
            ),
          ),
          if (!first || connected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: connected ? c.primary : c.muted),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                connected
                    ? RemainingSurface.trNow('common.connected', '연결됨')
                    : RemainingSurface.tr(context, 'watch_app_preview.body.14', '예정'),
                style: storeText(12, connected ? c.primary : c.muted,
                    w: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}
