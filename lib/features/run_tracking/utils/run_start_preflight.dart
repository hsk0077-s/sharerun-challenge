import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../data/models/user_model.dart';
import '../../../l10n/remaining_surface.dart';

Future<void> startRunWithPreflight({
  required BuildContext context,
  required UserModel? profile,
}) async {
  if (profile == null || profile.uid.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          RemainingSurface.tr(
            context,
            'run_tracking.run_start_preflight.toast',
            '로그인 후 러닝을 시작할 수 있습니다.',
          ),
        ),
      ),
    );
    return;
  }

  if (!profile.healthDataConsent) {
    final goToConsent = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            RemainingSurface.tr(
              context,
              'run_tracking.run_start_preflight.dialog',
              '건강정보 동의 필요',
            ),
          ),
          content: Text(
            RemainingSurface.tr(
              context,
              'run_tracking.run_start_preflight.button',
              '심박수·케이던스 검증을 위해 [선택] 건강정보 수집 동의가 필요합니다. '
                  '일반 이용약관과 별도로 Opt-in 해 주세요.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                RemainingSurface.tr(
                  context,
                  'run_tracking.run_start_preflight.button.2',
                  '동의 화면으로',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (goToConsent == true && context.mounted) {
      context.push(RouteNames.healthDataConsent);
    }
    return;
  }

  if (context.mounted) {
    context.push(RouteNames.runTracking);
  }
}
