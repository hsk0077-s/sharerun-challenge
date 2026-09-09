import 'package:flutter/material.dart';

import '../app/router/route_names.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_button.dart';
import '../core/widgets/src_gradient_background.dart';
import '../core/widgets/src_sync_button.dart';
import 'garmin_auth_screen.dart';

// TODO(delete?): UI가 DeviceConnectionScreen으로 통합되었습니다.
// 온보딩 라우트(smartWatchSync)도 DeviceConnectionScreen을 사용합니다.
// 라우트 전환 검증 후 이 파일 삭제 가능 여부를 확인해 주세요.
/// 스마트워치 연동 가이드 화면 (Screen 3).
class SmartWatchSyncScreen extends StatelessWidget {
  const SmartWatchSyncScreen({super.key});

  void _onButtonTap() {
    debugPrint('버튼 클릭됨');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientEnd,
      body: SRCGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppShapes.termsHorizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppColors.textBlack,
                      onPressed: () {
                        debugPrint('버튼 클릭됨');
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      onPressed: _onButtonTap,
                      child: Text(
                        AppStrings.watchSyncSkip,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  AppStrings.watchSyncTitle,
                  style: AppTextStyles.termsTitle,
                ),
                const SizedBox(height: 12),
                const Text(
                  AppStrings.watchSyncSubtitle,
                  style: AppTextStyles.termsSubtitle,
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SmartWatchPlaceholder(),
                        const SizedBox(height: 32),
                        SRCSyncButton(
                          label: AppStrings.watchSyncApple,
                          leading: const AppleHealthIcon(),
                          onPressed: _onButtonTap,
                        ),
                        const SizedBox(height: 12),
                        SRCSyncButton(
                          label: AppStrings.watchSyncGoogle,
                          leading: const GoogleHealthConnectIcon(),
                          onPressed: _onButtonTap,
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) => const GarminAuthScreen(),
                              ),
                            ),
                            child: Text(
                              AppStrings.watchSyncExternalDevices,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.link.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SRCButton(
                  label: AppStrings.watchSyncComplete,
                  variant: SRCButtonVariant.primary,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const GarminAuthScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 스마트워치 일러스트 자리 (추후 에셋 교체).
class _SmartWatchPlaceholder extends StatelessWidget {
  const _SmartWatchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryMint.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          Icons.watch_rounded,
          size: 96,
          color: AppColors.primaryMint.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
