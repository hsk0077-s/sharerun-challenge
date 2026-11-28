/// 워치가 페어링된 폰에서 방금 끝낸 달리기를 열 때 쓰는 주소.
///
/// `sharerun://run/<activityId>`. activityId는 서버 `activities` 문서 id와 같다.
const watchRunLinkScheme = 'sharerun';
const watchRunLinkHost = 'run';
const watchShopLinkHost = 'shop';

/// 다이아 화면이 폰의 상점을 열 때. 워치에서는 결제하지 않는다.
String buildWatchShopUri() => '$watchRunLinkScheme://$watchShopLinkHost';

String buildWatchRunUri(String? activityId) {
  final id = activityId?.trim() ?? '';
  if (id.isEmpty) return '$watchRunLinkScheme://$watchRunLinkHost';
  return Uri(
    scheme: watchRunLinkScheme,
    host: watchRunLinkHost,
    pathSegments: [id],
  ).toString();
}
