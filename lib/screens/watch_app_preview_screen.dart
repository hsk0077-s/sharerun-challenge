import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme.dart';
import '../features/shop/widgets/store_look.dart';

/// 워치 전용 앱 안내. 아직 만들지 않았고 "예정"인 것만 보여 준다.
/// 갤럭시 워치부터 시작하며, 아래 화면은 시안이다(실제 동작 아님).
class WatchAppPreviewScreen extends StatelessWidget {
  const WatchAppPreviewScreen({super.key});

  static const platforms = <({String name, String note, bool first})>[
    (name: '갤럭시 워치', note: '가장 먼저 만들어요', first: true),
    (name: '안드로이드 워치 (Wear OS)', note: '갤럭시 워치 다음', first: false),
    (name: '스마트 밴드 (샤오미 등)', note: '그다음 순서로 검토해요', first: false),
    (name: '가민', note: '그다음 순서로 검토해요', first: false),
    (name: '애플 워치', note: '그다음 순서로 검토해요', first: false),
  ];

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
            '손목에서 바로 뛸 수 있는 쉐어런 앱을 준비하고 있어요. '
            '아래 화면은 시안이고, 아직 쓸 수 없어요.',
            key: const Key('watch-preview-intro'),
            style: storeText(13, c.muted, h: 1.5),
          ),
          const SizedBox(height: 16),
          for (final p in platforms) ...[
            _PlatformRow(name: p.name, note: p.note, first: p.first),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          const StoreSectionLabel('갤럭시 워치 화면 시안'),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _WatchFace(label: '시작', big: '3km', sub: '탭해서 시작', icon: Icons.play_arrow_rounded),
                _WatchFace(label: '달리는 중', big: '5:42', sub: '♥ 148  ·  1.8km', icon: Icons.directions_run),
                _WatchFace(label: '일시정지', big: '일시정지', sub: '탭해서 다시 시작', icon: Icons.pause_rounded),
                _WatchFace(label: '대회 알림', big: '1위!', sub: '대회 2명 앞서요', icon: Icons.emoji_events_outlined),
                _WatchFace(label: '끝', big: '3.00km', sub: '5:38/km · 17분', icon: Icons.check_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({required this.name, required this.note, required this.first});
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
            child: Text('예정', style: storeText(12, c.muted, w: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _WatchFace extends StatelessWidget {
  const _WatchFace({
    required this.label,
    required this.big,
    required this.sub,
    required this.icon,
  });
  final String label;
  final String big;
  final String sub;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A0A0A),
              border: Border.all(color: const Color(0xFF3A3A3A), width: 5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: c.primary),
                const SizedBox(height: 4),
                Text(big, style: storeText(big.length > 5 ? 15 : 24, Colors.white, w: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(sub, style: storeText(10, const Color(0xFFB8B8B8))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: storeText(12, c.muted, w: FontWeight.w700)),
        ],
      ),
    );
  }
}
