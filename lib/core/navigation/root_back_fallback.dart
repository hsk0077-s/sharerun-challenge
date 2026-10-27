import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';

/// Back press that reaches the app's outermost handler.
///
/// The inner navigator gets it first, so a pushed screen closes, a tab root
/// goes home / double-back exits, and screens with their own PopScope keep
/// their behavior. Only when nothing handled it — a screen that became the
/// bottom of the stack through `go()` — the user lands on Home instead of
/// being thrown out of the app.
Future<void> backWithHomeFallback(
  GoRouter router, {
  String home = RouteNames.home,
}) async {
  final inner = router.routerDelegate.navigatorKey.currentState;
  if (inner == null || !inner.mounted) return;
  final handled = await inner.maybePop();
  if (!handled) router.go(home);
}
