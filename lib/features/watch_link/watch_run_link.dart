import '../../app/router/route_names.dart';

/// 워치 결과 화면이 폰에서 이 달리기 기록을 열 때 쓰는 주소.
///
/// `sharerun://run/<activityId>`. activityId는 서버가 `activities/{id}`로 저장한
/// 값(워치가 만든 `watch_…` id)이다. id가 없으면 기록 목록·최근 기록을 연다.
class WatchRunLink {
  const WatchRunLink({this.activityId});

  static const scheme = 'sharerun';
  static const host = 'run';

  /// 서버·워치가 쓰는 활동 id. 없거나 비면 최근 기록/목록으로 보낸다.
  final String? activityId;

  bool get hasActivityId {
    final id = activityId?.trim() ?? '';
    return id.isNotEmpty;
  }

  /// GoRouter가 쓰는 경로 (`/watch-run` 또는 `/watch-run?id=`).
  String get location => RouteNames.watchRunRecordFor(activityId ?? '');

  /// 워치가 폰에 보내는 주소.
  String toUriString() {
    final id = activityId?.trim() ?? '';
    if (id.isEmpty) return '$scheme://$host';
    return Uri(scheme: scheme, host: host, pathSegments: [id]).toString();
  }

  /// [raw]가 쉐어런 워치 링크가 아니면 null. 카카오 주소 등은 받지 않는다.
  static WatchRunLink? parse(String? raw) {
    if (raw == null) return null;
    final text = raw.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || uri.scheme != scheme) return null;

    String? cleaned(String? value) {
      if (value == null) return null;
      final text = value.trim();
      return text.isEmpty ? null : text;
    }

    if (uri.host == host) {
      final segs = [for (final s in uri.pathSegments) if (s.isNotEmpty) s];
      final fromPath = segs.isEmpty ? null : cleaned(Uri.decodeComponent(segs.first));
      final fromQuery = cleaned(
        uri.queryParameters['id'] ?? uri.queryParameters['activityId'],
      );
      return WatchRunLink(activityId: fromPath ?? fromQuery);
    }

    final segs = [for (final s in uri.pathSegments) if (s.isNotEmpty) s];
    if (segs.isNotEmpty && segs.first == host) {
      final id = segs.length < 2 ? null : cleaned(Uri.decodeComponent(segs[1]));
      return WatchRunLink(activityId: id);
    }
    return null;
  }
}
