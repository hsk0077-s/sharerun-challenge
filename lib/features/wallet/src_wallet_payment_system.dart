import 'package:flutter/material.dart';

import '../../app/router/route_names.dart';
import '../../core/navigation/app_route_nav.dart';
import '../../screens/in_app_billing_screen.dart';
import '../iap/models/share_iap_product.dart';
import 'widgets/share_insufficient_dialog.dart';

/// SRC 지갑·결제 백본.
///
/// - 실물 현금 충전: Google Play `in_app_purchase` 만 사용
///   ([ShareIapProduct] `share_pack_1000` / `5000` / `10000`).
///   purchased → 영수증 `serverVerificationData` → GCP 검증 → `VERIFIED` 후
///   서버가 `shareBalance` 를 가산한다. 클라이언트는 임의 가산하지 않는다.
/// - 크루 창설·방 개설 등 소비: Firestore `runTransaction` 만 사용.
///   IAP `buyConsumable` 을 호출하지 않는다.
abstract final class SrcWalletPaymentSystem {
  static const crewCreateShareCost = 50000;
  static const defaultRoomCreateShareCost = 50000;

  static const pack1000Id = 'share_pack_1000';
  static const pack5000Id = 'share_pack_5000';
  static const pack10000Id = 'share_pack_10000';

  static const billingRoute = RouteNames.inAppBilling;
  static const storeRoute = RouteNames.store;
  static const walletHistoryRoute = RouteNames.walletHistory;

  static List<ShareIapProduct> get iapCatalog => ShareIapProduct.catalog;

  static bool isOfficialIapProduct(String productId) {
    return ShareIapProduct.byProductId(productId) != null;
  }

  static Future<void> openOfficialBilling(BuildContext context) {
    return AppRouteNav.push<void>(
      context,
      billingRoute,
      materialBuilder: (_) => const InAppBillingScreen(),
    );
  }

  static Future<void> promptBillingIfShareShort(BuildContext context) {
    return ShareInsufficientDialog.promptAndMaybeOpenBilling(context);
  }
}
