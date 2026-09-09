import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_route_nav.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/shop/providers/shop_tab_provider.dart';
import '../features/wallet/providers/wallet_provider.dart';
import '../features/wallet/widgets/share_insufficient_dialog.dart';

/// 크루 방장 관리 대시보드 (Screen 19).
class CrewManagerScreen extends ConsumerStatefulWidget {
  const CrewManagerScreen({super.key});

  @override
  ConsumerState<CrewManagerScreen> createState() => _CrewManagerScreenState();
}

class _CrewManagerScreenState extends ConsumerState<CrewManagerScreen> {
  static const _royalBlue = Color(0xFF3182F6);
  static const _saveNavy = Color(0xFF1A2B4A);

  static const _profileChangeDia = 100;
  static const _expandMembersDia = 300;
  static const _giftCprDia = 30;
  static const _giftDepositShare = 10000;
  static const _giftPassDia = 50;

  var _crewName = AppStrings.crewManagerCrewName;
  var _memberLimit = 50;
  var _viceLeader = '';
  final _members = <String>[
    AppStrings.crewManagerMember1,
    AppStrings.crewManagerMember2,
    AppStrings.crewManagerMember3,
  ];

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _spendDia(int amount, String actionLabel) {
    final wallet = ref.read(walletProvider);
    if (wallet.diamondBalance < amount) {
      _toast('DIA가 부족합니다. 상점에서 구매해 주세요. ($actionLabel)');
      return false;
    }
    ref.read(walletProvider.notifier).debitDia(amount);
    return true;
  }

  bool _spendShare(int amount, String actionLabel) {
    final wallet = ref.read(walletProvider);
    if (wallet.shareBalance < amount) {
      ShareInsufficientDialog.promptAndMaybeOpenBilling(context);
      return false;
    }
    ref.read(walletProvider.notifier).subtractShare(amount);
    return true;
  }

  Future<void> _onPushNotice() async {
    _toast('전체 공지 푸시를 발송했습니다. (무료)');
  }

  Future<void> _onProfileChange() async {
    if (!_spendDia(_profileChangeDia, '프로필 변경')) return;
    final controller = TextEditingController(text: _crewName);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('크루 이름 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || next == null || next.isEmpty) return;
    setState(() => _crewName = next);
    _toast('크루 프로필이 변경되었습니다. (−$_profileChangeDia DIA)');
  }

  void _onGiftCpr() {
    if (!_spendDia(_giftCprDia, '심폐소생권 선물')) return;
    ref.read(shopTabProvider.notifier).addItem(ShopItemSku.cpr);
    ref.read(shopTabProvider.notifier).addItem(ShopItemSku.safeGuard);
    _toast('크루원에게 심폐소생권·세이프가드 선물을 지급했습니다. (−$_giftCprDia DIA)');
  }

  void _onGiftDeposit() {
    if (!_spendShare(_giftDepositShare, '예치금 대납')) return;
    _toast('크루 대항전 예치금을 대납했습니다. (−$_giftDepositShare SHARE)');
  }

  void _onGiftPass() {
    if (!_spendDia(_giftPassDia, '챌린지 패스')) return;
    _toast('크루 전용 챌린지 패스·스킨을 구매했습니다. (−$_giftPassDia DIA)');
  }

  void _onExpandMembers() {
    if (!_spendDia(_expandMembersDia, '인원 확장')) return;
    setState(() => _memberLimit += 10);
    _toast('인원 한도가 $_memberLimit명으로 확장되었습니다. (−$_expandMembersDia DIA)');
  }

  void _onAppointVice(String name) {
    setState(() => _viceLeader = name);
    _toast('$name 님을 부방장으로 임명했습니다.');
  }

  void _onKick(String name) {
    setState(() {
      _members.remove(name);
      if (_viceLeader == name) _viceLeader = '';
    });
    _toast('$name 님을 강제 퇴출했습니다.');
  }

  void _onSave() {
    _toast('관리 설정을 저장했습니다. ($_crewName · 한도 $_memberLimit명)');
    AppRouteNav.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    8,
                    AppShapes.termsHorizontalPadding,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CrewManagerHeader(
                        onBack: () => AppRouteNav.pop(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '보유 DIA ${wallet.diamondBalance} · SHARE ${wallet.shareBalance}',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ManagerWhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const _CrewLogoMark(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _crewName,
                                    style: const TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textBlack,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_viceLeader.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '부방장: $_viceLeader',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: _onPushNotice,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryMintDark,
                                  foregroundColor: AppColors.textWhite,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppShapes.cardRadius,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('📢',
                                        style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppStrings.crewManagerPushNotice,
                                      style: AppTextStyles.buttonText.copyWith(
                                        color: AppColors.textWhite,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.crewManagerPremiumSection,
                        style: AppTextStyles.header1.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      _ManagerWhiteCard(
                        child: Row(
                          children: [
                            Text(
                              AppStrings.crewManagerProfileLabel,
                              style: AppTextStyles.agreementLabel.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            const Text('💎', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            _RoyalBlueChip(
                              label: AppStrings.crewManagerProfileChange,
                              onTap: _onProfileChange,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ManagerWhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppStrings.crewManagerGiftSection,
                              style: AppTextStyles.agreementLabel.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _RoyalBlueButton(
                              label: AppStrings.crewManagerGiftCpr,
                              onTap: _onGiftCpr,
                            ),
                            const SizedBox(height: 10),
                            _RoyalBlueButton(
                              label: AppStrings.crewManagerGiftDeposit,
                              subtitle: AppStrings.crewManagerGiftAngelBadge,
                              onTap: _onGiftDeposit,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('⚠️',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 6),
                                Text(
                                  AppStrings.crewManagerShareWarning,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 11,
                                    color: AppColors.warningOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _RoyalBlueButton(
                              label: AppStrings.crewManagerGiftPass,
                              onTap: _onGiftPass,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ManagerWhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '소속 팀원 관리 (${_members.length} / $_memberLimit명)',
                              style: AppTextStyles.agreementLabel.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (_members.length / _memberLimit)
                                    .clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: AppColors.borderLight,
                                color: AppColors.primaryMintDark,
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: _onExpandMembers,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _royalBlue,
                                side: const BorderSide(
                                  color: _royalBlue,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppShapes.cardRadius,
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('💎',
                                      style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      AppStrings.crewManagerExpandMembers,
                                      style: AppTextStyles.buttonText.copyWith(
                                        color: _royalBlue,
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_members.isEmpty)
                              Text(
                                '소속 팀원이 없습니다.',
                                style: AppTextStyles.caption,
                              )
                            else
                              ..._members.map(
                                (name) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _MemberRow(
                                    name: name,
                                    isVice: _viceLeader == name,
                                    onAppoint: () => _onAppointVice(name),
                                    onKick: () => _onKick(name),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    4,
                    AppShapes.termsHorizontalPadding,
                    12,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.9,
                      height: AppShapes.buttonHeight,
                      child: FilledButton(
                        onPressed: _onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: _saveNavy,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppShapes.cardRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          AppStrings.crewManagerSave,
                          style: AppTextStyles.buttonText.copyWith(
                            color: AppColors.textWhite,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrewManagerHeader extends StatelessWidget {
  const _CrewManagerHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.textBlack,
            iconSize: 22,
            onPressed: onBack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.crewManagerTitle,
          style: AppTextStyles.header1.copyWith(fontSize: 22),
        ),
      ],
    );
  }
}

class _ManagerWhiteCard extends StatelessWidget {
  const _ManagerWhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CrewLogoMark extends StatelessWidget {
  const _CrewLogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2B4A),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.nightlight_round, color: Colors.white),
    );
  }
}

class _RoyalBlueChip extends StatelessWidget {
  const _RoyalBlueChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3182F6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoyalBlueButton extends StatelessWidget {
  const _RoyalBlueButton({
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3182F6),
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.buttonText.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.onAppoint,
    required this.onKick,
    this.isVice = false,
  });

  final String name;
  final bool isVice;
  final VoidCallback onAppoint;
  final VoidCallback onKick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.borderLight,
          child: Text(name.isNotEmpty ? name.substring(0, 1) : '?'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isVice ? '$name (부방장)' : name,
            style: AppTextStyles.agreementLabel.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        TextButton(
          onPressed: onAppoint,
          child: Text(
            AppStrings.crewManagerAppointVice,
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF3182F6),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        TextButton(
          onPressed: onKick,
          child: Text(
            AppStrings.crewManagerForceKick,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
