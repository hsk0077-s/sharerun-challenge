import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/root_navigator.dart';
import '../../../core/config/app_env.dart';
import '../models/iap_ui_event.dart';
import '../providers/iap_providers.dart';

/// 앱 가동과 함께 IAP purchaseStream 구독을 열고, 검증 이벤트를 스낵바로 전달한다.
class IapLifecycleHost extends ConsumerWidget {
  const IapLifecycleHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 결제 스위치가 꺼져 있으면 컨트롤러를 만들지 않는다. 컨트롤러를 만들면
    // 구매 스트림을 구독하고 Android에서 restorePurchases를 자동으로 부른다.
    if (!AppEnv.inAppPurchasesEnabled) return child;
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
