import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/src_theme.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/onboarding/src_onboarding_controller.dart';
import '../features/profile/user_profile_notifier.dart';
import '../features/profile/widgets/tier_circle_badge.dart';
import '../features/shop/cosmetics_catalog.dart';
import '../features/shop/providers/server_shop_inventory_provider.dart';
import '../features/pedometer/walking_challenge_share.dart';
import '../features/run_result/run_finish_image_share.dart';
import '../features/run_result/run_finish_share_card.dart';
import '../features/run_result/run_finish_share_flow.dart';
import '../features/run_result/run_finish_share_targets.dart';
import '../features/run_result/run_finish_theme_store.dart';

const _nightFlat = LinearGradient(
  colors: [AppColors.nightBg, AppColors.nightBg],
);

String _formatRunClock(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = safe ~/ 60;
  final remain = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${remain.toString().padLeft(2, '0')}';
}

String _formatRunPace(double distanceKm, int durationSeconds) {
  if (distanceKm <= 0 || durationSeconds <= 0) return '--:-- /km';
  final totalSeconds = (durationSeconds / distanceKm).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')} /km';
}

/// 온보딩 플로우 기록 결과 화면 (Screen 11).
class OnboardingRunResultScreen extends ConsumerStatefulWidget {
  const OnboardingRunResultScreen({
    super.key,
    this.distanceKm = 0,
    this.durationSeconds = 0,
    this.valueTokenReward = 0,
    this.serverConfirmed = false,
    this.serverAnswered = false,
    this.companyDonationWon = 0,
    this.donationCounted = false,
    this.donationReason = '',
    this.donationCapReached = false,
    this.splitPaces,
    this.averageHeartRate,
  });

  /// Tracked kilometres passed through server validation.
  final double distanceKm;

  /// Tracked seconds passed through server validation.
  final int durationSeconds;

  /// `value_token_reward` from POST /actions/runs/validate.
  final int valueTokenReward;

  /// True only after the server marked the run verified.
  final bool serverConfirmed;

  /// True after POST /actions/runs/validate returned, including a rejection.
  final bool serverAnswered;

  /// `company_donation_won` from the validate response. Not kilometres × 100.
  final int companyDonationWon;

  /// `donation_counted` from the validate response.
  final bool donationCounted;

  /// Why the server did not count a donation. Empty when it did.
  final String donationReason;

  /// `donation_cap_reached` from the validate response.
  final bool donationCapReached;

  /// 기기 안에서 만든 1km 구간 페이스. 서버로 보내거나 저장하지 않는다.
  final List<int>? splitPaces;

  /// 평균 심박. 없으면 카드에 넣지 않는다.
  final int? averageHeartRate;

  static const photoGalleryKey = Key('run-finish-photo-gallery');
  static const tierBadgeSwitchKey = Key('run-finish-tier-badge-switch');
  static const photoCameraKey = Key('run-finish-photo-camera');
  static const photoCameraLabel = '사진 찍기';
  static const photoGalleryLabel = '갤러리에서 고르기';

  /// Test hook. Production uses [ImagePicker] and keeps the bytes in memory.
  static Future<Uint8List?> Function(ImageSource source)? debugPickPhoto;

  @override
  ConsumerState<OnboardingRunResultScreen> createState() =>
      _OnboardingRunResultScreenState();
}

class _OnboardingRunResultScreenState
    extends ConsumerState<OnboardingRunResultScreen>
    with WidgetsBindingObserver {
  var _styleIndex = 0;
  var _themeReady = false;
  var _sharingImage = false;
  var _armResume = false;
  var _nextIndex = 0;
  List<RunFinishShareTarget> _queue = const [];
  File? _poster;

  /// 카드에 동물 티어·천사 등급 원을 넣을지. 공유할 때만 빼는 용도라 저장하지 않는다.
  var _showTierBadges = true;

  /// Scenery for this visit only. Never saved, never uploaded.
  ImageProvider? _photo;
  var _usingPhoto = false;
  final _finishedOn = DateTime.now();
  final _styleController = PageController(viewportFraction: 0.8);
  final _cardKey = GlobalKey();

  String get _distanceLabel => widget.distanceKm.toStringAsFixed(2);

  String get _timeLabel => _formatRunClock(widget.durationSeconds);

  String get _paceLabel =>
      _formatRunPace(widget.distanceKm, widget.durationSeconds);

  int? get _serverDonationWon =>
      widget.serverConfirmed && widget.donationCounted
          ? widget.companyDonationWon
          : null;

  String get _donationStatus {
    final line = runFinishDonationLine(_serverDonationWon);
    if (line == null) return runFinishDonationSkippedLine(widget.donationReason);
    return widget.donationCapReached ? '$line $runFinishDonationCapLine' : line;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restoreTheme());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_armResume) return;
    _armResume = false;
    if (!mounted) return;
    setState(() {
      _nextIndex += 1;
      if (_nextIndex >= _queue.length) _clearQueue();
    });
  }

  void _clearQueue() {
    _queue = const [];
    _poster = null;
    _nextIndex = 0;
    _armResume = false;
  }

  Future<void> _restoreTheme() async {
    final theme = await RunFinishThemeStore.load();
    if (!mounted) return;
    setState(() {
      _styleIndex = RunFinishCardTheme.colorThemes.indexOf(theme);
      _usingPhoto = false;
      _themeReady = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_styleController.hasClients) return;
      if (_styleController.page?.round() == theme.index) return;
      _styleController.jumpToPage(theme.index);
    });
  }

  void _onThemeSelected(int index) {
    setState(() {
      _styleIndex = index;
      _usingPhoto = false;
    });
    if (_themeReady) {
      unawaited(
        RunFinishThemeStore.save(RunFinishCardTheme.colorThemes[index]),
      );
    }
    if (!_styleController.hasClients) return;
    if (_styleController.page?.round() == index) return;
    _styleController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _styleController.dispose();
    super.dispose();
  }

  RunFinishShareCard _shareCard(RunFinishCardTheme style) {
    final accent = ref
        .watch(serverShopInventoryProvider)
        .asData
        ?.value
        .loadout
        .frame
        .accent;
    final tier =
        ref.watch(activeUserTierStructProvider) ?? UserTier.unratedFallback;
    final angel = ref.watch(userAngelTierProvider);
    return RunFinishShareCard(
      badges: _showTierBadges
          ? RunFinishTierBadges(
              // 아직 등급이 없으면(달팽이, 예비 천사) 그 원은 카드에 넣지 않는다.
              animalImage: tier.isSnail ? null : tier.avatarAssetPath,
              animalLabel: tier.isSnail
                  ? null
                  : tier.animalName(Localizations.localeOf(context)),
              angelImage:
                  angel == AngelTier.preAngel ? null : angel.avatarAssetPath,
              angelLabel:
                  angel == AngelTier.preAngel ? null : angel.circleLabel,
              angelEmoji: angel.emoji,
            )
          : null,
      style: style,
      distanceKm: _distanceLabel,
      time: _timeLabel,
      pace: _paceLabel,
      date: _finishedOn,
      donationWon: _serverDonationWon,
      splitPaces: widget.splitPaces,
      averageHeartRate: widget.averageHeartRate,
      photo: style == RunFinishCardTheme.photo ? _photo : null,
      frameColor: cosmeticAccentColor(accent),
    );
  }

  RunFinishCardTheme get _captureStyle {
    if (_usingPhoto && _photo != null) return RunFinishCardTheme.photo;
    return RunFinishCardTheme.colorThemes[_styleIndex];
  }

  Future<void> _pickRunPhoto(ImageSource source) async {
    try {
      final hook = OnboardingRunResultScreen.debugPickPhoto;
      final Uint8List? bytes;
      if (hook != null) {
        bytes = await hook(source);
      } else {
        final file = await ImagePicker().pickImage(
          source: source,
          maxWidth: 1440,
          imageQuality: 85,
        );
        if (file == null) return;
        bytes = await file.readAsBytes();
      }
      if (!mounted || bytes == null || bytes.isEmpty) return;
      setState(() {
        _photo = MemoryImage(bytes!);
        _usingPhoto = true;
      });
    } catch (e, st) {
      debugPrint('run finish photo: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 불러오지 못했어요.')),
      );
    }
  }

  Future<File?> _capturePoster() async {
    if (_sharingImage) return null;
    setState(() => _sharingImage = true);
    try {
      return await RunFinishImageShare.capture(_cardKey);
    } catch (e, st) {
      debugPrint('RunFinishImageShare.capture: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(RunFinishImageShare.captureFailedMessage)),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _sharingImage = false);
    }
  }

  Future<void> _shareSheet(BuildContext buttonContext, File file) async {
    try {
      await RunFinishImageShare.shareImageFile(
        path: file.path,
        sharePositionOrigin: WalkingChallengeShare.originFrom(buttonContext),
      );
    } catch (e, st) {
      debugPrint('RunFinishImageShare.sheet: $e\n$st');
    }
  }

  Future<void> _handOff(
      RunFinishShareTarget target, BuildContext origin) async {
    final file = _poster;
    if (file == null) return;
    if (target == RunFinishShareTarget.more) {
      if (origin.mounted) await _shareSheet(origin, file);
      return;
    }
    final opened = await RunFinishImageShare.shareTarget(
      id: target.id,
      path: file.path,
    );
    if (!opened && origin.mounted) await _shareSheet(origin, file);
  }

  Future<void> _onCardShare(BuildContext origin) async {
    final mode = await showRunFinishShareMode(
      origin,
      await RunFinishSharePrefs.loadMode(),
    );
    if (mode == null || !origin.mounted) return;
    await RunFinishSharePrefs.saveMode(mode);
    final targets = orderedShareTargets(
      installedIds: await RunFinishImageShare.installedTargets(),
      savedOrder: await RunFinishSharePrefs.loadOrder(),
    );
    if (!origin.mounted) return;
    if (mode == RunFinishShareMode.one) {
      final target = await showRunFinishOnePicker(origin, targets);
      if (target == null || !mounted) return;
      final file = await _capturePoster();
      if (file == null || !origin.mounted) return;
      _poster = file;
      await _handOff(target, origin);
      return;
    }
    final saved = await RunFinishSharePrefs.loadOrder();
    if (!origin.mounted) return;
    final chosen = await showRunFinishSequencePicker(
      origin,
      targets: targets,
      checkedIds: saved.toSet(),
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;
    await RunFinishSharePrefs.saveOrder([for (final item in chosen) item.id]);
    final file = await _capturePoster();
    if (file == null || !origin.mounted) return;
    setState(() {
      _poster = file;
      _queue = chosen;
      _nextIndex = 0;
      _armResume = true;
    });
    await _handOff(chosen.first, origin);
  }

  Future<void> _onSequenceNext(BuildContext origin) async {
    if (_nextIndex >= _queue.length) return;
    final target = _queue[_nextIndex];
    setState(() => _armResume = true);
    await _handOff(target, origin);
  }

  void _onSequenceSkip() {
    setState(() {
      _nextIndex += 1;
      if (_nextIndex >= _queue.length) _clearQueue();
    });
  }

  Future<void> _onShare(BuildContext buttonContext) async {
    final shareText = runFinishShareText(
      distanceKm: _distanceLabel,
      time: _timeLabel,
      donationWon: _serverDonationWon,
    );

    try {
      await WalkingChallengeShare.openChooser(
        buttonContext,
        text: shareText,
        subject: '쉐어런 완주 기록',
        sharePositionOrigin: WalkingChallengeShare.originFrom(buttonContext),
      );
    } catch (e, st) {
      debugPrint('WalkingChallengeShare.finish: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 새 디자인: 이 화면 안의 기본 글자색·스위치 색도 검정 + 라임 테마를 따른다.
    return Theme(
      data: SrcTheme.night,
      child: Builder(builder: _buildNight),
    );
  }

  Widget _buildNight(BuildContext context) {
    if (!widget.serverConfirmed) {
      return Scaffold(
        backgroundColor: AppColors.nightBg,
        body: SRCGradientBackground(
          gradient: _nightFlat,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: widget.serverAnswered
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _donationStatus,
                            key: const Key('run-finish-donation-status'),
                            style: AppTextStyles.header1.copyWith(fontSize: 18, color: AppColors.nightInk),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          _RecordCard(
                            distance: '$_distanceLabel km',
                            time: _timeLabel,
                            pace: _paceLabel,
                          ),
                        ],
                      )
                    : Text(
                        AppStrings.runResultUnconfirmed,
                        style: AppTextStyles.header1.copyWith(fontSize: 18, color: AppColors.nightInk),
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
          ),
        ),
      );
    }
    final valueTokens = widget.valueTokenReward;
    return Scaffold(
      backgroundColor: AppColors.nightBg,
      body: SRCGradientBackground(
        gradient: _nightFlat,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppShapes.termsHorizontalPadding,
                        16,
                        AppShapes.termsHorizontalPadding,
                        16,
                      ),
                      child: Column(
                        children: [
                          const _CelebrationGraphic(),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.runResultTitle,
                            style: AppTextStyles.header1.copyWith(fontSize: 28, color: AppColors.nightInk),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          RunFinishSharePreview(
                            controller: _styleController,
                            styleIndex: _styleIndex,
                            cardFor: _shareCard,
                            onStyleChanged: _onThemeSelected,
                            photoActive: _usingPhoto && _photo != null,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _ImageShareButton(
                                  key: OnboardingRunResultScreen.photoCameraKey,
                                  label: OnboardingRunResultScreen
                                      .photoCameraLabel,
                                  onTap: () => unawaited(
                                    _pickRunPhoto(ImageSource.camera),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ImageShareButton(
                                  key:
                                      OnboardingRunResultScreen.photoGalleryKey,
                                  label: OnboardingRunResultScreen
                                      .photoGalleryLabel,
                                  onTap: () => unawaited(
                                    _pickRunPhoto(ImageSource.gallery),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SwitchListTile(
                            key: OnboardingRunResultScreen.tierBadgeSwitchKey,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('티어·천사 등급 넣기'),
                            value: _showTierBadges,
                            onChanged: (v) =>
                                setState(() => _showTierBadges = v),
                          ),
                          const SizedBox(height: 12),
                          _RecordCard(
                            distance: '$_distanceLabel km',
                            time: _timeLabel,
                            pace: _paceLabel,
                          ),
                          const SizedBox(height: 14),
                          _RewardCard(valueTokens: valueTokens),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppShapes.termsHorizontalPadding,
                      8,
                      AppShapes.termsHorizontalPadding,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          key: const Key('run-finish-donation-status'),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.nightCard,
                            borderRadius:
                                BorderRadius.circular(AppShapes.cardRadius),
                          ),
                          child: Text(
                            _donationStatus,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.buttonText.copyWith(
                              color: AppColors.nightInk,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Builder(
                          builder: (buttonContext) {
                            return Material(
                              color: AppColors.nightLime,
                              borderRadius: BorderRadius.circular(
                                AppShapes.cardRadius,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => unawaited(_onShare(buttonContext)),
                                child: SizedBox(
                                  height: AppShapes.buttonHeight,
                                  child: Center(
                                    child: Text(
                                      AppStrings.runResultShare,
                                      style: AppTextStyles.buttonText.copyWith(
                                        color: AppColors.nightOnLime,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (_queue.isNotEmpty &&
                            !_armResume &&
                            _nextIndex < _queue.length) ...[
                          const SizedBox(height: 8),
                          RunFinishSequenceBanner(
                            label: _queue[_nextIndex].label,
                            progress: '${_nextIndex + 1}/${_queue.length}',
                            onNext: () => unawaited(
                              _onSequenceNext(context),
                            ),
                            onSkip: _onSequenceSkip,
                            onStop: () => setState(_clearQueue),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _ImageShareButton(
                          key: runFinishCardShareKey,
                          label: '카드 올리기',
                          onTap: _sharingImage
                              ? null
                              : () => unawaited(_onCardShare(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Full 1080×1920 poster for export. The stack does not clip a
              // zero-size child, so without the shift this layer covers the
              // phone and the window cuts off the right side. toImage reads
              // the boundary before the shift, at pixelRatio 1.
              Positioned(
                left: 0,
                top: 0,
                width: 0,
                height: 0,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: RunFinishShareCard.canvasWidth,
                      maxWidth: RunFinishShareCard.canvasWidth,
                      minHeight: RunFinishShareCard.canvasHeight,
                      maxHeight: RunFinishShareCard.canvasHeight,
                      child: Transform.translate(
                        offset: const Offset(
                          -(RunFinishShareCard.canvasWidth + 8),
                          -(RunFinishShareCard.canvasHeight + 8),
                        ),
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: _shareCard(_captureStyle),
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

class _ImageShareButton extends StatelessWidget {
  const _ImageShareButton({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.nightCard,
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppShapes.cardRadius),
            border: Border.all(color: AppColors.nightLine),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.buttonText.copyWith(
              color: AppColors.nightInk,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationGraphic extends StatelessWidget {
  const _CelebrationGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.celebration_rounded,
            size: 72,
            color: AppColors.nightLime.withValues(alpha: 0.35),
          ),
          Positioned(
            top: 8,
            left: 24,
            child: Icon(
              Icons.auto_awesome,
              size: 28,
              color: AppColors.progressYellow.withValues(alpha: 0.9),
            ),
          ),
          Positioned(
            top: 16,
            right: 32,
            child: Icon(
              Icons.auto_awesome,
              size: 22,
              color: AppColors.nightLime,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 48,
            child: _ConfettiDot(color: AppColors.error.withValues(alpha: 0.8)),
          ),
          Positioned(
            top: 28,
            right: 56,
            child: _ConfettiDot(color: AppColors.nightLime),
          ),
          Positioned(
            bottom: 20,
            right: 40,
            child: _ConfettiDot(color: AppColors.progressYellow),
          ),
          Positioned(
            top: 40,
            left: 72,
            child: _ConfettiDot(color: const Color(0xFF42A5F5)),
          ),
        ],
      ),
    );
  }
}

class _ConfettiDot extends StatelessWidget {
  const _ConfettiDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.distance,
    required this.time,
    required this.pace,
  });

  final String distance;
  final String time;
  final String pace;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      child: Column(
        children: [
          _RecordLine(label: '거리:', value: distance),
          const SizedBox(height: 12),
          _RecordLine(
            label: AppStrings.runResultFinalTimeLabel,
            value: time,
          ),
          const SizedBox(height: 12),
          _RecordLine(
            label: AppStrings.runResultAvgPaceLabel,
            value: pace,
          ),
        ],
      ),
    );
  }
}

class _RecordLine extends StatelessWidget {
  const _RecordLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.agreementLabel.copyWith(fontSize: 16),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.valueTokens});

  final int valueTokens;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _ShareCoinIcon(size: 56),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+$valueTokens',
                    style: AppTextStyles.header1.copyWith(fontSize: 36, color: AppColors.nightInk),
                  ),
                  Text(
                    'VALUE 획득',
                    style: AppTextStyles.agreementLabel.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.nightLine, height: 1),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.nightCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.runResultValueReward(valueTokens),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.nightMuted,
                    ),
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.nightCard,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.nightInk.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ShareCoinIcon extends StatelessWidget {
  const _ShareCoinIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.progressYellow,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.progressYellow.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'V',
        style: AppTextStyles.buttonText.copyWith(
          color: AppColors.textWhite,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
