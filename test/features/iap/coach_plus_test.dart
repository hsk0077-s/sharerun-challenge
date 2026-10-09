import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:share_run_challenge/data/models/user_model.dart';
import 'package:share_run_challenge/features/iap/models/coach_plus_product.dart';
import 'package:share_run_challenge/features/iap/providers/coach_plus_providers.dart';
import 'package:share_run_challenge/features/iap/services/coach_plus_entitlement_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProductDetails _detail({
  required String id,
  required String price,
  required double rawPrice,
}) {
  return ProductDetails(
    id: id,
    title: 'Coach+',
    description: 'Coach+',
    price: price,
    rawPrice: rawPrice,
    currencyCode: 'KRW',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('force override is debug-only', () {
    expect(
      coachPlusForceEnabled(debugMode: false, dartDefine: true),
      isFalse,
    );
    expect(
      coachPlusForceEnabled(debugMode: true, dartDefine: false),
      isFalse,
    );
    expect(
      coachPlusForceEnabled(debugMode: true, dartDefine: true),
      isTrue,
    );
  });

  test('monthly grant stays inside the local window only', () async {
    SharedPreferences.setMockInitialValues({});
    const store = CoachPlusEntitlementStore();
    final now = DateTime.utc(2026, 9, 28);

    expect(await store.readActive(now: now), isFalse);
    await store.grant(CoachPlusPlan.monthly.productId, now: now);

    expect(
      await store.readActive(now: now.add(const Duration(days: 31))),
      isTrue,
    );
    expect(
      await store.readActive(now: now.add(const Duration(days: 33))),
      isFalse,
    );
    await store.grant('share_pack_1000', now: now);
    expect(
      await store.readActive(now: now.add(const Duration(days: 1))),
      isTrue,
    );
  });

  test('profile window is the same on every phone', () {
    final now = DateTime.utc(2026, 10, 3, 12);
    final inactive = UserModel.dashboardDefault(uid: 'u1');
    expect(coachPlusActiveOnProfile(inactive, now), isFalse);

    final active = inactive.copyWith(
      coachPlusProductId: CoachPlusPlan.monthly.productId,
      coachPlusActiveUntil: now.add(const Duration(days: 1)).toIso8601String(),
    );
    expect(coachPlusActiveOnProfile(active, now), isTrue);
    expect(
      coachPlusActiveOnProfile(
        active,
        now.add(const Duration(days: 2)),
      ),
      isFalse,
    );
  });

  test('offer choice prefers a store free phase and shows the paid price', () {
    final paid = _detail(
      id: CoachPlusPlan.monthly.productId,
      price: '₩6,900',
      rawPrice: 6900,
    );
    final intro = _detail(
      id: CoachPlusPlan.monthly.productId,
      price: '무료',
      rawPrice: 0,
    );
    final choice = chooseCoachPlusOffer(
      productId: CoachPlusPlan.monthly.productId,
      details: [paid, intro],
      fallbackPriceLabel: CoachPlusPlan.monthly.fallbackPriceLabel,
    );

    expect(choice?.purchase.rawPrice, 0);
    expect(choice?.priceLabel, '₩6,900');
  });

  test('offer choice falls back when the store has no row', () {
    expect(
      chooseCoachPlusOffer(
        productId: CoachPlusPlan.yearly.productId,
        details: const [],
        fallbackPriceLabel: CoachPlusPlan.yearly.fallbackPriceLabel,
      ),
      isNull,
    );
    final onlyIntro = chooseCoachPlusOffer(
      productId: CoachPlusPlan.yearly.productId,
      details: [
        _detail(
          id: CoachPlusPlan.yearly.productId,
          price: '무료',
          rawPrice: 0,
        ),
      ],
      fallbackPriceLabel: CoachPlusPlan.yearly.fallbackPriceLabel,
    );
    expect(onlyIntro?.priceLabel, '39,000원');
  });
}
