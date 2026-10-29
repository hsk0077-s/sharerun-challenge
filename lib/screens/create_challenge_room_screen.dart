import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../core/api/api_exception.dart';
import '../core/challenge/challenge_entry_fee.dart';
import '../core/config/app_env.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/theme.dart';
import '../data/firebase/share_spend_transaction.dart';
import '../data/models/tournament_model.dart';
import '../data/repositories/tournament_repository.dart';
import '../features/challenge/providers/challenge_room_providers.dart';
import '../features/shop/widgets/store_look.dart';
import '../features/wallet/providers/wallet_provider.dart';
import '../features/wallet/widgets/share_insufficient_dialog.dart';
import '../features/tournaments/utils/sponsor_display.dart';

/// 유저 주도 챌린지 방 개설 화면 (Screen 8).
class CreateChallengeRoomScreen extends ConsumerStatefulWidget {
  const CreateChallengeRoomScreen({super.key});

  @override
  ConsumerState<CreateChallengeRoomScreen> createState() =>
      _CreateChallengeRoomScreenState();
}

class _CreateChallengeRoomScreenState
    extends ConsumerState<CreateChallengeRoomScreen> {
  final _titleController = TextEditingController();
  var _selectedDistanceKm = 3;
  var _isSubmitting = false;

  /// 1·2·3·5·10 + 10km 초과(15·20) 선택 칩.
  static const _distances = [1, 2, 3, 5, 10, 15, 20];

  int get _entryFee => ChallengeEntryFee.forDistanceKm(_selectedDistanceKm);

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String get _formattedFee {
    return _entryFee.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String get _payButtonLabel =>
      '$_formattedFee ${AppStrings.createRoomPayAndCreateSuffix}';

  void _selectDistance(int km) {
    setState(() => _selectedDistanceKm = km);
  }

  /// Firestore 원장 차감 + 방 인서트. 구글 IAP는 호출하지 않는다.
  Future<void> _onCreateRoom() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.createRoomTitleRequired)),
      );
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final wallet = ref.read(walletProvider.notifier);

    try {
      final uid = ref.read(authStateChangesProvider).asData?.value?.uid;
      final useRemote =
          !AppEnv.useLocalMockData && uid != null && uid.isNotEmpty;

      final TournamentModel room;
      if (!useRemote) {
        // 재화는 서버만 차감한다. 기기 안에서 차감하는 길은 데모 모드에만 둔다.
        if (!AppEnv.useLocalMockData) {
          if (mounted) setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인한 뒤에 다시 시도해 주세요.')),
          );
          return;
        }
        if (!_hasLocalShare(_entryFee)) {
          if (mounted) setState(() => _isSubmitting = false);
          await ShareInsufficientDialog.promptAndMaybeOpenBilling(context);
          return;
        }
        wallet.subtractShare(_entryFee);
        room = _localRoom(title: title, createdByUid: 'local-guest');
      } else {
        final created =
            await ref.read(securedActionApiClientProvider).createChallengeRoom(
                  title: title,
                  distanceKm: _selectedDistanceKm,
                );
        wallet.applyWalletSnapshot(
          shareBalance: created.wallet.shareBalance,
          diamondBalance: created.wallet.diamondBalance,
          valueBalance: created.wallet.valueTokenBalance,
        );
        room = TournamentModel(
          id: created.tournamentId,
          title: title,
          targetDistanceKm: _selectedDistanceKm.toDouble(),
          entryFeeShare: created.entryFeeShare,
          winnerRewardValue: 0,
          donationValue: 0,
          minParticipantsBep: TournamentRepository.defaultBepForDistance(
            _selectedDistanceKm,
          ),
          maxParticipants: 400,
          participantCount: 1,
          requiredTier: 1,
          status: TournamentStatus.recruiting,
          sponsorName: operatorSponsorName,
          sponsorBillboardMessages: const [],
        );
      }

      ref.read(localUserRoomsProvider.notifier).prepend(room);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$title" 대회가 열렸어요.')),
      );
      AppRouteNav.pop(context);
    } on InsufficientShareException {
      if (mounted) setState(() => _isSubmitting = false);
      if (!mounted) return;
      await ShareInsufficientDialog.promptAndMaybeOpenBilling(context);
    } on ApiException {
      if (mounted) setState(() => _isSubmitting = false);
      if (!mounted) return;
      await ShareInsufficientDialog.promptAndMaybeOpenBilling(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('대회 열기에 실패했어요: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _hasLocalShare(int amount) {
    return ref.read(walletProvider).shareBalance >= amount;
  }

  TournamentModel _localRoom({
    required String title,
    required String createdByUid,
  }) {
    final id =
        'user-room-${DateTime.now().millisecondsSinceEpoch}-$createdByUid';
    return TournamentModel(
      id: id,
      title: title,
      targetDistanceKm: _selectedDistanceKm.toDouble(),
      entryFeeShare: _entryFee,
      winnerRewardValue: 0,
      donationValue: 0,
      minParticipantsBep: TournamentRepository.defaultBepForDistance(
        _selectedDistanceKm,
      ),
      maxParticipants: 400,
      participantCount: 1,
      requiredTier: 1,
      status: TournamentStatus.recruiting,
      sponsorName: operatorSponsorName,
      sponsorBillboardMessages: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: c.ink,
                    iconSize: 20,
                    onPressed: () => AppRouteNav.pop(context),
                  ),
                  const StoreTag('CHALLENGE'),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.createRoomScreenTitle,
                      style: storeText(28, c.ink, w: FontWeight.w900, h: 1.25),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.createRoomScreenSubtitle,
                      style: storeText(14, c.muted),
                    ),
                    const SizedBox(height: 12),
                    StoreSectionLabel(AppStrings.createRoomTitleSection),
                    Text(
                      AppStrings.createRoomTitleHint,
                      style: storeText(13, c.muted),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _titleController,
                      style: storeText(16, c.ink, w: FontWeight.w700),
                      cursorColor: c.primary,
                      decoration: InputDecoration(
                        hintText: AppStrings.createRoomTitlePlaceholder,
                        hintStyle: storeText(15, c.muted),
                        filled: true,
                        fillColor: c.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        border: _fieldBorder(c.outline),
                        enabledBorder: _fieldBorder(c.outline),
                        focusedBorder: _fieldBorder(c.primary, width: 1.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StoreSectionLabel(
                        AppStrings.createRoomDistanceSection),
                    Text(
                      AppStrings.createRoomDistanceHint,
                      style: storeText(13, c.muted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _distances.map((km) {
                        return _DistanceChip(
                          label: '${km}km',
                          selected: _selectedDistanceKm == km,
                          onTap: () => _selectDistance(km),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    StoreSectionLabel(
                        AppStrings.createRoomEntryFeeSection),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: c.outline),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_formattedFee SHARE',
                                style: storeText(32, c.ink, w: FontWeight.w900),
                              ),
                              const SizedBox(width: 10),
                              const _ShareCoinIcon(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text.rich(
                            TextSpan(
                              style: storeText(12, c.muted, h: 1.5),
                              children: [
                                TextSpan(
                                  text: AppStrings.createRoomFeeWarningRed,
                                  style: storeText(12, c.warning, h: 1.5),
                                ),
                                TextSpan(
                                  text: AppStrings.createRoomFeeWarningGrey,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _isSubmitting
                  ? Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(29),
                      ),
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: c.onPrimary,
                        ),
                      ),
                    )
                  : StorePillButton(
                      label: _payButtonLabel,
                      onPressed: _onCreateRoom,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: BorderSide(color: color, width: width),
      );
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Material(
      color: selected ? c.primary : c.surface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? c.primary : c.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            label,
            style: storeText(
              15,
              selected ? c.onPrimary : c.muted,
              w: FontWeight.w800,
            ),
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
    final c = context.srcTokens.colors;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: c.warning, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text('S', style: storeText(18, c.onPrimary, w: FontWeight.w900)),
    );
  }
}
