import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 아침·점심·저녁 리마인더는 몇 분 늦어도 괜찮으므로 "정확한 시각 알람"을 쓰지 않는다.
/// 정확한 알람은 안드로이드 14 이상에서 사용자가 "알람 및 리마인더" 권한을 직접 허용해야
/// 하고, 허용하지 않으면 예약이 조용히 실패해 알림이 오지 않는다. 이 방식은 권한이 필요 없다.
const reminderScheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
