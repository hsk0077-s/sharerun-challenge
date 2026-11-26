import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import '../features/donation/donation_settlement.dart';
import '../features/home/home_cards.dart' show groupedNumber;
import '../features/profile/my_page_activity_stats.dart';
import '../features/shop/widgets/store_look.dart';
import '../l10n/guidance_copy.dart';
import '../l10n/remaining_surface.dart';

/// 증빙 이미지를 그리는 함수. 테스트에서 바꿔 끼운다.
typedef DonationReceiptImageBuilder = Widget Function(
  BuildContext context,
  String storagePath,
);

final donationReceiptImageBuilderProvider =
    Provider<DonationReceiptImageBuilder>((ref) => _storageReceiptImage);

/// Firebase Storage의 증빙 이미지. 로그인한 사람의 토큰으로 읽는다(공개 주소 아님).
Widget _storageReceiptImage(BuildContext context, String path) {
  return FutureBuilder<_ReceiptSource?>(
    future: _receiptSource(path),
    builder: (context, snapshot) {
      final source = snapshot.data;
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      if (source == null) return _ReceiptFailed(path: path);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          source.url,
          headers: {'Authorization': 'Firebase ${source.token}'},
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _ReceiptFailed(path: path),
        ),
      );
    },
  );
}

class _ReceiptSource {
  const _ReceiptSource(this.url, this.token);
  final String url;
  final String token;
}

Future<_ReceiptSource?> _receiptSource(String path) async {
  try {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final bucket = Firebase.app().options.storageBucket;
    if (token == null || bucket == null || bucket.isEmpty) return null;
    final url = 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/'
        '${Uri.encodeComponent(path)}?alt=media';
    return _ReceiptSource(url, token);
  } catch (_) {
    return null;
  }
}

class _ReceiptFailed extends StatelessWidget {
  const _ReceiptFailed({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Text(
      RemainingSurface.tr(
          context, 'donation.exec.proof_failed', '증빙 이미지를 불러오지 못했어요.'),
      key: DonationSettlementScreen.proofFailedKey,
      style: storeText(12, context.srcTokens.colors.muted),
    );
  }
}

/// 기부 투명성. 이번 달 기부 예정, 규칙과 한도, 실제 집행, 기부처를 보여 준다.
/// 기부는 회사(운영자) 자금으로 한다. 개인별 원화 기부액은 어디에도 쓰지 않는다.
class DonationSettlementScreen extends ConsumerStatefulWidget {
  const DonationSettlementScreen({super.key});

  static const retryKey = Key('donation-settlement-retry');
  static const titleKey = Key('donation-title');
  static const fixedNoteKey = Key('donation-fixed-note');
  static const monthKey = Key('donation-settlement-month');
  static const runKey = Key('donation-month-run');
  static const stepKey = Key('donation-month-step');
  static const matchKey = Key('donation-month-match');
  static const totalKey = Key('donation-month-total');
  static const statusKey = Key('donation-month-status');
  static const kmKey = Key('donation-month-km');
  static const rulesKey = Key('donation-rules');
  static const capKey = Key('donation-settlement-cap');
  static const capLineKey = Key('donation-cap-line');
  static const execKey = Key('donation-exec');
  static const execNoneKey = Key('donation-exec-none');
  static const partnerKey = Key('donation-partner');
  static const partnerPendingKey = Key('donation-partner-pending');
  static const footerKey = Key('donation-footer');
  static const proofFailedKey = Key('donation-proof-failed');
  static Key execRowKey(String month) => Key('donation-exec-$month');
  static Key proofKey(String month) => Key('donation-proof-$month');

  static String get fixedNote => RemainingSurface.trNow(
      'donation.fixed_note', '기부금은 쉐어런이 부담해요. 내 돈은 나가지 않아요.');
  static String get footer => RemainingSurface.trNow(
        'donation.footer',
        '기부금영수증과 연말정산 공제 대상이 아니에요. 기부금은 쉐어런 운영사가 자체 예산으로 부담해요. 위치 정보는 판매하지 않아요.',
      );

  @override
  ConsumerState<DonationSettlementScreen> createState() =>
      _DonationSettlementScreenState();
}

class _DonationSettlementScreenState
    extends ConsumerState<DonationSettlementScreen> {
  DonationSettlement? _data;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final data = await ref.read(donationSettlementLoaderProvider)();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final c = context.srcTokens.colors;
    final now = DateTime.now();
    final copy = DonationGuidance.of(Localizations.localeOf(context));
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('donation-back'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: copy.back,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: Icon(Icons.arrow_back_rounded, color: c.ink),
                ),
                const Spacer(),
                const StoreTag('DONATION'),
                const SizedBox(width: 12),
                StoreTag(
                    '${now.year} · ${now.month.toString().padLeft(2, '0')}'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              RemainingSurface.tr(
                  context, 'donation.title', '나의 활동으로 이어진 기부'),
              key: DonationSettlementScreen.titleKey,
              style: storeText(30, c.ink, w: FontWeight.w900, h: 1.15),
            ),
            const SizedBox(height: 8),
            Text(
              RemainingSurface.tr(context, 'donation.fixed_note',
                  '기부금은 쉐어런이 부담해요. 내 돈은 나가지 않아요.'),
              key: DonationSettlementScreen.fixedNoteKey,
              style: storeText(14, c.muted, h: 1.5, w: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (data == null && _loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (data == null && _failed) ...[
              Text(copy.fail, style: storeText(14, c.muted)),
              const SizedBox(height: 8),
              OutlinedButton(
                key: DonationSettlementScreen.retryKey,
                onPressed: _load,
                child: Text(copy.retry),
              ),
            ] else if (data != null) ...[
              _MonthBlock(
                data: data,
                km: ref.watch(myPageActivityStatsProvider).monthKm,
              ),
              const SizedBox(height: 12),
              _RulesBlock(data: data),
              const SizedBox(height: 12),
              _ExecutionBlock(data: data),
              const SizedBox(height: 12),
              _PartnerBlock(data: data),
              const SizedBox(height: 18),
              Text(
                RemainingSurface.tr(
                  context,
                  'donation.footer',
                  '기부금영수증과 연말정산 공제 대상이 아니에요. 기부금은 쉐어런 운영사가 자체 예산으로 부담해요. 위치 정보는 판매하지 않아요.',
                ),
                key: DonationSettlementScreen.footerKey,
                style: storeText(13, c.muted, h: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 이용자 전체 합계 금액. 단위는 언어별 번역에 들어 있다. 개인 금액이 아니다.
String _won(BuildContext context, int value) => RemainingSurface.tr(
      context,
      'donation.won',
      '${groupedNumber(value)}원',
      {'amount': groupedNumber(value)},
    );

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children, this.cardKey});

  final String title;
  final List<Widget> children;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: storeText(16, c.ink, w: FontWeight.w900)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.lineKey, this.bold = false});

  final String label;
  final String value;
  final Key? lineKey;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: storeText(14, bold ? c.ink : c.muted,
                    w: bold ? FontWeight.w900 : FontWeight.w600)),
          ),
          Text(
            value,
            key: lineKey,
            style: storeText(bold ? 18 : 14, c.ink,
                w: bold ? FontWeight.w900 : FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// 블록 1. 이번 달: 러닝 / 걸음 / 상점 매칭을 따로, 합계와 상태.
class _MonthBlock extends StatelessWidget {
  const _MonthBlock({required this.data, required this.km});

  final DonationSettlement data;
  final double km;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return _Card(
      cardKey: DonationSettlementScreen.monthKey,
      title: RemainingSurface.tr(context, 'donation.month.heading', '이번 달'),
      children: [
        _Line(RemainingSurface.tr(context, 'donation.month.run', '러닝 기부'),
            _won(context, data.runWon),
            lineKey: DonationSettlementScreen.runKey),
        _Line(RemainingSurface.tr(context, 'donation.month.step', '걸음 기부'),
            _won(context, data.stepWon),
            lineKey: DonationSettlementScreen.stepKey),
        _Line(RemainingSurface.tr(context, 'donation.month.match', '상점 매칭'),
            _won(context, data.matchWon),
            lineKey: DonationSettlementScreen.matchKey),
        const Divider(height: 18),
        _Line(RemainingSurface.tr(context, 'donation.month.total', '합계'),
            _won(context, data.monthTotalWon),
            lineKey: DonationSettlementScreen.totalKey, bold: true),
        const SizedBox(height: 6),
        Text(
          RemainingSurface.tr(context, 'donation.month.status', '기부 예정'),
          key: DonationSettlementScreen.statusKey,
          style: storeText(13, const Color(0xFFE8B84B), w: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          RemainingSurface.tr(
            context,
            'donation.month.km',
            '이번 달 내가 달린 거리 ${km.toStringAsFixed(1)} km',
            {'km': km.toStringAsFixed(1)},
          ),
          key: DonationSettlementScreen.kmKey,
          style: storeText(13, c.muted),
        ),
      ],
    );
  }
}

/// 블록 2. 규칙과 한도. 월 한도는 서버가 월 합계 문서에 적은 값이다.
class _RulesBlock extends StatelessWidget {
  const _RulesBlock({required this.data});

  final DonationSettlement data;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    Widget rule(String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(text, style: storeText(14, c.ink, h: 1.4)),
        );
    return _Card(
      cardKey: DonationSettlementScreen.rulesKey,
      title: RemainingSurface.tr(context, 'donation.rules.heading', '규칙과 한도'),
      children: [
        rule(RemainingSurface.tr(context, 'donation.rules.run', '러닝: 검증된 달리기 1km마다 100원')),
        rule(RemainingSurface.tr(context, 'donation.rules.step', '걸음: 하루 6,000보 이상이면 50원 (하루 1번)')),
        rule(RemainingSurface.tr(context, 'donation.rules.person', '한 사람이 하루에 최대 1,000원까지')),
        if (data.monthCapWon > 0)
          Text(
            RemainingSurface.tr(
              context,
              'donation.rules.month',
              '이번 달 전체 한도: ${groupedNumber(data.monthCapWon)}원',
              {'cap': groupedNumber(data.monthCapWon)},
            ),
            key: DonationSettlementScreen.capKey,
            style: storeText(14, c.ink, h: 1.4),
          )
        else
          Text(
            RemainingSurface.tr(context, 'donation.rules.month_unknown', '이번 달 전체 한도는 첫 기부가 기록되면 여기에 표시돼요.'),
            key: DonationSettlementScreen.capKey,
            style: storeText(14, c.muted, h: 1.4),
          ),
        if (data.capReached) ...[
          const SizedBox(height: 8),
          Text(
            RemainingSurface.tr(context, 'donation.rules.cap_reached', '이번 달 기부 한도에 도달했어요. 이후 활동은 이번 달 기부에 더해지지 않아요.'),
            key: DonationSettlementScreen.capLineKey,
            style: storeText(13, c.accent, w: FontWeight.w800, h: 1.4),
          ),
        ],
      ],
    );
  }
}

/// 블록 3. 실제 집행. 기록이 있을 때만 금액·날짜·기부처·증빙을 보인다.
class _ExecutionBlock extends ConsumerWidget {
  const _ExecutionBlock({required this.data});

  final DonationSettlement data;

  static String _date(DateTime? at) {
    if (at == null) return '';
    final d = at.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.srcTokens.colors;
    final receipt = ref.watch(donationReceiptImageBuilderProvider);
    return _Card(
      cardKey: DonationSettlementScreen.execKey,
      title: RemainingSurface.tr(context, 'donation.exec.heading', '실제 집행'),
      children: [
        if (data.executions.isEmpty)
          Text(
            RemainingSurface.tr(context, 'donation.exec.none', '아직 실제 집행 내역이 없어요. 첫 기부를 보내면 금액, 날짜, 증빙을 여기에 공개할게요.'),
            key: DonationSettlementScreen.execNoneKey,
            style: storeText(14, c.muted, h: 1.5),
          )
        else
          for (final row in data.executions)
            Padding(
              key: DonationSettlementScreen.execRowKey(row.month),
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    RemainingSurface.tr(
                      context,
                      'donation.exec.amount',
                      '${row.month} · ${groupedNumber(row.amountWon)}원 기부 완료',
                      {'month': row.month, 'amount': groupedNumber(row.amountWon)},
                    ),
                    style: storeText(15, c.ink, w: FontWeight.w900),
                  ),
                  if (row.executedAt != null)
                    Text(
                      RemainingSurface.tr(
                        context,
                        'donation.exec.date',
                        '집행일 ${_date(row.executedAt)}',
                        {'date': _date(row.executedAt)},
                      ),
                      style: storeText(13, c.muted),
                    ),
                  if (row.partnerName.isNotEmpty)
                    Text(
                      RemainingSurface.tr(
                        context,
                        'donation.exec.partner',
                        '기부처: ${row.partnerName}',
                        {'name': row.partnerName},
                      ),
                      style: storeText(13, c.muted),
                    ),
                  if (row.receiptImagePath.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(RemainingSurface.tr(context, 'donation.exec.proof', '증빙 이미지'),
                        style: storeText(12, c.muted, w: FontWeight.w700)),
                    const SizedBox(height: 4),
                    KeyedSubtree(
                      key: DonationSettlementScreen.proofKey(row.month),
                      child: receipt(context, row.receiptImagePath),
                    ),
                  ],
                ],
              ),
            ),
      ],
    );
  }
}

/// 블록 4. 기부처와 상태. 기부처 이름은 집행 기록에 있을 때만 쓴다.
class _PartnerBlock extends StatelessWidget {
  const _PartnerBlock({required this.data});

  final DonationSettlement data;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final name = data.partnerName;
    return _Card(
      cardKey: DonationSettlementScreen.partnerKey,
      title: RemainingSurface.tr(context, 'donation.partner.heading', '기부처와 상태'),
      children: [
        if (name == null)
          Text(
            RemainingSurface.tr(context, 'donation.partner.pending', '기부처 선정 중'),
            key: DonationSettlementScreen.partnerPendingKey,
            style: storeText(14, c.muted),
          )
        else
          Text(
            RemainingSurface.tr(
              context,
              'donation.exec.partner',
              '기부처: $name',
              {'name': name},
            ),
            style: storeText(14, c.ink, w: FontWeight.w700),
          ),
      ],
    );
  }
}
