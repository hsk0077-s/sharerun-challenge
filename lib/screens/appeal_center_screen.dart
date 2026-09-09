import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../app/providers/app_providers.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../features/appeal/appeal_repository.dart';
import '../features/appeal/models/appeal_packet.dart';
import '../features/onboarding/src_onboarding_controller.dart';

/// src-27 기록 소명 및 고객센터.
class AppealCenterScreen extends ConsumerStatefulWidget {
  const AppealCenterScreen({
    super.key,
    this.activityId,
    this.challengeTitle = '중급 3km 챌린지',
  });

  final String? activityId;
  final String challengeTitle;

  @override
  ConsumerState<AppealCenterScreen> createState() => _AppealCenterScreenState();
}

class _AppealCenterScreenState extends ConsumerState<AppealCenterScreen> {
  final _detailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedReason = AppStrings.appealReasonGps;
  XFile? _proofImage;
  var _busy = false;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textBlack,
                    iconSize: 22,
                    onPressed: _busy ? null : _safeBack,
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.appealTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.header1.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _JenaHoldBanner(challengeTitle: widget.challengeTitle),
                    const SizedBox(height: 20),
                    _AppealFormCard(
                      selectedReason: _selectedReason,
                      reasons: AppStrings.appealReasonOptions,
                      onReasonChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedReason = value);
                      },
                      proofImage: _proofImage,
                      onUpload: _busy ? null : _pickProof,
                      detailController: _detailController,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 14),
                child: FractionallySizedBox(
                  widthFactor: 0.95,
                  child: SizedBox(
                    height: AppShapes.buttonHeight,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.tealAccent,
                        disabledBackgroundColor: AppColors.buttonDisabled,
                        foregroundColor: AppColors.textWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.textWhite,
                              ),
                            )
                          : Text(
                              AppStrings.appealSubmitCta,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.buttonText.copyWith(
                                color: AppColors.textWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
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
    );
  }

  Future<void> _pickProof() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (!mounted || file == null) return;
      setState(() => _proofImage = file);
    } catch (error, stackTrace) {
      debugPrint('Appeal proof pick failed: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지를 불러오지 못했습니다. 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.appealProofRequiredSnack)),
      );
      return;
    }

    final authUser = ref.read(authStateChangesProvider).value;
    final localSession = ref.read(persistedAuthSessionProvider);
    final userId = authUser?.uid ?? localSession?.uid;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 소명 자료를 제출할 수 있습니다.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final now = DateTime.now().toUtc();
      final appealId = 'appeal-${now.millisecondsSinceEpoch}';
      final activityId = (widget.activityId != null &&
              widget.activityId!.trim().isNotEmpty)
          ? widget.activityId!.trim()
          : 'activity-$userId-pending';
      final expireAt = now.add(AppealRepository.proofTtl);
      final packet = AppealPacket(
        appealId: appealId,
        userId: userId,
        userNickname: ref.read(userNicknameProvider),
        activityId: activityId,
        reasonCategory: _selectedReason,
        reasonDetail: _detailController.text.trim(),
        proofImageUri: 'gs://src-appeal-proofs/$userId/$appealId.jpg',
        status: AppealPacketStatus.underReview,
        createdAt: now,
        expireAt: expireAt,
        purgeAt: expireAt,
        challengeTitle: widget.challengeTitle,
      );

      await ref.read(appealRepositoryProvider).submitAppealPacket(packet: packet);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(AppStrings.appealSubmitSuccessTitle),
            content: const Text(AppStrings.appealSubmitSuccessBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
      _safeBack();
    } catch (error, stackTrace) {
      debugPrint('Appeal submit failed: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('소명 제출에 실패했습니다. $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _safeBack() {
    try {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
        return;
      }
      final router = GoRouter.maybeOf(context);
      if (router != null && router.canPop()) {
        router.pop();
      }
    } catch (_) {}
  }
}

class _JenaHoldBanner extends StatelessWidget {
  const _JenaHoldBanner({required this.challengeTitle});

  final String challengeTitle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warningFill.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ Jena AI 기록 검증 보류 안내',
                style: AppTextStyles.agreementLabel.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.warningOrange,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '최근 제출하신 [$challengeTitle] 기록이 비정상적인 GPS/심박수 패턴으로 인해 보류 처리되었습니다. 억울한 경우 아래 폼을 통해 소명 자료를 제출해 주세요.',
                style: AppTextStyles.agreementLabel.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppealFormCard extends StatelessWidget {
  const _AppealFormCard({
    required this.selectedReason,
    required this.reasons,
    required this.onReasonChanged,
    required this.proofImage,
    required this.onUpload,
    required this.detailController,
  });

  final String selectedReason;
  final List<String> reasons;
  final ValueChanged<String?> onReasonChanged;
  final XFile? proofImage;
  final VoidCallback? onUpload;
  final TextEditingController detailController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.appealFormTitle,
            style: AppTextStyles.agreementLabel.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey(selectedReason),
            initialValue: selectedReason,
            items: [
              for (final reason in reasons)
                DropdownMenuItem<String>(
                  value: reason,
                  child: Text(
                    reason,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.agreementLabel.copyWith(fontSize: 13),
                  ),
                ),
            ],
            onChanged: onReasonChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceWhite,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderGrey),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _DashedUploadBox(proofImage: proofImage, onTap: onUpload),
          const SizedBox(height: 14),
          TextFormField(
            controller: detailController,
            minLines: 3,
            maxLines: 8,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: AppStrings.appealDetailHint,
              hintStyle: AppTextStyles.caption.copyWith(
                fontSize: 14,
                color: AppColors.textGreyLight,
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            style: AppTextStyles.agreementLabel.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _DashedUploadBox extends StatelessWidget {
  const _DashedUploadBox({
    required this.proofImage,
    required this.onTap,
  });

  final XFile? proofImage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _DashedRRectPainter(
            color: proofImage == null ? AppColors.borderGrey : AppColors.tealAccent,
            radius: 16,
          ),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: proofImage == null
                ? Center(
                    child: Text(
                      AppStrings.appealUploadLabel,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(proofImage!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 1.5;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final half = strokeWidth / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        half,
        half,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
