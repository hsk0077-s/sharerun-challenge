import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Coach+ subscription catalog.
///
/// Subscription-only. There is no lifetime / one-time SKU.
///
/// Display targets (the store price is the source of truth once Play Billing
/// or StoreKit returns a product):
/// * [monthly] ₩6,900
/// * [yearly] ₩59,000
///
/// TODO(console): a 7-day free trial cannot be created from app code.
/// Create it in the store consoles, then this client will use it:
/// * Play Console — two auto-renewing subscriptions,
///   `coach_plus_monthly` and `coach_plus_yearly`, each with one base plan
///   at the prices above and a 7-day free-trial offer.
/// * App Store Connect — auto-renewable subscriptions with the same product
///   IDs and a 7-day introductory offer. StoreKit applies that offer itself.
/// Android purchase picks a store offer whose first phase price is 0 when
/// Play returns one (see [chooseCoachPlusOffer]). The app does not start a
/// local trial timer.
class CoachPlusPlan {
  const CoachPlusPlan({
    required this.productId,
    required this.periodLabel,
    required this.fallbackPriceLabel,
    required this.localActiveWindow,
  });

  final String productId;
  final String periodLabel;

  /// Shown only until the store returns a formatted price.
  final String fallbackPriceLabel;

  /// How long a store-owned subscription stays entitled on device after the
  /// last purchase or Android purchase refresh. Not a free trial and not the
  /// store's billing period. Play's `queryPurchases` (via restore) extends
  /// this while the subscription is still owned.
  final Duration localActiveWindow;

  static const monthly = CoachPlusPlan(
    productId: 'coach_plus_monthly',
    periodLabel: '월간',
    fallbackPriceLabel: '6,900원',
    localActiveWindow: Duration(days: 32),
  );

  static const yearly = CoachPlusPlan(
    productId: 'coach_plus_yearly',
    periodLabel: '연간',
    fallbackPriceLabel: '59,000원',
    localActiveWindow: Duration(days: 370),
  );

  static const catalog = <CoachPlusPlan>[monthly, yearly];

  static Set<String> get ids => <String>{
        monthly.productId,
        yearly.productId,
      };

  static CoachPlusPlan? byProductId(String productId) {
    for (final plan in catalog) {
      if (plan.productId == productId) return plan;
    }
    return null;
  }

  static bool isCoachPlusId(String productId) => byProductId(productId) != null;
}

/// Debug phone-verify only. Release and profile ignore the define.
///
/// `flutter run --dart-define=FORCE_COACH_PLUS=true`
bool coachPlusForceEnabled({
  required bool debugMode,
  required bool dartDefine,
}) =>
    debugMode && dartDefine;

bool get coachPlusForceDebug => coachPlusForceEnabled(
      debugMode: kDebugMode,
      dartDefine: const bool.fromEnvironment('FORCE_COACH_PLUS'),
    );

/// Which store row to buy, and which price string to show.
///
/// A subscription id can come back once per base plan / offer. A row with
/// `rawPrice <= 0` is a store introductory phase (the console free trial).
/// Buying that row uses its offer token. The label stays the paid phase
/// when Play also returned one, otherwise the catalog fallback.
class CoachPlusOfferChoice {
  const CoachPlusOfferChoice({
    required this.purchase,
    required this.priceLabel,
  });

  final ProductDetails purchase;
  final String priceLabel;
}

CoachPlusOfferChoice? chooseCoachPlusOffer({
  required String productId,
  required List<ProductDetails> details,
  required String fallbackPriceLabel,
}) {
  final matches = <ProductDetails>[
    for (final detail in details)
      if (detail.id == productId) detail,
  ];
  if (matches.isEmpty) return null;
  final paid = <ProductDetails>[
    for (final detail in matches)
      if (detail.rawPrice > 0) detail,
  ];
  final intro = <ProductDetails>[
    for (final detail in matches)
      if (detail.rawPrice <= 0) detail,
  ];
  final purchase = intro.isNotEmpty
      ? intro.first
      : (paid.isNotEmpty ? paid.first : matches.first);
  return CoachPlusOfferChoice(
    purchase: purchase,
    priceLabel: paid.isNotEmpty ? paid.first.price : fallbackPriceLabel,
  );
}
