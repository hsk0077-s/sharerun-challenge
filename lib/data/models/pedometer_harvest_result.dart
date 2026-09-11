class PedometerHarvestResult {
  const PedometerHarvestResult({
    required this.status,
    this.accepted = true,
    this.shareCredited,
    this.shareBalance,
    this.diamondBalance,
    this.valueTokenBalance,
  });

  final String status;
  final bool accepted;
  final int? shareCredited;
  final int? shareBalance;
  final int? diamondBalance;
  final int? valueTokenBalance;

  bool get mintedShare => status == 'harvested';

  /// Server-credited SHARE. Unknown `harvested` bodies fall back to [fallback].
  int creditedShare({required int fallback}) {
    if (shareCredited != null) return shareCredited!;
    if (status == 'harvested' || status.isEmpty) return fallback;
    return 0;
  }

  factory PedometerHarvestResult.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return const PedometerHarvestResult(status: 'harvested');
    }
    return PedometerHarvestResult(
      accepted: json['accepted'] as bool? ?? true,
      status: json['status'] as String? ?? '',
      shareCredited: _readInt(json, const [
        'share_credited',
        'shareCredited',
      ]),
      shareBalance: _readInt(json, const [
        'share_balance',
        'shareBalance',
      ]),
      diamondBalance: _readInt(json, const [
        'diamond_balance',
        'diamondBalance',
      ]),
      valueTokenBalance: _readInt(json, const [
        'value_token_balance',
        'valueTokenBalance',
      ]),
    );
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toInt();
    }
    return null;
  }
}
