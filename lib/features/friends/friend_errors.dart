import 'package:flutter/widgets.dart';

import '../../core/api/api_exception.dart';
import '../../l10n/remaining_surface.dart';

/// Friend-only error text. It reads the status and detail directly because the
/// shared API message table turns 'invalid', 'self' and 'expired' into
/// referral-code wording.
///
/// A blocked pair comes back from the server as 'invalid', the same as a code
/// that does not exist, so the text never reveals a block.
String friendErrorMessage(BuildContext? context, Object error) {
  if (error is ApiException) {
    if (error.statusCode == 429) {
      return RemainingSurface.tr(
          context, 'friends.error.rate', '오늘은 코드를 더 만들 수 없어요. 내일 다시 만들어 주세요.');
    }
    switch (error.detail) {
      case 'invalid':
        return friendInvalidCodeMessage(context);
      case 'self':
        return RemainingSurface.tr(
            context, 'friends.error.self', '내 친구 코드는 내가 쓸 수 없어요.');
      case 'used':
        return RemainingSurface.tr(
            context, 'friends.error.used', '이미 사용한 코드예요. 친구에게 새 코드를 받아 주세요.');
      case 'expired':
        return RemainingSurface.tr(context, 'friends.error.expired',
            '24시간이 지난 코드예요. 친구에게 새 코드를 받아 주세요.');
      case 'friend_limit':
        return RemainingSurface.tr(
            context, 'friends.error.limit', '친구는 50명까지 맺을 수 있어요.');
    }
  }
  return RemainingSurface.tr(
      context, 'friends.error.generic', '잠시 후 다시 시도해 주세요.');
}

/// Also shown when the pasted text holds no friend code at all.
String friendInvalidCodeMessage(BuildContext? context) => RemainingSurface.tr(
    context, 'friends.error.invalid', '코드를 확인해 주세요. 없는 코드이거나 쓸 수 없는 코드예요.');
