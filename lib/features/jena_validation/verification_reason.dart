import 'package:flutter/material.dart';

import 'models/jena_validation_result.dart';

/// Plain Korean for a server [reason_code]. Null when the code is unknown.
String? verificationReasonKo(String reasonCode) {
  return switch (reasonCode.trim()) {
    'distance_too_short' => '거리가 이번 방의 최소 거리보다 짧아요. 방 거리만큼, 적어도 1km는 달려야 해요. '
        '기록은 남고 보상은 지급되지 않아요.',
    'cadence_out_of_range' =>
      '분당 걸음 수가 120~210 범위를 벗어났어요. 기록은 남고 보상은 지급되지 않아요.',
    'heart_rate_required' => '상급·하프·파이널 대회는 워치 심박이 있어야 완주로 인정돼요. '
        '심박이 없어 보상은 지급되지 않아요.',
    'heart_rate_low' => '평균 심박이 달리기라고 보기엔 낮아요. 기록은 남고 보상은 지급되지 않아요.',
    'heart_rate_flat' => '심박이 거의 변하지 않아 달리기로 확인되지 않았어요. 기록은 남고 보상은 지급되지 않아요.',
    'stride_out_of_range' => '워치가 없어 보폭을 확인했는데, 거리와 걸음 수가 달리기 범위가 아니에요. '
        '기록은 남고 보상은 지급되지 않아요.',
    'vehicle_speed' => '이동 속도가 차량에 가까워 달리기로 인정되지 않았어요. 기록은 남고 보상은 지급되지 않아요.',
    'kickboard' => '킥보드나 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.',
    'bike' => '자전거 탑승으로 보여 보상은 지급되지 않아요. 기록은 남아요.',
    _ => null,
  };
}

const verificationRejectedFallback = '기록 검증에 실패했습니다. 보상이 지급되지 않았습니다.';

/// Specific Korean when the server rejected the run. The record itself stays.
String verificationUserMessage(JenaValidationResult result) {
  if (result.verified) return result.reason;
  final mapped = verificationReasonKo(result.reasonCode);
  if (mapped != null) return mapped;
  final trimmed = result.reason.trim();
  if (trimmed.isNotEmpty &&
      trimmed != 'No reason provided.' &&
      trimmed != 'No validation result was provided.') {
    return trimmed;
  }
  return verificationRejectedFallback;
}

Future<void> showVerificationRejectedDialog(
  BuildContext context,
  JenaValidationResult result,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('검증되지 않은 기록'),
        content: Text(verificationUserMessage(result)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('확인'),
          ),
        ],
      );
    },
  );
}
