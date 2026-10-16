import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// 상점 새 디자인의 작은 부품들. 시안(추천·다이아·아이템 화면)의 모양을 그대로 옮겼다.

TextStyle storeText(
  double size,
  Color color, {
  FontWeight w = FontWeight.w600,
  double h = 1.2,
  double ls = 0,
}) =>
    TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: size,
      fontWeight: w,
      color: color,
      height: h,
      letterSpacing: ls,
    );

/// `SHOP` 같은 작은 영문 라벨.
class StoreTag extends StatelessWidget {
  const StoreTag(this.text, {this.color, super.key});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Text(
      text,
      style:
          storeText(11, color ?? c.muted, w: FontWeight.w800, h: 1.0, ls: 2.2),
    );
  }
}

/// 위쪽 오른편 잔액 알약. 아이콘 + 숫자.
class StoreBalancePill extends StatelessWidget {
  const StoreBalancePill({
    required this.icon,
    required this.value,
    required this.iconColor,
    super.key,
  });

  final IconData icon;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(value, style: storeText(13, c.ink, w: FontWeight.w900)),
        ],
      ),
    );
  }
}

/// 추천·다이아·아이템·꾸미기 글자 탭. 고른 탭 밑에 굵은 라임 선이 깔린다.
class StoreUnderlineTabs extends StatelessWidget {
  const StoreUnderlineTabs({
    required this.labels,
    required this.selected,
    required this.onSelected,
    required this.keys,
    super.key,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final List<Key> keys;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.outline)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                key: keys[i],
                onTap: () => onSelected(i),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == selected ? c.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: storeText(
                      15,
                      i == selected ? c.ink : c.muted,
                      w: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StoreSectionLabel extends StatelessWidget {
  const StoreSectionLabel(this.text, {this.more, this.onMore, super.key});

  final String text;
  final String? more;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(text, style: storeText(15, c.ink, w: FontWeight.w900)),
          const Spacer(),
          if (more != null)
            InkWell(
              onTap: onMore,
              child: Text(
                more!,
                style: storeText(12, c.muted, w: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

/// Coach+ 안내 카드. 라임 바탕, 월간/연간 가격 두 칸.
class StoreCoachCard extends StatelessWidget {
  const StoreCoachCard({
    required this.monthlyLabel,
    required this.yearlyLabel,
    required this.onTap,
    this.yearlyDiscountPct,
    this.badge,
    super.key,
  });

  final String monthlyLabel;
  final String yearlyLabel;
  final int? yearlyDiscountPct;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final on = c.onPrimary;
    return InkWell(
      key: const Key('coach-plus-store'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: on,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: storeText(11, c.primary, w: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Text(
                  'Coach+',
                  style: storeText(30, on, w: FontWeight.w900, h: 1.0),
                ),
                const Spacer(),
                Icon(Icons.headset_mic_rounded, color: on, size: 22),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '심박·상황에 맞춘 심층 코칭',
              style: storeText(
                14,
                on.withValues(alpha: 0.75),
                w: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: on,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '월간',
                          style: storeText(
                            11,
                            c.primary.withValues(alpha: 0.8),
                            w: FontWeight.w800,
                          ),
                        ),
                        Text(
                          monthlyLabel,
                          style: storeText(16, c.primary, w: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: on, width: 1.6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '연간',
                              style: storeText(
                                11,
                                on.withValues(alpha: 0.75),
                                w: FontWeight.w800,
                              ),
                            ),
                            if (yearlyDiscountPct != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '-$yearlyDiscountPct%',
                                style: storeText(11, on, w: FontWeight.w900),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          yearlyLabel,
                          style: storeText(16, on, w: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 다이아 팩 카드 한 장(추천 화면 가로 3장).
class StorePackCard extends StatelessWidget {
  const StorePackCard({
    required this.dia,
    required this.bonus,
    required this.price,
    this.hot = false,
    this.onTap,
    super.key,
  });

  final String dia;
  final String bonus;
  final String price;
  final bool hot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hot ? c.primary : c.outline,
              width: hot ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 16,
                child: hot
                    ? Text(
                        '인기',
                        style:
                            storeText(11, c.primary, w: FontWeight.w900, ls: 1),
                      )
                    : null,
              ),
              Row(
                children: [
                  Icon(Icons.diamond_outlined, size: 16, color: c.ink),
                  const SizedBox(width: 4),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        dia,
                        style: storeText(20, c.ink, w: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                bonus,
                style: storeText(11, c.primary, w: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(price, style: storeText(13, c.muted, w: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 러닝 아이템 작은 타일(추천 화면 2열).
class StoreItemTile extends StatelessWidget {
  const StoreItemTile({
    required this.icon,
    required this.name,
    required this.cost,
    required this.onTap,
    this.costIcon = Icons.diamond_outlined,
    super.key,
  });

  final IconData icon;
  final String name;
  final String cost;
  final IconData? costIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: c.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: storeText(13, c.ink, w: FontWeight.w800),
                    ),
                    Row(
                      children: [
                        if (costIcon != null) ...[
                          Icon(costIcon, size: 12, color: c.muted),
                          const SizedBox(width: 3),
                        ],
                        Flexible(
                          child: Text(
                            cost,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: storeText(12, c.muted, w: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
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

/// 아이템 탭의 한 줄. 동그란 아이콘 + 이름/설명 + 오른쪽 가격 알약.
class StoreItemRow extends StatelessWidget {
  const StoreItemRow({
    required this.icon,
    required this.name,
    required this.onTap,
    this.sub = '',
    this.cost,
    this.plainLabel,
    this.owned = 0,
    super.key,
  });

  final IconData icon;
  final String name;
  final String sub;

  /// 다이아로 사는 값. 있으면 라임 테두리 알약 안에 다이아 아이콘과 같이 보인다.
  final String? cost;

  /// SHARE·VALUE처럼 다이아가 아닌 값. 있으면 회색 알약으로 보인다.
  final String? plainLabel;
  final int owned;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.outline)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: c.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: storeText(15, c.ink, w: FontWeight.w800)),
                  if (sub.isNotEmpty || owned > 0)
                    Text(
                      [
                        if (sub.isNotEmpty) sub,
                        if (owned > 0) '보관함 $owned',
                      ].join(' · '),
                      style: storeText(12, c.muted),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: plainLabel != null ? c.outline : c.primary,
                  width: 1.4,
                ),
              ),
              child: plainLabel != null
                  ? Text(
                      plainLabel!,
                      style: storeText(12, c.muted, w: FontWeight.w900),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.diamond_outlined,
                            size: 13, color: c.primary),
                        const SizedBox(width: 4),
                        Text(
                          cost ?? '',
                          style: storeText(13, c.primary, w: FontWeight.w900),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 라임 알약 버튼. 시안처럼 아래로 빛이 번진다.
class StorePillButton extends StatelessWidget {
  const StorePillButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(29),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: c.onPrimary,
            shape: const StadiumBorder(),
          ),
          icon: icon == null ? const SizedBox.shrink() : Icon(icon),
          label: Text(
            label,
            style: storeText(17, c.onPrimary, w: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}
