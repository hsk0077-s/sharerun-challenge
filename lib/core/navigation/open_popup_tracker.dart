import 'package:flutter/material.dart';

/// 열려 있는 하단 창·대화상자를 기억해 두었다가, 뒤로가기나 탭 전환 때 먼저 닫는다.
///
/// 하단 창은 탭 안쪽 화면에 열리는데, 탭 전체를 지키는 뒤로가기 장치는 그것을 모른다.
/// 그래서 예전에는 창이 열린 채로 홈으로 가 버렸다. 각 탭(브랜치)과 맨 바깥 라우터에
/// 이 관찰자를 하나씩 달면 한 곳에서 같이 처리된다.
class OpenPopupTracker extends NavigatorObserver {
  static final List<PopupRoute<dynamic>> _open = [];

  /// 열려 있는 창이 있는지.
  static bool get hasOpen => _open.any(_isLive);

  static bool _isLive(PopupRoute<dynamic> route) =>
      route.isActive && route.navigator != null;

  /// 가장 나중에 열린 창 하나를 닫는다. 닫을 것이 있었으면 true.
  static bool closeTop() {
    for (final route in _open.reversed.toList()) {
      if (!_isLive(route)) continue;
      final navigator = route.navigator!;
      if (route.isCurrent) {
        navigator.pop();
      } else {
        navigator.removeRoute(route);
      }
      return true;
    }
    return false;
  }

  /// 열려 있는 창을 모두 닫는다(탭을 바꿀 때).
  static void closeAll() {
    while (closeTop()) {}
  }

  @visibleForTesting
  static void resetForTest() => _open.clear();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) _open.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _open.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _open.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _open.remove(oldRoute);
    if (newRoute is PopupRoute) _open.add(newRoute);
  }
}
