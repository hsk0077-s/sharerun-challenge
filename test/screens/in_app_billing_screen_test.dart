import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_run_challenge/core/strings/app_strings.dart';
import 'package:share_run_challenge/core/theme/theme.dart';
import 'package:share_run_challenge/features/iap/models/share_iap_product.dart';
import 'package:share_run_challenge/screens/in_app_billing_screen.dart';

void main() {
  testWidgets('dia station hides SHARE won packs and keeps the other entries',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SrcTheme.light,
        home: const InAppBillingScreen(highlightAmountWon: 50000),
      ),
    );

    expect(find.text(AppStrings.iapBillingTitle), findsOneWidget);
    expect(find.text('다이아 충전소'), findsOneWidget);
    expect(find.text('Coach+'), findsOneWidget);
    expect(find.text('DIA · SHARE로 교환'), findsOneWidget);
    expect(find.text('DIA 팩'), findsOneWidget);

    expect(
      tester.widget<InkWell>(find.byKey(const Key('coach-plus-billing'))).onTap,
      isNotNull,
    );
    expect(
      tester.widget<InkWell>(find.byKey(const Key('dia-share-exchange'))).onTap,
      isNotNull,
    );
    expect(
      tester.widget<InkWell>(find.byKey(const Key('dia-pack-store'))).onTap,
      isNotNull,
    );

    for (final product in ShareIapProduct.catalog) {
      expect(find.text(product.label), findsNothing);
      expect(find.textContaining(product.productId), findsNothing);
    }
  });
}
