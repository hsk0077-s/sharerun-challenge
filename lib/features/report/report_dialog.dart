import 'package:flutter/material.dart';
import '../../l10n/remaining_surface.dart';

/// 신고 사유. 값은 서버가 받는 코드와 같다.
Map<String, String> get reportReasons => <String, String>{
  'offensive_name': RemainingSurface.trNow('report.body', '욕설·불쾌한 이름'),
  'sexual': RemainingSurface.trNow('report.body.2', '선정적인 이름'),
  'hate': RemainingSurface.trNow('report.body.3', '혐오·차별 표현'),
  'spam': RemainingSurface.trNow('report.body.4', '광고·도배'),
  'other': RemainingSurface.trNow('report.dialog', '기타'),
};

/// 신고할 대상의 이름을 보여 주고 사유를 고르게 한다. 취소하면 null.
Future<String?> askReportReason(BuildContext context, String targetName) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text('"$targetName" 신고'),
      children: [
        for (final entry in reportReasons.entries)
          SimpleDialogOption(
            key: Key('report-reason-${entry.key}'),
            onPressed: () => Navigator.of(dialogContext).pop(entry.key),
            child: Text(entry.value),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: Text(
            RemainingSurface.trNow('report.button', '운영자가 확인한 뒤 조치합니다. 신고한 사람은 상대에게 알려지지 않아요.'),
            style: Theme.of(dialogContext).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}
