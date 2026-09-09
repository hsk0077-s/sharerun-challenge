import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Material / GoRouter 공통 push·pop (셸 밖 상세 화면용).
abstract final class AppRouteNav {
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    String location, {
    Object? extra,
    WidgetBuilder? materialBuilder,
  }) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      return context.push<T>(location, extra: extra);
    }
    if (materialBuilder != null) {
      return Navigator.of(context).push<T>(
        MaterialPageRoute<T>(builder: materialBuilder),
      );
    }
    return Navigator.of(context).pushNamed<T>(location, arguments: extra);
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop(result);
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }
}
