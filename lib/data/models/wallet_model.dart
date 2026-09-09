class WalletModel {
  const WalletModel({
    required this.shareBalance,
    required this.diamondBalance,
    required this.valueTokenBalance,
    required this.totalDonationValue,
  });

  final int shareBalance;
  final int diamondBalance;
  final int valueTokenBalance;
  final int totalDonationValue;

  WalletModel copyWith({
    int? shareBalance,
    int? diamondBalance,
    int? valueTokenBalance,
    int? totalDonationValue,
  }) {
    return WalletModel(
      shareBalance: shareBalance ?? this.shareBalance,
      diamondBalance: diamondBalance ?? this.diamondBalance,
      valueTokenBalance: valueTokenBalance ?? this.valueTokenBalance,
      totalDonationValue: totalDonationValue ?? this.totalDonationValue,
    );
  }

  factory WalletModel.empty() {
    return const WalletModel(
      shareBalance: 0,
      diamondBalance: 0,
      valueTokenBalance: 0,
      totalDonationValue: 0,
    );
  }

  /// Robust Firestore mapping — missing / alternate keys fall back to 0.
  factory WalletModel.fromJson(Map<String, dynamic>? json) {
    final raw = json ?? const <String, dynamic>{};
    return WalletModel(
      shareBalance: _readInt(raw, const [
        'shareBalance',
        'share',
        'SHARE',
      ]),
      diamondBalance: _readInt(raw, const [
        'diamondBalance',
        'diamond',
        'dia',
        'DIA',
      ]),
      valueTokenBalance: _readInt(raw, const [
        'valueTokenBalance',
        'valueToken',
        'value',
        'VALUE',
      ]),
      totalDonationValue: _readInt(raw, const [
        'totalDonationValue',
        'donationValue',
      ]),
    );
  }

  static int _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = num.tryParse(value);
        if (parsed != null) return parsed.toInt();
      }
    }
    return 0;
  }
}
