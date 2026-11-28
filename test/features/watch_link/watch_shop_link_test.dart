import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/app/router/route_names.dart';
import 'package:share_run_challenge/features/watch_link/watch_run_link.dart';
import 'package:share_run_challenge/features/watch_link/watch_shop_link.dart';

void main() {
  test('sharerun://shop opens the phone shop and is not a run link', () {
    final link = WatchShopLink.parse('sharerun://shop');
    expect(link, isNotNull);
    expect(link!.location, RouteNames.shop);
    expect(WatchRunLink.parse('sharerun://shop'), isNull);
    expect(WatchShopLink.parse('sharerun://run/watch_abc'), isNull);
    expect(WatchShopLink.parse('https://sharerun.app/shop'), isNull);
    expect(WatchShopLink.parse(null), isNull);
  });
}
