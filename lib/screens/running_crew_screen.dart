import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../core/api/api_exception.dart';
import '../app/router/route_names.dart';
import '../core/config/app_env.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_exit_guard.dart';
import '../core/widgets/src_gradient_background.dart';
import '../data/firebase/share_spend_transaction.dart';
import '../features/wallet/providers/wallet_provider.dart';
import '../features/wallet/src_wallet_payment_system.dart';
import '../features/wallet/widgets/share_insufficient_dialog.dart';
import 'challenge_detail_screen.dart';
import 'crew_manager_screen.dart';
import 'hall_of_fame_screen.dart';

/// 러닝 크루 · 랭킹 및 창설 화면 (Screen 18).
class RunningCrewScreen extends ConsumerStatefulWidget {
  const RunningCrewScreen({super.key});

  @override
  ConsumerState<RunningCrewScreen> createState() => _RunningCrewScreenState();
}

class _RunningCrewScreenState extends ConsumerState<RunningCrewScreen> {
  static const _currentNavIndex = DashboardTabNavigation.crew;
  static const _completionRate = 0.8;
  static const _createButtonGold = Color(0xFFC9A227);
  static const _createCrewShareCost =
      SrcWalletPaymentSystem.crewCreateShareCost;
  static const _createCrewDiaCost = SrcWalletPaymentSystem.crewCreateDiaCost;

  static const _allRankings = <_CrewRankItem>[
    _CrewRankItem(
      rankLabel: AppStrings.runningCrewRank1Label,
      medal: '🥇',
      crewName: AppStrings.runningCrewRank1Name,
      distance: AppStrings.runningCrewRank1Distance,
    ),
    _CrewRankItem(
      rankLabel: AppStrings.runningCrewRank2Label,
      medal: '🥈',
      crewName: AppStrings.runningCrewRank2Name,
      distance: AppStrings.runningCrewRank2Distance,
    ),
    _CrewRankItem(
      rankLabel: AppStrings.runningCrewRank5Label,
      crewName: AppStrings.runningCrewMyCrewName,
      highlighted: true,
      showLogo: true,
    ),
  ];

  String _searchQuery = '';
  var _hasOwnCrew = true;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    SrcExitGuard.crewTabBack = _clearSearchOnBack;
  }

  @override
  void dispose() {
    if (identical(SrcExitGuard.crewTabBack, _clearSearchOnBack)) {
      SrcExitGuard.crewTabBack = null;
    }
    super.dispose();
  }

  /// 검색 중이면 필터만 지우고 원래 크루 목록에 남긴다.
  bool _clearSearchOnBack() {
    if (!mounted || _searchQuery.isEmpty) return false;
    setState(() => _searchQuery = '');
    return true;
  }

  List<_CrewRankItem> get _visibleRankings {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _allRankings;
    return _allRankings
        .where((e) => e.crewName.toLowerCase().contains(q))
        .toList();
  }

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

  Future<String?> _chooseCrewPayment() {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('크루 만들기'),
        content: const Text('서버가 50 DIA 또는 30,000 SHARE 중 선택한 금액만 차감합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'dia'),
            child: const Text('50 DIA'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'share'),
            child: const Text('30,000 SHARE'),
          ),
        ],
      ),
    );
  }

  Future<void> _onCreateCrew() async {
    if (_isSubmitting) return;
    final payWith = await _chooseCrewPayment();
    if (payWith != 'dia' && payWith != 'share') return;
    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final uid = ref.read(authStateChangesProvider).asData?.value?.uid;
      final useRemote =
          !AppEnv.useLocalMockData && uid != null && uid.isNotEmpty;
      final paidWithDia = payWith == 'dia';

      if (!useRemote) {
        final wallet = ref.read(walletProvider);
        if (paidWithDia) {
          if (wallet.diamondBalance < _createCrewDiaCost) {
            if (mounted) setState(() => _isSubmitting = false);
            _toast('DIA가 부족합니다. 상점에서 구매해 주세요.');
            return;
          }
          ref.read(walletProvider.notifier).debitDia(_createCrewDiaCost);
        } else if (wallet.shareBalance < _createCrewShareCost) {
          if (mounted) setState(() => _isSubmitting = false);
          await ShareInsufficientDialog.promptAndMaybeOpenBilling(context);
          return;
        } else {
          ref.read(walletProvider.notifier).subtractShare(_createCrewShareCost);
        }
      } else {
        final result = await ref.read(securedActionApiClientProvider).foundCrew(
              AppStrings.runningCrewMyCrewName,
              payWith: payWith,
            );
        ref.read(walletProvider.notifier).applyWalletSnapshot(
              shareBalance: result.shareBalance,
              diamondBalance: result.diamondBalance,
              valueBalance: result.valueTokenBalance,
            );
      }

      if (!mounted) return;
      setState(() => _hasOwnCrew = true);
      _toast(
        paidWithDia
            ? '새 크루 창설 완료 (−$_createCrewDiaCost DIA)'
            : '새 크루 창설 완료 (−$_createCrewShareCost SHARE)',
      );
      await AppRouteNav.push<void>(
        context,
        RouteNames.crewManager,
        materialBuilder: (_) => const CrewManagerScreen(),
      );
    } on InsufficientShareException {
      if (mounted) setState(() => _isSubmitting = false);
      if (!mounted) return;
      await ShareInsufficientDialog.promptAndMaybeOpenBilling(context);
    } on ApiException catch (error) {
      if (mounted) setState(() => _isSubmitting = false);
      if (!mounted) return;
      if (error.detail == 'Insufficient Diamond balance.') {
        _toast(error.userMessage);
        return;
      }
      await ShareInsufficientDialog.promptAndMaybeOpenBilling(context);
    } catch (error) {
      if (!mounted) return;
      _toast('크루 창설 실패: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    DashboardTabNavigation.go(context, index);
  }

  void _onBack() {
    if (_clearSearchOnBack()) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    DashboardTabNavigation.go(context, DashboardTabNavigation.home);
  }

  Future<void> _onSearch() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _CrewSearchDialog(initialQuery: _searchQuery),
    );
    if (!mounted) return;
    // 다이얼로그를 뒤로 닫으면 검색어를 비우고 전체 목록으로 돌아간다.
    if (result == null) {
      _clearSearchOnBack();
      return;
    }
    setState(() => _searchQuery = result.trim());
    _toast(
      result.trim().isEmpty
          ? '전체 랭킹을 표시합니다.'
          : '"$result" 검색 결과 ${_visibleRankings.length}건',
    );
  }

  void _onEnterRoom({String? crewName}) {
    final name = crewName ?? AppStrings.runningCrewMyCrewName;
    _toast('$name 챌린지 룸으로 이동합니다.');
    AppRouteNav.push<void>(
      context,
      RouteNames.challengeDetailForRoom('crew-challenge-room'),
      extra: 'crew-challenge-room',
      materialBuilder: (_) =>
          const ChallengeDetailScreen(roomId: 'crew-challenge-room'),
    );
  }

  void _onOpenHallOfFame() {
    AppRouteNav.push<void>(
      context,
      RouteNames.hallOfFame,
      materialBuilder: (_) => const HallOfFameScreen(),
    );
  }

  void _onOpenCrewManager() {
    AppRouteNav.push<void>(
      context,
      RouteNames.crewManager,
      materialBuilder: (_) => const CrewManagerScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final embedNav = DashboardTabNavigation.useEmbeddedBottomNav(context);
    final rankings = _visibleRankings;
    final scaffold = Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RunningCrewHeader(
                onBack: _onBack,
                onSearch: _onSearch,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '보유 SHARE ${_format(wallet.shareBalance)}',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _onOpenHallOfFame,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textBlack,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        AppStrings.runningCrewHallOfFame,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                      _MyCrewCard(
                        onTap: _hasOwnCrew
                            ? _onOpenCrewManager
                            : (_isSubmitting ? null : _onCreateCrew),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _onCreateCrew,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surfaceWhite,
                            foregroundColor: _createButtonGold,
                            side: const BorderSide(
                              color: _createButtonGold,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppShapes.cardRadius,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _ShareCoinIcon(),
                              const SizedBox(width: 8),
                              Flexible(
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: _createButtonGold,
                                        ),
                                      )
                                    : Text(
                                        AppStrings.runningCrewCreateButton,
                                        style:
                                            AppTextStyles.buttonText.copyWith(
                                          color: _createButtonGold,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.runningCrewRankingTitle,
                            style: AppTextStyles.header1.copyWith(fontSize: 18),
                          ),
                        ],
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '검색: "$_searchQuery"',
                          style: AppTextStyles.caption.copyWith(fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (rankings.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            '검색 결과가 없습니다.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption,
                          ),
                        )
                      else
                        ...rankings.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RankingCard(
                              rankLabel: item.rankLabel,
                              medal: item.medal,
                              crewName: item.crewName,
                              distance: item.distance,
                              highlighted: item.highlighted,
                              showLogo: item.showLogo,
                              onTap: () =>
                                  _onEnterRoom(crewName: item.crewName),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.runningCrewProgressLabel,
                              style: AppTextStyles.agreementLabel.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            AppStrings.runningCrewProgressValue,
                            style: AppTextStyles.agreementLabel.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryMintDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _completionRate,
                          minHeight: 10,
                          backgroundColor: AppColors.borderLight,
                          color: AppColors.primaryMintDark,
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
                    8,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.9,
                      height: AppShapes.buttonHeight,
                      child: FilledButton(
                        onPressed: () => _onEnterRoom(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryMintDark,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppShapes.cardRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          AppStrings.runningCrewEnterRoom,
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
      bottomNavigationBar: embedNav
          ? DashboardBottomNav(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
            )
          : null,
    );
    return embedNav
        ? SrcExitGuard(
            tabIndex: DashboardTabNavigation.crew,
            child: scaffold,
          )
        : scaffold;
  }

  String _format(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class _CrewRankItem {
  const _CrewRankItem({
    required this.rankLabel,
    required this.crewName,
    this.medal,
    this.distance,
    this.highlighted = false,
    this.showLogo = false,
  });

  final String rankLabel;
  final String crewName;
  final String? medal;
  final String? distance;
  final bool highlighted;
  final bool showLogo;
}

/// Owns the field controller until this route unmounts.
///
/// [showDialog] completes when the route starts popping, while the focused
/// field is still mounted. Disposing the controller then rebuilds that field
/// and deactivates its focus scope with dependents still attached
/// (`_dependents.isEmpty` on Flutter 3.44).
class _CrewSearchDialog extends StatefulWidget {
  const _CrewSearchDialog({required this.initialQuery});

  final String initialQuery;

  @override
  State<_CrewSearchDialog> createState() => _CrewSearchDialogState();
}

class _CrewSearchDialogState extends State<_CrewSearchDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);
  var _closed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close(String value) {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('크루 검색'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '크루 이름 입력',
          border: OutlineInputBorder(),
        ),
        onSubmitted: _close,
      ),
      actions: [
        TextButton(
          onPressed: () => _close(''),
          child: const Text('초기화'),
        ),
        FilledButton(
          onPressed: () => _close(_controller.text),
          child: const Text('검색'),
        ),
      ],
    );
  }
}

class _RunningCrewHeader extends StatelessWidget {
  const _RunningCrewHeader({
    required this.onBack,
    required this.onSearch,
  });

  final VoidCallback onBack;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppColors.textBlack,
              iconSize: 22,
              onPressed: onBack,
            ),
          ),
          Text(
            AppStrings.runningCrewTitle,
            style: AppTextStyles.header1.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.search_rounded),
              color: AppColors.textBlack,
              iconSize: 24,
              onPressed: onSearch,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyCrewCard extends StatelessWidget {
  const _MyCrewCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryMintDark,
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const _CrewLogoPlaceholder(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.runningCrewMyCrewName,
                      style: AppTextStyles.agreementLabel.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.runningCrewMyCrewStats,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textWhite.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '탭하여 크루 관리 열기 ›',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.textWhite.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
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

class _CrewLogoPlaceholder extends StatelessWidget {
  const _CrewLogoPlaceholder({this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2B4A),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.nightlight_round,
        color: AppColors.textWhite,
        size: size * 0.5,
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.rankLabel,
    required this.crewName,
    required this.onTap,
    this.medal,
    this.distance,
    this.highlighted = false,
    this.showLogo = false,
  });

  final String rankLabel;
  final String crewName;
  final VoidCallback onTap;
  final String? medal;
  final String? distance;
  final bool highlighted;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? AppColors.agreementBoxFill : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  medal ?? rankLabel,
                  style: AppTextStyles.agreementLabel.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: medal != null ? 20 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              if (showLogo) ...[
                const _CrewLogoPlaceholder(size: 28),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crewName,
                      style: AppTextStyles.agreementLabel.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        distance!,
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareCoinIcon extends StatelessWidget {
  const _ShareCoinIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: AppColors.progressYellow,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'S',
        style: AppTextStyles.buttonText.copyWith(
          color: AppColors.textWhite,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
