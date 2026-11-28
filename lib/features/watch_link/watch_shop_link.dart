import '../../app/router/route_names.dart';

/// 워치 다이아 화면이 폰 상점을 열 때 쓰는 주소.
///
/// `sharerun://shop`. 워치에서는 결제·구매를 하지 않는다.
class WatchShopLink {
  const WatchShopLink();

  static const scheme = 'sharerun';
  static const host = 'shop';

  String get location => RouteNames.shop;

  static WatchShopLink? parse(String? raw) {
    if (raw == null) return null;
    final text = raw.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || uri.scheme != scheme || uri.host != host) return null;
    return const WatchShopLink();
  }
}
