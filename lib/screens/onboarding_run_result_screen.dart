import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../app/providers/wallet_state_provider.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/pedometer/walking_challenge_share.dart';
import '../features/run_result/run_finish_image_share.dart';
import '../features/run_result/run_finish_share_card.dart';
import '../features/run_result/run_finish_share_flow.dart';
import '../features/run_result/run_finish_share_targets.dart';
import '../features/run_result/run_finish_theme_store.dart';

/// 온보딩 플로우 기록 결과 화면 (Screen 11).
class OnboardingRunResultScreen extends ConsumerStatefulWidget {
  const OnboardingRunResultScreen({super.key});

  static const photoGalleryKey = Key('run-finish-photo-gallery');
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
  static const _shareReward = 200;
  static const _valueReward = 100;
  static const _donationAmount = 100;
  static const _mockDistanceKm = '8.35';

  var _rewardsApplied = false;
  var _styleIndex = 0;
  var _themeReady = false;
  var _sharingImage = false;
  var _armResume = false;
  var _nextIndex = 0;
  List<RunFinishShareTarget> _queue = const [];
  File? _poster;

  /// Scenery for this visit only. Never saved, never uploaded.
  ImageProvider? _photo;
  var _usingPhoto = false;
  final _finishedOn = DateTime.now();
  final _styleController = PageController(viewportFraction: 0.8);
  final _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      await _applyRunRewards();
      await _saveRunDataToFirebase();
    });
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
    return RunFinishShareCard(
      style: style,
      distanceKm: _mockDistanceKm,
      time: AppStrings.runResultFinalTimeValue,
      pace: AppStrings.runResultAvgPaceValue,
      date: _finishedOn,
      photo: style == RunFinishCardTheme.photo ? _photo : null,
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

  Future<void> _applyRunRewards() async {
    if (_rewardsApplied || !mounted) return;
    _rewardsApplied = true;
    final wallet = ref.read(walletProvider.notifier);
    wallet.creditShare(_shareReward);
    wallet.creditValueToken(_valueReward);
  }

  /// Placeholder for persisting the run log to Cloud Firestore.
  Future<void> _saveRunDataToFirebase() async {
    // ignore: avoid_print
    print(
      '[OnboardingRunResult] _saveRunDataToFirebase — '
      'distanceKm=$_mockDistanceKm, '
      'time=${AppStrings.runResultFinalTimeValue}, '
      'share=+$_shareReward, value=+$_valueReward',
    );
  }

  Future<void> _onDonate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('기부 확인'),
          content: const Text(
            '유니세프 결식아동에게 100 VALUE를 기부하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('기부하기'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final wallet = ref.read(walletProvider);
    if (wallet.valueTokenBalance < _donationAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기부할 VALUE가 부족합니다.')),
      );
      return;
    }

    ref.read(walletProvider.notifier).donateValueToken(_donationAmount);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('기부가 성공적으로 완료되었습니다!')),
    );
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
    final shareText = 'SRC 앱에서 ${_mockDistanceKm}km 완주 후 기부에 동참했습니다! '
        '⏱ 기록: ${AppStrings.runResultFinalTimeValue}';

    try {
      await WalkingChallengeShare.openChooser(
        buttonContext,
        text: shareText,
        subject: 'SRC 완주 기록',
        sharePositionOrigin: WalkingChallengeShare.originFrom(buttonContext),
      );
    } catch (e, st) {
      debugPrint('WalkingChallengeShare.finish: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
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
                            style: AppTextStyles.header1.copyWith(fontSize: 28),
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
                          const SizedBox(height: 20),
                          const _RecordCard(),
                          const SizedBox(height: 14),
                          const _RewardCard(),
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
                        Material(
                          color: AppColors.primaryMint,
                          borderRadius:
                              BorderRadius.circular(AppShapes.cardRadius),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _onDonate,
                            child: SizedBox(
                              height: AppShapes.buttonHeight,
                              child: Center(
                                child: Text(
                                  AppStrings.runResultDonate,
                                  style: AppTextStyles.buttonText.copyWith(
                                    color: AppColors.textBlack,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Builder(
                          builder: (buttonContext) {
                            return Material(
                              color: AppColors.garminAuthButton,
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
                                        color: AppColors.textWhite,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
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
              // Laid out at full poster size, clipped by the stack so it
              // never covers the finish screen. toImage reads this layer.
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
                      child: RepaintBoundary(
                        key: _cardKey,
                        child: _shareCard(_captureStyle),
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
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppShapes.cardRadius),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.buttonText.copyWith(
              color: AppColors.textBlack,
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
            color: AppColors.primaryMint.withValues(alpha: 0.35),
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
              color: AppColors.primaryMint,
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
            child: _ConfettiDot(color: AppColors.primaryMint),
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
  const _RecordCard();

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      child: Column(
        children: [
          _RecordLine(
            label: AppStrings.runResultFinalTimeLabel,
            value: AppStrings.runResultFinalTimeValue,
          ),
          const SizedBox(height: 12),
          _RecordLine(
            label: AppStrings.runResultAvgPaceLabel,
            value: AppStrings.runResultAvgPaceValue,
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
  const _RewardCard();

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
                    AppStrings.runResultShareAmount,
                    style: AppTextStyles.header1.copyWith(fontSize: 36),
                  ),
                  Text(
                    AppStrings.runResultShareEarned,
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
          Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.agreementBoxFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.runResultValueReward,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.textGrey,
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
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.06),
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
        'S',
        style: AppTextStyles.buttonText.copyWith(
          color: AppColors.textWhite,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
