import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../core/api/api_exception.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/crew/crew_membership.dart';
import '../features/shop/providers/server_shop_inventory_provider.dart';
import '../features/wallet/providers/wallet_provider.dart';
import '../l10n/remaining_surface.dart';

/// 크루 방장 관리 대시보드 (Screen 19). 크루 정보와 크루원은 서버 값이다.
class CrewManagerScreen extends ConsumerStatefulWidget {
  const CrewManagerScreen({super.key});

  @override
  ConsumerState<CrewManagerScreen> createState() => _CrewManagerScreenState();
}

class _CrewManagerScreenState extends ConsumerState<CrewManagerScreen> {
  static const _royalBlue = AppColors.nightLime;
  static const _saveNavy = AppColors.nightLime;

  static const _giftDiaPerMember = 30;

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

  void _refresh() => ref.invalidate(myCrewProvider);

  Future<bool> _confirm(String title, String body, String okLabel) async {
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
            child: Text(okLabel),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _onPreparing() async {
    _toast(RemainingSurface.tr(
      context,
      'crew_manager.toast',
      '아직 열리지 않았어요. 준비되면 알려드릴게요.',
    ));
  }

  Future<void> _onRename(MyCrew mine) async {
    final api = ref.read(crewApiProvider);
    if (api == null) return;
    final cost = mine.crew.renameCostDia;
    final controller = TextEditingController(text: mine.crew.name);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(RemainingSurface.tr(
          ctx,
          'crew_manager.dialog',
          '크루 이름 변경',
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              maxLength: 20,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            Text(
              cost == 0
                  ? RemainingSurface.tr(
                      ctx,
                      'crew_manager.body',
                      '처음 한 번은 무료예요.',
                    )
                  : RemainingSurface.tr(
                      ctx,
                      'crew_manager.button',
                      '이름을 바꿀 때마다 $cost DIA가 들어요.',
                      {'cost': cost},
                    ),
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(RemainingSurface.tr(
              ctx,
              'crew_manager.button.2',
              '저장',
            )),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || next == null || next.isEmpty || next == mine.crew.name) {
      return;
    }
    if (cost > 0 &&
        !await _confirm(
          RemainingSurface.tr(
            context,
            'crew_manager.body.2',
            '이름 바꾸기',
          ),
          RemainingSurface.tr(
            context,
            'crew_manager.body.3',
            '"$next"(으)로 바꾸면 $cost DIA가 들어요. 보너스 DIA를 먼저 써요.',
            {'next': next, 'cost': cost},
          ),
          RemainingSurface.tr(
            context,
            'crew_manager.body.4',
            '$cost DIA 내고 바꾸기',
            {'cost': cost},
          ),
        )) {
      return;
    }
    try {
      final balance = await api.renameCrew(next);
      if (!mounted) return;
      if (balance != null) {
        ref.read(walletProvider.notifier).applyWalletSnapshot(
              diamondBalance: balance,
            );
      }
      _refresh();
      _toast(RemainingSurface.tr(
        context,
        'crew_manager.toast.2',
        '크루 이름을 "$next"(으)로 바꿨어요.',
        {'next': next},
      ));
    } on ApiException catch (error) {
      if (!mounted) return;
      _toast(switch (error.statusCode) {
        400 => RemainingSurface.tr(
            context,
            'crew_manager.toast.3',
            'DIA가 모자라거나 쓸 수 없는 이름이에요.',
          ),
        403 => RemainingSurface.tr(
            context,
            'crew_manager.toast.4',
            '크루장만 이름을 바꿀 수 있어요.',
          ),
        _ => RemainingSurface.tr(
            context,
            'crew_manager.toast.5',
            '이름을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.',
          ),
      });
    } catch (_) {
      if (mounted) {
        _toast(RemainingSurface.tr(
          context,
          'crew_manager.toast.5',
          '이름을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.',
        ));
      }
    }
  }

  Future<void> _onExpandMembers(MyCrew mine) async {
    final api = ref.read(crewApiProvider);
    final step = mine.crew.expansion;
    if (api == null || step == null) return;
    if (step.atMax) {
      _toast(RemainingSurface.tr(
        context,
        'crew_manager.toast.6',
        '인원 한도가 최대(${mine.crew.maxMembers}명)예요.',
        {'mine.crew.maxMembers': mine.crew.maxMembers},
      ));
      return;
    }
    if (!step.canBuy) {
      _toast(RemainingSurface.tr(
        context,
        'crew_manager.toast.7',
        '자리를 모두 채우면 더 늘릴 수 있어요. (${mine.crew.maxMembers}명)',
        {'mine.crew.maxMembers': mine.crew.maxMembers},
      ));
      return;
    }
    if (!await _confirm(
      RemainingSurface.tr(
        context,
        'crew_manager.toast.8',
        '인원 한도 확장',
      ),
      RemainingSurface.tr(
        context,
        'crew_manager.toast.9',
        '크루 인원 한도를 ${step.add}명 늘려요. ${step.costDia} DIA가 들고, 보너스 DIA를 먼저 써요.',
        {'step.add': step.add, 'step.costDia': step.costDia},
      ),
      RemainingSurface.tr(
        context,
        'crew_manager.toast.10',
        '${step.costDia} DIA 내고 늘리기',
        {'step.costDia': step.costDia},
      ),
    )) {
      return;
    }
    try {
      final result = await api.expandCrew();
      if (!mounted) return;
      if (result.diamondBalance != null) {
        ref.read(walletProvider.notifier).applyWalletSnapshot(
              diamondBalance: result.diamondBalance,
            );
      }
      _refresh();
      _toast(RemainingSurface.tr(
        context,
        'crew_manager.toast.11',
        '인원 한도가 ${result.maxMembers}명이 됐어요.',
        {'result.maxMembers': result.maxMembers},
      ));
    } on ApiException catch (error) {
      if (!mounted) return;
      _toast(switch (error.statusCode) {
        400 => 'DIA가 부족합니다. 상점에서 구매해 주세요.',
        403 => RemainingSurface.tr(
            context,
            'crew_manager.toast.12',
            '크루장만 늘릴 수 있어요.',
          ),
        409 => RemainingSurface.tr(
            context,
            'crew_manager.toast.13',
            '자리를 모두 채워야 하거나 이미 최대예요.',
          ),
        _ => RemainingSurface.tr(
            context,
            'crew_manager.toast.14',
            '인원 한도를 늘리지 못했어요. 잠시 뒤 다시 해 주세요.',
          ),
      });
    } catch (_) {
      if (mounted) {
        _toast(RemainingSurface.tr(
          context,
          'crew_manager.toast.14',
          '인원 한도를 늘리지 못했어요. 잠시 뒤 다시 해 주세요.',
        ));
      }
    }
  }

  Future<void> _onCheerFlag() async {
    try {
      await ref.read(securedActionApiClientProvider).useShopItem(
            ServerShopInventory.crewCheerId,
          );
      if (!mounted) return;
      _toast(RemainingSurface.tr(
        context,
        'crew_manager.toast.15',
        '크루 응원 깃발을 걸었습니다. 오늘 대회 SHARE 보상이 10% 늘어납니다.',
      ));
    } on ApiException catch (error) {
      if (!mounted) return;
      _toast(error.userMessage);
    } catch (_) {
      if (!mounted) return;
      _toast(RemainingSurface.tr(
        context,
        'crew_manager.toast.16',
        '응원 깃발을 걸지 못했습니다.',
      ));
    }
  }

  /// [member]가 null이면 나를 뺀 크루원 전체에게 준다.
  Future<void> _onGift(MyCrew mine, {CrewMember? member}) async {
    final api = ref.read(crewApiProvider);
    if (api == null) return;
    final count = member == null
        ? mine.members.where((m) => m.role != 'leader').length
        : 1;
    if (count == 0) {
      _toast(RemainingSurface.tr(
        context,
        'crew_manager.toast.17',
        '선물을 받을 크루원이 없어요.',
      ));
      return;
    }
    final cost = count * _giftDiaPerMember;
    final who = member == null
        ? RemainingSurface.tr(
            context,
            'crew_manager.toast.18',
            '크루원 $count명 모두',
            {'count': count},
          )
        : RemainingSurface.tr(
            context,
            'crew_manager.toast.19',
            '${member.nickname}님',
            {'member.nickname': member.nickname},
          );
    if (!await _confirm(
      RemainingSurface.tr(
        context,
        'crew_manager.toast.20',
        '심폐소생권·세이프가드 선물',
      ),
      RemainingSurface.tr(
        context,
        'crew_manager.toast.21',
        '$who에게 심폐소생권과 세이프가드를 하나씩 보내요. 한 명당 $_giftDiaPerMember DIA, 모두 $cost DIA가 들고 보너스 DIA를 먼저 써요.',
        {'who': who, '_giftDiaPerMember': _giftDiaPerMember, 'cost': cost},
      ),
      RemainingSurface.tr(
        context,
        'crew_manager.body.5',
        '$cost DIA 내고 보내기',
        {'cost': cost},
      ),
    )) {
      return;
    }
    try {
      final result = await api.giftCrewItems(targetUid: member?.uid ?? '');
      if (!mounted) return;
      if (result.diamondBalance != null) {
        ref.read(walletProvider.notifier).applyWalletSnapshot(
              diamondBalance: result.diamondBalance,
            );
      }
      _toast(RemainingSurface.tr(
        context,
        'crew_manager.toast.22',
        '${result.recipients}명의 보관함에 선물을 넣었어요. (−$cost DIA)',
        {'result.recipients': result.recipients, 'cost': cost},
      ));
    } on ApiException catch (error) {
      if (!mounted) return;
      _toast(switch (error.statusCode) {
        400 => 'DIA가 부족합니다. 상점에서 구매해 주세요.',
        403 => RemainingSurface.tr(
            context,
            'crew_manager.toast.23',
            '크루장만 선물할 수 있어요.',
          ),
        404 => RemainingSurface.tr(
            context,
            'crew_manager.toast.24',
            '그 크루원을 찾지 못했어요.',
          ),
        _ => RemainingSurface.tr(
            context,
            'crew_manager.toast.25',
            '선물을 보내지 못했어요. 잠시 뒤 다시 해 주세요.',
          ),
      });
    } catch (_) {
      if (mounted) {
        _toast(RemainingSurface.tr(
          context,
          'crew_manager.toast.25',
          '선물을 보내지 못했어요. 잠시 뒤 다시 해 주세요.',
        ));
      }
    }
  }

  Future<void> _onSetRole(CrewMember member, String role) async {
    final api = ref.read(crewApiProvider);
    if (api == null) return;
    try {
      await api.setCrewRole(member.uid, role);
      if (!mounted) return;
      _refresh();
      _toast(
        role == 'sub'
            ? RemainingSurface.tr(
                context,
                'crew_manager.toast.26',
                '${member.nickname}님을 부방장으로 임명했어요.',
                {'member.nickname': member.nickname},
              )
            : RemainingSurface.tr(
                context,
                'crew_manager.toast.27',
                '${member.nickname}님을 크루원으로 돌렸어요.',
                {'member.nickname': member.nickname},
              ),
      );
    } catch (_) {
      if (mounted) {
        _toast(RemainingSurface.tr(
          context,
          'crew_manager.toast.28',
          '바꾸지 못했어요. 잠시 뒤 다시 해 주세요.',
        ));
      }
    }
  }

  Future<void> _onKick(CrewMember member) async {
    final api = ref.read(crewApiProvider);
    if (api == null) return;
    if (!await _confirm(
      RemainingSurface.tr(
        context,
        'crew_manager.toast.29',
        '크루원 내보내기',
      ),
      RemainingSurface.tr(
        context,
        'crew_manager.toast.30',
        '${member.nickname}님을 크루에서 내보낼까요?',
        {'member.nickname': member.nickname},
      ),
      RemainingSurface.tr(
        context,
        'crew_manager.toast.31',
        '내보내기',
      ),
    )) {
      return;
    }
    try {
      await api.kickCrewMember(member.uid);
      if (!mounted) return;
      _refresh();
      _toast(RemainingSurface.tr(
        context,
        'crew_manager.toast.32',
        '${member.nickname}님을 내보냈어요.',
        {'member.nickname': member.nickname},
      ));
    } catch (_) {
      if (mounted) {
        _toast(RemainingSurface.tr(
          context,
          'crew_manager.toast.33',
          '내보내지 못했어요. 잠시 뒤 다시 해 주세요.',
        ));
      }
    }
  }

  static String _expandLabel(CrewSummary crew) {
    final step = crew.expansion;
    if (step == null) {
      return RemainingSurface.trNow(
        'crew_manager.toast.8',
        '인원 한도 확장',
      );
    }
    if (step.atMax) {
      return RemainingSurface.trNow(
        'crew_manager.toast.34',
        '인원 한도 최대 (${crew.maxMembers}명)',
        {'crew.maxMembers': crew.maxMembers},
      );
    }
    final base = RemainingSurface.trNow(
      'crew_manager.body.6',
      '+${step.add}명 인원 한도 확장하기 (${step.costDia} DIA)',
      {'step.add': step.add, 'step.costDia': step.costDia},
    );
    return step.canBuy
        ? base
        : RemainingSurface.trNow(
            'crew_manager.body.7',
            '$base · ${crew.maxMembers}명을 모두 채우면 열려요',
            {'base': base, 'crew.maxMembers': crew.maxMembers},
          );
  }

  Widget _scaffold(Widget body) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
        child: SafeArea(bottom: false, child: body),
      ),
    );
  }

  Widget _message(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppShapes.termsHorizontalPadding,
        8,
        AppShapes.termsHorizontalPadding,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CrewManagerHeader(onBack: () => AppRouteNav.pop(context)),
          const SizedBox(height: 24),
          _ManagerWhiteCard(child: Text(text, style: AppTextStyles.caption)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final async = ref.watch(myCrewProvider);
    if (async.isLoading && async.asData == null) {
      return _scaffold(const Center(child: CircularProgressIndicator()));
    }
    final mine = async.asData?.value;
    if (mine == null) {
      return _scaffold(_message(RemainingSurface.tr(
        context,
        'crew_manager.body.8',
        '크루 정보를 불러오지 못했어요. 크루에 들어 있는지, 네트워크가 연결됐는지 확인해 주세요.',
      )));
    }
    if (!mine.isManager) {
      return _scaffold(_message(RemainingSurface.tr(
        context,
        'crew_manager.body.9',
        '크루장과 부크루장만 관리할 수 있어요.',
      )));
    }
    final subs = [
      for (final m in mine.members)
        if (m.role == 'sub') m.nickname,
    ];
    final limit = mine.crew.maxMembers;
    final count = mine.members.length;
    return _scaffold(
      Column(
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
                    RemainingSurface.tr(
                      context,
                      'crew_manager.body.10',
                      '보유 DIA ${wallet.diamondBalance} · SHARE ${wallet.shareBalance}',
                      {
                        'wallet.diamondBalance': wallet.diamondBalance,
                        'wallet.shareBalance': wallet.shareBalance,
                      },
                    ),
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
                                mine.crew.name,
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
                        if (subs.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '부방장: ${subs.join(', ')}',
                            style: AppTextStyles.caption.copyWith(fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _RoyalBlueButton(
                          label: RemainingSurface.tr(
                            context,
                            'crew_manager.body.12',
                            '📢 전체 공지 푸시 (준비 중)',
                          ),
                          onTap: _onPreparing,
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
                  if (mine.isLeader) ...[
                    _ManagerWhiteCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              RemainingSurface.tr(
                                context,
                                'crew_manager.body.13',
                                '크루 이름',
                              ),
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.agreementLabel.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Text('💎', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          _RoyalBlueChip(
                            label: mine.crew.renameCostDia == 0
                                ? RemainingSurface.tr(
                                    context,
                                    'crew_manager.body.14',
                                    '이름 변경 (첫 1회 무료)',
                                  )
                                : RemainingSurface.tr(
                                    context,
                                    'crew_manager.body.15',
                                    '이름 변경 (${mine.crew.renameCostDia} DIA)',
                                    {
                                      'mine.crew.renameCostDia':
                                          mine.crew.renameCostDia,
                                    },
                                  ),
                            onTap: () => _onRename(mine),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _ManagerWhiteCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          RemainingSurface.tr(
                            context,
                            'crew_manager.body.16',
                            '보관함 아이템',
                          ),
                          style: AppTextStyles.agreementLabel.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (mine.isLeader) ...[
                          _RoyalBlueButton(
                            label: RemainingSurface.tr(
                              context,
                              'crew_manager.body.17',
                              '🎁 크루원 전체에게 심폐소생권·세이프가드 선물 (1인당 $_giftDiaPerMember DIA)',
                              {'_giftDiaPerMember': _giftDiaPerMember},
                            ),
                            subtitle: RemainingSurface.tr(
                              context,
                              'crew_manager.body.18',
                              '내가 아닌 크루원의 보관함에 하나씩 들어가요. 한 명에게만 줄 때는 아래 팀원 목록에서 골라요.',
                            ),
                            onTap: () => _onGift(mine),
                          ),
                        ],
                        const SizedBox(height: 10),
                        _RoyalBlueButton(
                          label: RemainingSurface.tr(
                            context,
                            'crew_manager.body.19',
                            '🚩 크루 응원 깃발 (15 DIA, 하루 1회)',
                          ),
                          onTap: _onCheerFlag,
                        ),
                        const SizedBox(height: 10),
                        _RoyalBlueButton(
                          label: RemainingSurface.tr(
                            context,
                            'crew_manager.body.20',
                            '🛡️ 크루 대항전 예치금 대납 (준비 중)',
                          ),
                          onTap: _onPreparing,
                        ),
                        const SizedBox(height: 10),
                        _RoyalBlueButton(
                          label: RemainingSurface.tr(
                            context,
                            'crew_manager.body.21',
                            '🎉 크루 전용 챌린지 패스 & 스킨 (준비 중)',
                          ),
                          onTap: _onPreparing,
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
                          RemainingSurface.tr(
                            context,
                            'crew_manager.body.22',
                            '소속 팀원 관리 ($count / $limit명)',
                            {'count': count, 'limit': limit},
                          ),
                          style: AppTextStyles.agreementLabel.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: limit <= 0
                                ? 0.0
                                : (count / limit).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: AppColors.borderLight,
                            color: AppColors.primaryMintDark,
                          ),
                        ),
                        if (mine.isLeader) ...[
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: () => _onExpandMembers(mine),
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('💎',
                                    style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _expandLabel(mine.crew),
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
                        ],
                        const SizedBox(height: 16),
                        if (mine.members.isEmpty)
                          Text(
                            RemainingSurface.tr(
                              context,
                              'crew_manager.body.23',
                              '소속 팀원이 없습니다.',
                            ),
                            style: AppTextStyles.caption,
                          )
                        else
                          ...mine.members.map(
                            (member) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _MemberRow(
                                name: member.nickname,
                                role: member.role,
                                canAppoint: mine.isLeader &&
                                    member.role != 'leader',
                                canKick: member.role != 'leader' &&
                                    (mine.isLeader || member.role == 'member'),
                                onAppoint: () => _onSetRole(
                                  member,
                                  member.role == 'sub' ? 'member' : 'sub',
                                ),
                                onKick: () => _onKick(member),
                                canGift: mine.isLeader && member.role != 'leader',
                                onGift: () => _onGift(mine, member: member),
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
                    onPressed: () => AppRouteNav.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _saveNavy,
                      foregroundColor: AppColors.nightOnLime,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppShapes.cardRadius,
                        ),
                      ),
                    ),
                    child: Text(
                      '닫기',
                      style: AppTextStyles.buttonText.copyWith(
                        color: AppColors.nightOnLime,
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
      color: AppColors.nightLime,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.nightOnLime,
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
      color: AppColors.nightLime,
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
                  color: AppColors.nightOnLime,
                  fontSize: 13,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.nightOnLime,
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
    required this.role,
    required this.canAppoint,
    required this.canKick,
    required this.onAppoint,
    required this.onKick,
    required this.canGift,
    required this.onGift,
  });

  final String name;
  final String role;
  final bool canAppoint;
  final bool canKick;
  final VoidCallback onAppoint;
  final VoidCallback onKick;
  final bool canGift;
  final VoidCallback onGift;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      'leader' => RemainingSurface.tr(
          context,
          'crew_manager.body.24',
          '$name (방장)',
          {'name': name},
        ),
      'sub' => RemainingSurface.tr(
          context,
          'crew_manager.body.25',
          '$name (부방장)',
          {'name': name},
        ),
      _ => name,
    };
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
            label,
            style: AppTextStyles.agreementLabel.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        if (canGift)
          TextButton(
            onPressed: onGift,
            child: Text(
              RemainingSurface.tr(
                context,
                'crew_manager.button.3',
                '선물',
              ),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.nightLime,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        if (canAppoint)
          TextButton(
            onPressed: onAppoint,
            child: Text(
              role == 'sub'
                  ? RemainingSurface.tr(
                      context,
                      'crew_manager.button.4',
                      '부방장 해제',
                    )
                  : AppStrings.crewManagerAppointVice,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.nightLime,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        if (canKick)
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
