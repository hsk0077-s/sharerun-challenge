/// Google Play consumable DIA packs. Purchase stays disabled until the
/// products exist in Play Console.
class DiaPackProduct {
  const DiaPackProduct({
    required this.productId,
    required this.priceKrw,
    required this.baseDia,
    required this.bonusDia,
  });

  final String productId;
  final int priceKrw;
  final int baseDia;
  final int bonusDia;

  int get totalDia => baseDia + bonusDia;

  String get bonusLabel => bonusDia == 0 ? '보너스 없음' : '보너스 $bonusDia DIA';

  static const catalog = <DiaPackProduct>[
    DiaPackProduct(
      productId: 'dia_pack_12',
      priceKrw: 1200,
      baseDia: 12,
      bonusDia: 0,
    ),
    DiaPackProduct(
      productId: 'dia_pack_60',
      priceKrw: 5900,
      baseDia: 59,
      bonusDia: 1,
    ),
    DiaPackProduct(
      productId: 'dia_pack_130',
      priceKrw: 12000,
      baseDia: 120,
      bonusDia: 10,
    ),
    DiaPackProduct(
      productId: 'dia_pack_370',
      priceKrw: 33000,
      baseDia: 330,
      bonusDia: 40,
    ),
    DiaPackProduct(
      productId: 'dia_pack_700',
      priceKrw: 59000,
      baseDia: 590,
      bonusDia: 110,
    ),
    DiaPackProduct(
      productId: 'dia_pack_1500',
      priceKrw: 119000,
      baseDia: 1190,
      bonusDia: 310,
    ),
  ];
}
