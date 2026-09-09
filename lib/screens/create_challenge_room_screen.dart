import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers/app_providers.dart';
import '../core/challenge/challenge_entry_fee.dart';
import '../core/config/app_env.dart';
import '../core/navigation/app_route_nav.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';
import '../data/firebase/share_spend_transaction.dart';
import '../data/models/tournament_model.dart';
import '../data/repositories/tournament_repository.dart';
import '../features/challenge/providers/challenge_room_providers.dart';
import '../features/wallet/providers/wallet_provider.dart';
import '../features/wallet/widgets/share_insufficient_dialog.dart';

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

  /// 1·3·5·10 + 10km 초과(15·20) 선택 칩.
  static const _distances = [1, 3, 5, 10, 15, 20];

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
        const SnackBar(content: Text(AppStrings.createRoomTitleRequired)),
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

      if (!useRemote) {
        if (!_hasLocalShare(_entryFee)) {
          if (mounted) setState(() => _isSubmitting = false);
          await ShareInsufficientDialog.promptAndMaybeOpenBilling(context);
          return;
        }
        wallet.subtractShare(_entryFee);
      }

      final room = await _insertChallengeRoom(
        title: title,
        createdByUid: uid ?? 'local-guest',
        persistRemote: useRemote,
      );

      if (useRemote) {
        wallet.subtractShare(_entryFee);
      }

      ref.read(localUserRoomsProvider.notifier).prepend(room);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$title" 방이 개설되었습니다.')),
      );
      AppRouteNav.pop(context);
    } on InsufficientShareException {
      if (mounted) setState(() => _isSubmitting = false);
      if (!mounted) return;
      await ShareInsufficientDialog.promptAndMaybeOpenBilling(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('방 개설 실패: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _hasLocalShare(int amount) {
    return ref.read(walletProvider).shareBalance >= amount;
  }

  Future<TournamentModel> _insertChallengeRoom({
    required String title,
    required String createdByUid,
    required bool persistRemote,
  }) async {
    if (!persistRemote) {
      return _localRoom(title: title, createdByUid: createdByUid);
    }
    return ref.read(tournamentRepositoryProvider).createUserChallengeRoom(
          title: title,
          distanceKm: _selectedDistanceKm,
          entryFeeShare: _entryFee,
          createdByUid: createdByUid,
        );
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
      winnerRewardValue: (_entryFee * 0.4).round(),
      donationValue: (_entryFee * 0.2).round(),
      minParticipantsBep: TournamentRepository.defaultBepForDistance(
        _selectedDistanceKm,
      ),
      maxParticipants: 400,
      participantCount: 1,
      requiredTier: 1,
      status: TournamentStatus.recruiting,
      sponsorName: 'UNICEF',
      sponsorBillboardMessages: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CreateRoomHeader(onBack: () => AppRouteNav.pop(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    8,
                    AppShapes.termsHorizontalPadding,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.createRoomTitleSection,
                              style: AppTextStyles.agreementLabel.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppStrings.createRoomTitleHint,
                              style: AppTextStyles.caption.copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _titleController,
                              style: AppTextStyles.inputText,
                              decoration: InputDecoration(
                                hintText: AppStrings.createRoomTitlePlaceholder,
                                hintStyle: AppTextStyles.inputHint,
                                filled: true,
                                fillColor: AppColors.surfaceWhite,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppShapes.inputRadius,
                                  ),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppShapes.inputRadius,
                                  ),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppShapes.inputRadius,
                                  ),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryMint,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _WhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.createRoomDistanceSection,
                              style: AppTextStyles.agreementLabel.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppStrings.createRoomDistanceHint,
                              style: AppTextStyles.caption.copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _distances.map((km) {
                                final selected = _selectedDistanceKm == km;
                                return _DistanceChip(
                                  label: '${km}km',
                                  selected: selected,
                                  onTap: () => _selectDistance(km),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _WhiteCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              AppStrings.createRoomEntryFeeSection,
                              style: AppTextStyles.agreementLabel.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$_formattedFee SHARE',
                                  style: AppTextStyles.header1.copyWith(
                                    fontSize: 32,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const _ShareCoinIcon(),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text.rich(
                              TextSpan(
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(
                                    text: AppStrings.createRoomFeeWarningRed,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                    ),
                                  ),
                                  TextSpan(
                                    text: AppStrings.createRoomFeeWarningGrey,
                                    style: const TextStyle(
                                      color: AppColors.textGrey,
                                    ),
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
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppShapes.termsHorizontalPadding,
                    8,
                    AppShapes.termsHorizontalPadding,
                    12,
                  ),
                  child: Material(
                    color: AppColors.primaryMint,
                    borderRadius: BorderRadius.circular(AppShapes.cardRadius),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _isSubmitting ? null : _onCreateRoom,
                      child: SizedBox(
                        width: double.infinity,
                        height: AppShapes.buttonHeight,
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: AppColors.textWhite,
                                  ),
                                )
                              : Text(
                                  _payButtonLabel,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateRoomHeader extends StatelessWidget {
  const _CreateRoomHeader({required this.onBack});

  final VoidCallback onBack;

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              children: [
                Text(
                  AppStrings.createRoomScreenTitle,
                  style: AppTextStyles.header1.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.createRoomScreenSubtitle,
                  style: AppTextStyles.termsSubtitle.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
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
    return Material(
      color: selected ? AppColors.primaryMint : AppColors.borderLight,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: AppTextStyles.buttonText.copyWith(
              fontSize: 13,
              color: selected ? AppColors.textWhite : AppColors.textGrey,
              fontWeight: FontWeight.w600,
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
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.progressYellow,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'S',
        style: AppTextStyles.buttonText.copyWith(
          color: AppColors.textWhite,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
