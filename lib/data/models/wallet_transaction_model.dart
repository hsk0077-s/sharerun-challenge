import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransactionModel {
  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.shareAmount,
    required this.valueAmount,
    required this.diamondAmount,
    required this.createdAt,
    required this.tournamentId,
    this.itemId,
    this.ticketAmount = 0,
  });

  final String id;
  final String type;
  final int shareAmount;
  final int valueAmount;
  final int diamondAmount;
  final DateTime? createdAt;
  final String? tournamentId;
  final String? itemId;
  final int ticketAmount;

  String get displayLabel {
    if (type == 'shop_purchase' && itemId == 'rest_day_ticket') {
      return '휴식일 지정권';
    }
    if (type == 'shop_item_use' && itemId == 'rest_day_ticket') {
      return '휴식일 지정';
    }
    return switch (type) {
      'share_top_up' => 'Share 충전',
      'tournament_entry' => '대회 참가',
      'tournament_prize_dia' => '대회 보너스 DIA',
      'tournament_top_percent_share' => '대회 상위 완주 SHARE',
      'tournament_finisher_value' => '대회 완주 VALUE',
      'cash_refund_requested' => '현금 환불 요청',
      'bep_refund' => '모집 미달 환불',
      'diamond_box_collect' => '다이아 수집',
      'effort_value_mint' => '러닝 SRV 채굴',
      'onboarding_signup_reward' => '신규 가입 보상',
      'signup_free_ticket' => '첫 경기 무료 참가권',
      'trial_milestone_reward' => '예비 러닝 3회 달성',
      'referral_reward' => '추천인 보상 (지연 지급)',
      'referral_redeem' => '초대 코드 등록',
      'referral_trial_referee_1' => '체험 런 1회',
      'referral_trial_referee' => '체험 런 3회 완료',
      'referral_trial_referrer' => '친구 체험 런 3회',
      'referral_trial_referrer_hold' => '친구 체험 런 3회 대기',
      'mercy_rule_donation' => '자비로운 실패 기부 (Mercy Rule)',
      'winner_reward_claim_all' => '우승 상금 수령',
      'winner_reward_donate_half' => '우승 상금 50% 기부',
      'winner_reward_donate_all' => '우승 상금 전액 기부',
      'sponsor_payment_verified' => '스폰서 결제',
      'web3_transfer' => 'Web3 외부 전송',
      'deposit_forfeiture_fraud' => '부정 러닝 예치금 몰수',
      'pedometer_harvest' => '워킹챌린지 코인 줍기',
      'step_incubator_hatch' => '만보기 부화',
      'donation_match' => '기부 매칭권',
      'personal_sponsor_donation' => '유니세프 기부 완료',
      'personal_sponsor_prize' => '챌린지 상금 지원 후원',
      'cosmetic_equip' => '코스메틱 장착',
      'debug_test_grant_1m' => '디버그 테스트 지급',
      'share_to_dia' => 'SHARE → 다이아 전환',
      'dia_pack_purchase' => '다이아 구매',
      'streak_bonus' => '연속 달리기 보너스',
      'nickname_change' => '닉네임 변경',
      'crew_create' => '크루 만들기',
      'crew_item_gift' => '크루 선물',
      'crew_cheer_share' => '크루 응원 SHARE',
      'challenge_room_create' => '챌린지 방 만들기',
      'hall_of_fame_donation' => '명예의 전당 기부',
      'free_entry' => '무료 대회 참가',
      'ticket_grant' => '참가권 지급',
      'ticket_share_fallback' => '참가권 대신 SHARE 지급',
      'referral_trial_referrer_clawback' => '친구 체험 보상 회수',
      'trial_referrer' => '친구 체험 런 3회',
      'cpr_coach_plus_grant' => 'Coach+ 심폐소생권 지급',
      _ => type,
    };
  }

  String get amountSummary {
    final parts = <String>[];
    final debit = _isDebitType;

    if (shareAmount != 0) {
      parts.add(_formatAmount(shareAmount, 'Share', debit: debit || shareAmount < 0));
    }
    if (valueAmount != 0) {
      parts.add(_formatAmount(valueAmount, 'Value', debit: valueAmount < 0));
    }
    if (diamondAmount != 0) {
      parts.add(_formatAmount(diamondAmount, 'Diamond', debit: diamondAmount < 0));
    }
    if (ticketAmount != 0) {
      parts.add(_formatAmount(ticketAmount, '참가권', debit: ticketAmount < 0));
    }
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  bool get _isDebitType {
    return switch (type) {
      'tournament_entry' ||
      'cash_refund_requested' ||
      'shop_purchase' ||
      'web3_transfer' ||
      'personal_sponsor_donation' ||
      'personal_sponsor_prize' =>
        true,
      _ => false,
    };
  }

  String _formatAmount(int amount, String unit, {required bool debit}) {
    final absolute = amount.abs();
    final sign = debit ? '-' : '+';
    return '$sign$absolute $unit';
  }

  factory WalletTransactionModel.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final createdAt = data['createdAt'];
    DateTime? createdDate;
    if (createdAt is Timestamp) {
      createdDate = createdAt.toDate();
    }

    return WalletTransactionModel(
      id: id,
      type: data['type'] as String? ?? 'unknown',
      shareAmount: (data['shareAmount'] as num?)?.toInt() ?? 0,
      valueAmount: (data['valueAmount'] as num?)?.toInt() ?? 0,
      diamondAmount: (data['diamondAmount'] as num?)?.toInt() ?? 0,
      createdAt: createdDate,
      tournamentId: data['tournamentId'] as String?,
      itemId: data['itemId'] as String?,
      ticketAmount: (data['ticketAmount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 서버 원장 한 쪽. [cursor]를 다음 쪽 요청에 그대로 넘긴다.
class WalletHistoryPage {
  const WalletHistoryPage({
    required this.rows,
    required this.cursor,
    required this.hasMore,
  });

  final List<WalletTransactionModel> rows;
  final Object? cursor;
  final bool hasMore;
}
