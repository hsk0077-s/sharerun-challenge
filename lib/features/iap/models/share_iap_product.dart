/// Google Play Consumable SHARE 팩 카탈로그.
class ShareIapProduct {
  const ShareIapProduct({
    required this.productId,
    required this.shareAmount,
    required this.priceKrw,
    required this.label,
  });

  final String productId;
  final int shareAmount;
  final int priceKrw;
  final String label;

  static const pack1000 = ShareIapProduct(
    productId: 'share_pack_1000',
    shareAmount: 10000,
    priceKrw: 10000,
    label: '10,000 SHARE',
  );

  static const pack5000 = ShareIapProduct(
    productId: 'share_pack_5000',
    shareAmount: 50000,
    priceKrw: 50000,
    label: '50,000 SHARE',
  );

  static const pack10000 = ShareIapProduct(
    productId: 'share_pack_10000',
    shareAmount: 100000,
    priceKrw: 100000,
    label: '100,000 SHARE',
  );

  static const catalog = <ShareIapProduct>[pack1000, pack5000, pack10000];

  static ShareIapProduct? byProductId(String productId) {
    for (final product in catalog) {
      if (product.productId == productId) return product;
    }
    return null;
  }

  static ShareIapProduct? byPriceKrw(int amountWon) {
    for (final product in catalog) {
      if (product.priceKrw == amountWon || product.shareAmount == amountWon) {
        return product;
      }
    }
    return null;
  }
}
