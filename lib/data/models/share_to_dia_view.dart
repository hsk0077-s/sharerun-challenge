class ShareToDiaView {
  const ShareToDiaView({
    required this.status,
    required this.rateSharePerDia,
    required this.unitDia,
    required this.weeklyCapDia,
    required this.remainingDia,
    required this.spendableShare,
    required this.lockedShare,
    this.lockReason,
    this.shareBalance,
    this.diamondBalance,
    this.valueTokenBalance,
  });

  final String status;
  final int rateSharePerDia;
  final int unitDia;
  final int weeklyCapDia;
  final int remainingDia;
  final int spendableShare;
  final int lockedShare;
  final String? lockReason;
  final int? shareBalance;
  final int? diamondBalance;
  final int? valueTokenBalance;

  bool get canExchange =>
      (lockReason == null || lockReason!.isEmpty) && remainingDia > 0;

  factory ShareToDiaView.fromJson(Map<String, dynamic> json) {
    return ShareToDiaView(
      status: json['status'] as String? ?? '',
      rateSharePerDia: _int(json['rate_share_per_dia']) ?? 120,
      unitDia: _int(json['unit_dia']) ?? 10,
      weeklyCapDia: _int(json['weekly_cap_dia']) ?? 20,
      remainingDia: _int(json['remaining_dia']) ?? 0,
      spendableShare: _int(json['spendable_share']) ?? 0,
      lockedShare: _int(json['locked_share']) ?? 0,
      lockReason: json['lock_reason'] as String?,
      shareBalance: _int(json['share_balance']),
      diamondBalance: _int(json['diamond_balance']),
      valueTokenBalance: _int(json['value_token_balance']),
    );
  }

  static int? _int(Object? value) {
    if (value is num) return value.toInt();
    return null;
  }
}
