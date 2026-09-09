import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/root_navigator.dart';
import '../models/iap_ui_event.dart';
import '../providers/iap_providers.dart';

/// 앱 가동과 함께 IAP purchaseStream 구독을 열고, 검증 이벤트를 스낵바로 전달한다.
class IapLifecycleHost extends ConsumerWidget {
  const IapLifecycleHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(iapPurchaseControllerProvider);
    ref.listen<AsyncValue<IapUiEvent>>(iapUiEventsProvider, (previous, next) {
      final event = next.asData?.value;
      if (event == null) return;
      final navContext = rootNavigatorKey.currentContext;
      if (navContext == null) return;
      final messenger = ScaffoldMessenger.maybeOf(navContext);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(content: Text(event.message)));
    });
    return child;
  }
}
