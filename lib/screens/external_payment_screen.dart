import 'package:flutter/material.dart';

import 'in_app_billing_screen.dart';

/// 레거시 PG 웹뷰 엔트리 — Google Play IAP 충전소로 전향.
class ExternalPaymentScreen extends StatelessWidget {
  const ExternalPaymentScreen({
    this.amountWon = 0,
    super.key,
  });

  final int amountWon;

  @override
  Widget build(BuildContext context) {
    return InAppBillingScreen(highlightAmountWon: amountWon);
  }
}
