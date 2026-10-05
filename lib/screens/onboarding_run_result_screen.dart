import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_gradient_background.dart';
import '../features/shop/cosmetics_catalog.dart';
import '../features/shop/providers/server_shop_inventory_provider.dart';
import '../features/pedometer/walking_challenge_share.dart';
import '../features/run_result/run_finish_image_share.dart';
import '../features/run_result/run_finish_share_card.dart';
import '../features/run_result/run_finish_theme_store.dart';

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
  });

  /// Tracked kilometres passed through server validation.
  final double distanceKm;

  /// Tracked seconds passed through server validation.
  final int durationSeconds;

  /// `value_token_reward` from POST /actions/runs/validate.
  final int valueTokenReward;

  /// True only after the server marked the run verified.
  final bool serverConfirmed;

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
    extends ConsumerState<OnboardingRunResultScreen> {
  var _styleIndex = 0;
  var _themeReady = false;
  var _instagramInstalled = false;
  var _tiktokInstalled = false;
  var _sharingImage = false;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadShareTargets());
    });
    unawaited(_restoreTheme());
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
    _styleController.dispose();
    super.dispose();
  }

  Future<void> _loadShareTargets() async {
    final instagram = await RunFinishImageShare.instagramInstalled();
    final tiktok = await RunFinishImageShare.tiktokInstalled();
    if (!mounted) return;
    setState(() {
      _instagramInstalled = instagram;
      _tiktokInstalled = tiktok;
    });
  }

  RunFinishShareCard _shareCard(RunFinishCardTheme style) {
    final accent = ref
        .watch(serverShopInventoryProvider)
        .asData
        ?.value
        .loadout
        .frame
        .accent;
    return RunFinishShareCard(
      style: style,
      distanceKm: _distanceLabel,
      time: _timeLabel,
      pace: _paceLabel,
      date: _finishedOn,
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

  Future<void> _onInstagram() async {
    final file = await _capturePoster();
    if (file == null || !mounted) return;
    final opened = await RunFinishImageShare.shareInstagramStory(file.path);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(RunFinishImageShare.instagramFailedMessage)),
      );
    }
  }

  Future<void> _onTikTok(BuildContext buttonContext) async {
    final file = await _capturePoster();
    if (file == null || !mounted) return;
    final targeted = await RunFinishImageShare.shareTikTok(file.path);
    if (!targeted && buttonContext.mounted) {
      await _shareSheet(buttonContext, file);
    }
  }

  Future<void> _onMore(BuildContext buttonContext) async {
    final file = await _capturePoster();
    if (file == null || !buttonContext.mounted) return;
    await _shareSheet(buttonContext, file);
  }

  Future<void> _onShare(BuildContext buttonContext) async {
    final shareText = 'SRC 앱에서 ${_distanceLabel}km 완주 후 기부에 동참했습니다! '
        '⏱ 기록: $_timeLabel';

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
    if (!widget.serverConfirmed) {
      return Scaffold(
        backgroundColor: AppColors.bgGradientEnd,
        body: SRCGradientBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  AppStrings.runResultUnconfirmed,
                  style: AppTextStyles.header1.copyWith(fontSize: 18),
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
                        Material(
                          color: AppColors.primaryMint.withValues(alpha: 0.35),
                          borderRadius:
                              BorderRadius.circular(AppShapes.cardRadius),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: null,
                            child: SizedBox(
                              height: AppShapes.buttonHeight,
                              child: Center(
                                child: Text(
                                  AppStrings.runResultDonatePending,
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
                        const SizedBox(height: 8),
                        _ImageShareRow(
                          instagram: _instagramInstalled,
                          tiktok: _tiktokInstalled,
                          enabled: !_sharingImage,
                          onInstagram: _onInstagram,
                          onTikTok: _onTikTok,
                          onMore: _onMore,
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

class _ImageShareRow extends StatelessWidget {
  const _ImageShareRow({
    required this.instagram,
    required this.tiktok,
    required this.enabled,
    required this.onInstagram,
    required this.onTikTok,
    required this.onMore,
  });

  final bool instagram;
  final bool tiktok;
  final bool enabled;
  final Future<void> Function() onInstagram;
  final Future<void> Function(BuildContext context) onTikTok;
  final Future<void> Function(BuildContext context) onMore;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (instagram)
        _ImageShareButton(
          key: RunFinishImageShare.instagramButtonKey,
          label: RunFinishImageShare.instagramLabel,
          onTap: enabled ? () => unawaited(onInstagram()) : null,
        ),
      if (tiktok)
        Builder(
          builder: (buttonContext) {
            return _ImageShareButton(
              key: RunFinishImageShare.tiktokButtonKey,
              label: RunFinishImageShare.tiktokLabel,
              onTap: enabled ? () => unawaited(onTikTok(buttonContext)) : null,
            );
          },
        ),
      Builder(
        builder: (buttonContext) {
          return _ImageShareButton(
            key: RunFinishImageShare.moreButtonKey,
            label: RunFinishImageShare.moreLabel,
            onTap: enabled ? () => unawaited(onMore(buttonContext)) : null,
          );
        },
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: buttons[i]),
        ],
      ],
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
                    style: AppTextStyles.header1.copyWith(fontSize: 36),
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
                    AppStrings.runResultValueReward(valueTokens),
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
