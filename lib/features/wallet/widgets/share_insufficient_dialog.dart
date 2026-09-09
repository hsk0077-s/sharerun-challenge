import 'package:flutter/material.dart';

import '../../../app/router/route_names.dart';
import '../../../core/navigation/app_route_nav.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../screens/in_app_billing_screen.dart';

/// 인앱 재화 부족 시 충전소(IAP)로만 안내한다. 소비 플로우는 buyConsumable을 호출하지 않는다.
abstract final class ShareInsufficientDialog {
  static Future<bool> askGoToBilling(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.cardRadius + 6),
          ),
          title: Text(
            AppStrings.shareInsufficientTitle,
            style: AppTextStyles.header1.copyWith(fontSize: 18),
          ),
          content: Text(
            AppStrings.shareInsufficientBody,
            style: AppTextStyles.agreementLabel.copyWith(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textGrey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                AppStrings.shareInsufficientNo,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tealAccent,
                foregroundColor: AppColors.textWhite,
              ),
              child: Text(
                AppStrings.shareInsufficientYes,
                style: AppTextStyles.buttonText.copyWith(
                  color: AppColors.textWhite,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
    return go == true;
  }

  static Future<void> openBilling(BuildContext context) {
    return AppRouteNav.push<void>(
      context,
      RouteNames.inAppBilling,
      materialBuilder: (_) => const InAppBillingScreen(),
    );
  }

  static Future<void> promptAndMaybeOpenBilling(BuildContext context) async {
    final go = await askGoToBilling(context);
    if (!go || !context.mounted) return;
    await openBilling(context);
  }
}
