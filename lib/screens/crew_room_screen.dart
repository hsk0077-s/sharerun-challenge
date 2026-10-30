import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_route_nav.dart';
import '../core/theme/theme.dart';
import '../features/crew/crew_emblem.dart';
import '../features/crew/crew_membership.dart';
import '../features/shop/widgets/store_look.dart';
import '../l10n/remaining_surface.dart';

/// 크루 룸. 크루 정보·크루원은 모두 서버 값이다.
/// 크루끼리 겨루는 대항전은 아직 서버에 없어서 "준비 중"으로 보여 준다.
class CrewRoomScreen extends ConsumerWidget {
  const CrewRoomScreen({super.key});

  static const preparingKey = Key('crew-room-preparing');

  static String _roleLabel(String role) => switch (role) {
        'leader' => '크루장',
        'sub' => '부크루장',
        _ => '크루원',
      };

  static String _km(double km) =>
      km >= 100 ? '${km.round()}km' : '${km.toStringAsFixed(1)}km';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.srcTokens.colors;
    final async = ref.watch(myCrewProvider);
    final mine = async.asData?.value;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        backgroundColor: c.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: c.ink,
          onPressed: () => AppRouteNav.pop(context),
        ),
        title: Text(
          RemainingSurface.tr(context, 'crew_room.button', '크루 룸'),
          style: storeText(18, c.ink, w: FontWeight.w900),
        ),
      ),
      body: async.isLoading && mine == null
          ? const Center(child: CircularProgressIndicator())
          : mine == null
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    RemainingSurface.tr(
                      context,
                      'crew_room.body',
                      '크루에 들어 있어야 크루 룸을 볼 수 있어요. 크루에 들어갔는지, 네트워크가 연결됐는지 확인해 주세요.',
                    ),
                    style: storeText(14, c.muted),
                  ),
                )
              : _Room(mine: mine),
    );
  }
}

class _Room extends StatelessWidget {
  const _Room({required this.mine});

  final MyCrew mine;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final crew = mine.crew;
    final emblem = CrewEmblem.parse(crew.emblem) ?? CrewEmblem.fallback;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            CrewEmblemBadge(emblem: emblem, size: 72),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crew.name,
                    style: storeText(22, c.ink, w: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (crew.needsApproval ? '크루장 승인 가입' : '자유 가입') +
                        RemainingSurface.tr(
                          context,
                          'crew_room.body.2',
                          ' · 내 역할 ${CrewRoomScreen._roleLabel(mine.role)}',
                          {
                            'CrewRoomScreen._roleLabel(mine.role)':
                                CrewRoomScreen._roleLabel(mine.role),
                          },
                        ),
                    style: storeText(12, c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _Stat(value: '${crew.memberCount}/${crew.maxMembers}', label: '크루원'),
            const SizedBox(width: 10),
            _Stat(value: CrewRoomScreen._km(crew.totalDistanceKm), label: '누적 거리'),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          key: CrewRoomScreen.preparingKey,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            RemainingSurface.tr(
              context,
              'crew_room.body.3',
              '크루 대항전은 아직 열리지 않았어요. 열리면 여기서 이번 주 진행을 볼 수 있어요.',
            ),
            style: storeText(13, c.muted),
          ),
        ),
        const SizedBox(height: 22),
        Text('크루원', style: storeText(16, c.ink, w: FontWeight.w900)),
        const SizedBox(height: 8),
        for (final m in mine.members)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(m.nickname, style: storeText(15, c.ink, w: FontWeight.w700)),
            subtitle: Text(
              CrewRoomScreen._roleLabel(m.role),
              style: storeText(12, c.muted),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: storeText(18, c.ink, w: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, style: storeText(12, c.muted)),
          ],
        ),
      ),
    );
  }
}
