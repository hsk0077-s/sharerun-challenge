import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../core/api/api_exception.dart';
import '../app/router/route_names.dart';
import '../core/config/app_env.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/navigation/dashboard_tab_navigation.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/theme.dart';
import '../core/widgets/src_dashboard_bottom_nav.dart';
import '../core/widgets/src_exit_guard.dart';
import '../data/firebase/share_spend_transaction.dart';
import '../features/crew/crew_emblem.dart';
import '../features/crew/crew_emblem_status.dart';
import '../features/crew/crew_membership.dart';
import '../features/shop/widgets/store_look.dart';
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
  static const _createCrewShareCost =
      SrcWalletPaymentSystem.crewCreateShareCost;
  static const _createCrewDiaCost = SrcWalletPaymentSystem.crewCreateDiaCost;

  String _searchQuery = '';
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

  /// 검색어에 맞는 크루. 지금은 내 크루 하나뿐이다. (남의 크루 목록은 서버 랭킹이 생기면 채운다.)
  bool get _myCrewMatches {
    final q = _searchQuery.trim().toLowerCase();
    return q.isEmpty ||
        AppStrings.runningCrewMyCrewName.toLowerCase().contains(q);
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
    // 먼저 엠블럼을 고르고, 그다음 결제 방법을 고른다.
    final emblem = await CrewEmblemPicker.show(
      context,
      ref.read(crewEmblemProvider),
    );
    if (emblem == null || !mounted) return;
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
              payWith: payWith!,
              emblem: emblem.code,
            );
        ref.read(walletProvider.notifier).applyWalletSnapshot(
              shareBalance: result.shareBalance,
              diamondBalance: result.diamondBalance,
              valueBalance: result.valueTokenBalance,
            );
      }

      if (!mounted) return;
      await ref.read(crewEmblemProvider.notifier).choose(emblem);
      _refreshCrews();
      if (!mounted) return;
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
          : '"$result" 검색 결과 ${_myCrewMatches ? 1 : 0}건',
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

  /// 엠블럼 바꾸기(무료). 서버에 내 크루가 있으면 서버에 먼저 저장하고,
  /// 없으면(지금 보이는 크루는 샘플) 이 폰에만 저장한다고 알려 준다.
  Future<void> _onChangeEmblem() async {
    final current = ref.read(crewEmblemProvider);
    // 로그인 정보를 못 읽으면(예: 아직 준비 전) 폰에만 저장하는 쪽으로 간다.
    String? uid;
    try {
      uid = ref.read(authStateChangesProvider).asData?.value?.uid;
    } catch (_) {
      uid = null;
    }
    final useRemote = !AppEnv.useLocalMockData && uid != null && uid.isNotEmpty;
    final api = useRemote ? ref.read(securedActionApiClientProvider) : null;
    // 서버에 내 크루가 있으면 해금한 테두리·산 엠블럼을 먼저 받아 온다.
    CrewEmblemStatus? status;
    if (api != null) {
      try {
        status = await api.crewEmblemStatus();
      } catch (_) {
        status = null;
      }
    }
    if (!mounted) return;
    if (status != null && status.cooldownSeconds > 0) {
      final days = (status.cooldownSeconds / 86400).ceil();
      _toast('엠블럼은 자주 바꿀 수 없어요. 약 $days일 뒤에 다시 바꿀 수 있어요.');
      return;
    }
    final picked = await CrewEmblemPicker.show(
      context,
      current,
      status: status,
      onBuy: status == null || api == null
          ? null
          : (id) async {
              try {
                final result = await api.purchaseCrewPaidEmblem(id);
                ref.read(walletProvider.notifier).applyWalletSnapshot(
                      shareBalance: result.shareBalance,
                      diamondBalance: result.diamondBalance,
                      valueBalance: result.valueTokenBalance,
                    );
                return await api.crewEmblemStatus();
              } on ApiException catch (error) {
                _toast(
                  error.statusCode == 400
                      ? 'DIA가 부족해요.'
                      : '엠블럼을 사지 못했어요. 잠시 뒤 다시 해 주세요.',
                );
              } catch (_) {
                _toast('엠블럼을 사지 못했어요. 잠시 뒤 다시 해 주세요.');
              }
              return null;
            },
    );
    if (picked == null || picked == current || !mounted) return;
    var savedOnServer = false;
    if (api != null) {
      try {
        await api.changeCrewEmblem(picked.code);
        savedOnServer = true;
      } on ApiException catch (error) {
        if (!mounted) return;
        if (error.statusCode == 429) {
          _toast('엠블럼은 자주 바꿀 수 없어요. 잠시 뒤에 다시 바꿔 주세요.');
          return;
        }
        if (error.statusCode == 403) {
          _toast('아직 쓸 수 없는 테두리나 엠블럼이에요.');
          return;
        }
        if (error.statusCode != 404) {
          _toast('엠블럼을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.');
          return;
        }
      } catch (_) {
        if (!mounted) return;
        _toast('엠블럼을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.');
        return;
      }
    }
    await ref.read(crewEmblemProvider.notifier).choose(picked);
    _refreshCrews();
    if (!mounted) return;
    _toast(
      useRemote && !savedOnServer
          ? '이 폰에만 저장했어요. 서버에 크루가 생기면 함께 저장돼요.'
          : '크루 엠블럼을 바꿨어요.',
    );
  }

  void _refreshCrews() {
    ref.invalidate(myCrewProvider);
    ref.invalidate(crewListProvider);
  }

  Future<bool> _confirm(String title, String body, String yes) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(yes),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _onJoin(CrewSummary crew) async {
    final api = ref.read(crewApiProvider);
    if (api == null) return;
    if (!await _confirm('크루 가입', '"${crew.name}" 크루에 가입할까요?', '가입')) return;
    try {
      await api.joinCrew(crew.id);
      _refreshCrews();
      if (mounted) _toast('"${crew.name}" 크루에 가입했어요.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _toast(
        error.statusCode == 409
            ? '이미 다른 크루에 있거나 인원이 가득 찼어요.'
            : '가입하지 못했어요. 잠시 뒤 다시 해 주세요.',
      );
    } catch (_) {
      if (mounted) _toast('가입하지 못했어요. 잠시 뒤 다시 해 주세요.');
    }
  }

  Future<void> _onLeave(MyCrew mine) async {
    final api = ref.read(crewApiProvider);
    if (api == null) return;
    if (!await _confirm(
      '크루 나가기',
      '"${mine.crew.name}" 크루에서 나갈까요? 다시 가입할 수 있어요.',
      '나가기',
    )) {
      return;
    }
    try {
      await api.leaveCrew();
      _refreshCrews();
      if (mounted) _toast('크루에서 나왔어요.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _toast(
        error.statusCode == 400
            ? '크루장은 나갈 수 없어요.'
            : '나가지 못했어요. 잠시 뒤 다시 해 주세요.',
      );
    } catch (_) {
      if (mounted) _toast('나가지 못했어요. 잠시 뒤 다시 해 주세요.');
    }
  }

  Future<void> _onShowMembers(MyCrew mine) async {
    final api = ref.read(crewApiProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.srcTokens.colors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _CrewMembersSheet(
        mine: mine,
        onRole: api == null || !mine.isLeader
            ? null
            : (member, role) async {
                try {
                  await api.setCrewRole(member.uid, role);
                  _refreshCrews();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    _toast(
                      role == 'sub'
                          ? '${member.nickname}님을 부크루장으로 했어요.'
                          : '${member.nickname}님을 크루원으로 돌렸어요.',
                    );
                  }
                } catch (_) {
                  if (mounted) _toast('바꾸지 못했어요. 잠시 뒤 다시 해 주세요.');
                }
              },
      ),
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
    final c = context.srcTokens.colors;
    final localEmblem = ref.watch(crewEmblemProvider);
    final api = ref.watch(crewApiProvider);
    final mine = ref.watch(myCrewProvider).asData?.value;
    // 서버에 내 크루가 있으면 서버 값을, 없으면 이 폰에 저장한 값을 쓴다.
    final emblem = (mine == null ? null : CrewEmblem.parse(mine.crew.emblem)) ??
        localEmblem;
    final embedNav = DashboardTabNavigation.useEmbeddedBottomNav(context);
    final searching = _searchQuery.isNotEmpty;
    final scaffold = Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CrewPhotoHeader(
                    emblem: emblem,
                    crewName: mine?.crew.name ?? AppStrings.runningCrewMyCrewName,
                    onEmblem: _onChangeEmblem,
                    onHallOfFame: _onOpenHallOfFame,
                    onBack: searching || Navigator.of(context).canPop()
                        ? _onBack
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _CrewStat(
                              value: mine == null
                                  ? '45/50'
                                  : '${mine.crew.memberCount}/${mine.crew.maxMembers}',
                              label: '크루원',
                            ),
                            const SizedBox(width: 10),
                            _CrewStat(
                              value: mine == null
                                  ? '3,240km'
                                  : '${_format(mine.crew.totalDistanceKm.round())}km',
                              label: '누적 거리',
                            ),
                            const SizedBox(width: 10),
                            const _CrewStat(
                              value: AppStrings.runningCrewProgressValue,
                              label: '이번 주 대항전',
                              highlight: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _CrewActionLine(
                          index: '01',
                          title: '크루 관리',
                          subtitle: '공지 · 크루원 · 혜택 선물',
                          onTap: _onOpenCrewManager,
                        ),
                        if (mine != null)
                          _CrewActionLine(
                            index: '··',
                            title: '크루원 보기',
                            subtitle: '${mine.crew.memberCount}명 · 내 역할 ${_roleLabel(mine.role)}',
                            onTap: () => _onShowMembers(mine),
                          ),
                        if (mine != null && mine.canLeave)
                          _CrewActionLine(
                            index: '··',
                            title: '크루 나가기',
                            subtitle: '다시 가입할 수 있어요',
                            onTap: () => _onLeave(mine),
                          ),
                        _CrewActionLine(
                          index: '02',
                          title: '엠블럼 바꾸기',
                          subtitle: '틀 ${CrewEmblem.frames.length}가지 · '
                              '문양 ${CrewEmblem.glyphIds.length}가지 · '
                              '색 ${CrewEmblem.paletteColors.length}가지',
                          onTap: _onChangeEmblem,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppStrings.runningCrewProgressLabel,
                                style: storeText(14, c.ink, w: FontWeight.w700),
                              ),
                            ),
                            Text(
                              AppStrings.runningCrewProgressValue,
                              style:
                                  storeText(14, c.primary, w: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _completionRate,
                            minHeight: 8,
                            backgroundColor: c.outline,
                            color: c.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const StoreSectionLabel('다른 크루 찾기'),
                        _CrewSearchPill(onTap: _onSearch),
                        if (api != null) ...[
                          if (searching)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                '검색: "$_searchQuery"',
                                style: storeText(12, c.muted),
                              ),
                            ),
                          _RemoteCrewList(
                            query: _searchQuery.trim(),
                            canJoin: mine == null,
                            onJoin: _onJoin,
                          ),
                        ] else if (searching) ...[
                          const SizedBox(height: 10),
                          Text(
                            '검색: "$_searchQuery"',
                            style: storeText(12, c.muted),
                          ),
                          if (_myCrewMatches)
                            _MyCrewResultRow(
                              emblem: emblem,
                              onTap: _onOpenCrewManager,
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                '검색 결과가 없습니다.',
                                textAlign: TextAlign.center,
                                style: storeText(14, c.muted),
                              ),
                            ),
                        ],
                        const SizedBox(height: 16),
                        if (mine == null)
                          _CreateCrewTile(
                            busy: _isSubmitting,
                            onTap: _isSubmitting ? null : _onCreateCrew,
                          ),
                        const SizedBox(height: 6),
                        Text(
                          '보유 SHARE ${_format(wallet.shareBalance)}',
                          textAlign: TextAlign.center,
                          style: storeText(12, c.muted),
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
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: StorePillButton(
                label: AppStrings.runningCrewEnterRoom,
                onPressed: () => _onEnterRoom(),
              ),
            ),
          ),
        ],
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

  String _roleLabel(String role) => switch (role) {
        'leader' => '크루장',
        'sub' => '부크루장',
        _ => '크루원',
      };

  String _format(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
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

/// 맨 위 사진 카드. 사진 위에 명예의 전당·`CREW`, 아래 왼쪽에 엠블럼과 크루 이름.
/// 엠블럼을 누르면 바꾸는 창이 열린다.
class _CrewPhotoHeader extends StatelessWidget {
  const _CrewPhotoHeader({
    required this.emblem,
    required this.crewName,
    required this.onEmblem,
    required this.onHallOfFame,
    this.onBack,
  });

  final CrewEmblem emblem;
  final String crewName;
  final VoidCallback onEmblem;
  final VoidCallback onHallOfFame;
  final VoidCallback? onBack;

  static const photoAsset = 'assets/images/crew_crowd.jpg';
  static const emblemKey = Key('crew-header-emblem');

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    final top = MediaQuery.paddingOf(context).top;
    const radius = BorderRadius.vertical(bottom: Radius.circular(32));
    return SizedBox(
      height: 292 + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: Image.asset(
              photoAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(color: c.surface),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0xEE000000)],
                stops: [0.2, 1],
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 20,
            top: top + 8,
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    onPressed: onBack,
                  )
                else
                  const SizedBox(width: 12),
                InkWell(
                  onTap: onHallOfFame,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_outlined,
                            size: 18, color: c.warning),
                        const SizedBox(width: 6),
                        Text(
                          '명예의 전당',
                          style: storeText(13, c.warning, w: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                const StoreTag('CREW', color: Colors.white70),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                InkWell(
                  key: emblemKey,
                  onTap: onEmblem,
                  customBorder: const CircleBorder(),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CrewEmblemBadge(emblem: emblem, size: 80),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Icon(Icons.edit_rounded,
                            size: 13, color: c.onPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MY CREW',
                        style: storeText(11, c.primary,
                            w: FontWeight.w800, ls: 1.8),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        crewName,
                        style: storeText(24, Colors.white, w: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrewStat extends StatelessWidget {
  const _CrewStat({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: storeText(19, highlight ? c.primary : c.ink,
                    w: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: storeText(12, c.muted)),
          ],
        ),
      ),
    );
  }
}

/// `01  제목 / 부제  >` 모양의 한 줄. 아래 선만 긋는다.
class _CrewActionLine extends StatelessWidget {
  const _CrewActionLine({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String index;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.outline)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(index,
                  style: storeText(18, c.muted, w: FontWeight.w900)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: storeText(16, c.ink, w: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: storeText(13, c.muted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.muted),
          ],
        ),
      ),
    );
  }
}

/// 시안의 둥근 검색 줄. 누르면 기존 검색 창이 열린다.
class _CrewSearchPill extends StatelessWidget {
  const _CrewSearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: c.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: c.muted, size: 22),
            const SizedBox(width: 10),
            Text('크루 이름 검색', style: storeText(16, c.muted)),
          ],
        ),
      ),
    );
  }
}

/// 검색 결과 한 줄. 지금은 내 크루만 나온다.
class _MyCrewResultRow extends StatelessWidget {
  const _MyCrewResultRow({required this.emblem, required this.onTap});

  final CrewEmblem emblem;
  final VoidCallback onTap;

  static const rowKey = Key('crew-search-result');

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return InkWell(
      key: rowKey,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.outline)),
        ),
        child: Row(
          children: [
            CrewEmblemBadge(emblem: emblem, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.runningCrewMyCrewName,
                style: storeText(16, c.ink, w: FontWeight.w700),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.muted),
          ],
        ),
      ),
    );
  }
}

/// 시안의 "크루 만들기" 카드: 올리브 빛 면에 라임 + 버튼.
class _CreateCrewTile extends StatelessWidget {
  const _CreateCrewTile({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.primary.withValues(alpha: 0.22), c.surface],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '크루 만들기',
                    style: storeText(18, c.ink, w: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '50 DIA 또는 30,000 SHARE',
                    style: storeText(14, c.muted),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration:
                  BoxDecoration(color: c.primary, shape: BoxShape.circle),
              child: busy
                  ? Padding(
                      padding: const EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: c.onPrimary,
                      ),
                    )
                  : Icon(Icons.add_rounded, color: c.onPrimary, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}


/// 서버에서 받은 크루 목록. 내가 크루가 없으면 가입 버튼이 붙는다.
class _RemoteCrewList extends ConsumerWidget {
  const _RemoteCrewList({
    required this.query,
    required this.canJoin,
    required this.onJoin,
  });

  final String query;
  final bool canJoin;
  final Future<void> Function(CrewSummary crew) onJoin;

  static Key joinKey(String id) => Key('crew-join-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.srcTokens.colors;
    final crews = ref.watch(crewListProvider(query)).asData?.value ?? const [];
    if (crews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          query.isEmpty ? '아직 만들어진 크루가 없어요.' : '검색 결과가 없습니다.',
          textAlign: TextAlign.center,
          style: storeText(14, c.muted),
        ),
      );
    }
    return Column(
      children: [
        for (final crew in crews)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.outline),
              ),
              child: Row(
                children: [
                  CrewEmblemBadge(
                    emblem: CrewEmblem.parse(crew.emblem) ?? CrewEmblem.fallback,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crew.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: storeText(15, c.ink, w: FontWeight.w800),
                        ),
                        Text(
                          '${crew.memberCount}/${crew.maxMembers}명',
                          style: storeText(12, c.muted),
                        ),
                      ],
                    ),
                  ),
                  if (canJoin)
                    FilledButton(
                      key: joinKey(crew.id),
                      onPressed: crew.isFull ? null : () => onJoin(crew),
                      child: Text(crew.isFull ? '가득 참' : '가입'),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 크루원 목록. 크루장이면 크루원을 부크루장으로 올리거나 되돌릴 수 있다.
class _CrewMembersSheet extends StatelessWidget {
  const _CrewMembersSheet({required this.mine, required this.onRole});

  final MyCrew mine;
  final Future<void> Function(CrewMember member, String role)? onRole;

  static Key roleKey(String uid) => Key('crew-role-$uid');

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    String label(String role) => switch (role) {
          'leader' => '크루장',
          'sub' => '부크루장',
          _ => '크루원',
        };
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Text(
              '${mine.crew.name} · ${mine.members.length}명',
              style: storeText(20, c.ink, w: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            for (final m in mine.members)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m.nickname, style: storeText(15, c.ink, w: FontWeight.w700)),
                subtitle: Text(label(m.role), style: storeText(12, c.muted)),
                trailing: onRole == null || m.role == 'leader'
                    ? null
                    : TextButton(
                        key: roleKey(m.uid),
                        onPressed: () =>
                            onRole!(m, m.role == 'sub' ? 'member' : 'sub'),
                        child: Text(m.role == 'sub' ? '부크루장 해제' : '부크루장으로'),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
