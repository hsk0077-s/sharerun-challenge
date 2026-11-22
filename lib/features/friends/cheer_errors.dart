import 'package:flutter/widgets.dart';

import '../../core/api/api_exception.dart';
import '../../l10n/remaining_surface.dart';

/// Cheer-only error text. It reads the status and detail directly because the
/// shared API message table turns some of these words into referral wording.
///
/// A blocked pair, a missing run and an old run all come back as 'not_found',
/// so the text never says why and never reveals a block.
String cheerErrorMessage(BuildContext? context, Object error) {
  if (error is ApiException) {
    switch (error.detail) {
      case 'not_found':
        return RemainingSurface.tr(
            context, 'cheers.error.not_found', '이 기록에는 응원할 수 없어요.');
      case 'already_cheered':
        return RemainingSurface.tr(
            context, 'cheers.error.already', '이미 응원했어요.');
      case 'friend_daily_limit':
        return RemainingSurface.tr(context, 'cheers.error.friend_daily',
            '이 친구에게는 오늘 이미 응원했어요. 내일 다시 보낼 수 있어요.');
      case 'daily_limit':
        return RemainingSurface.tr(
            context, 'cheers.error.daily', '오늘 응원은 20번까지예요.');
    }
  }
  return RemainingSurface.tr(
      context, 'friends.error.generic', '잠시 후 다시 시도해 주세요.');
}
