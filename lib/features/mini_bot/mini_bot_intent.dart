import '../../core/challenge/challenge_entry_fee.dart';
import '../../core/strings/app_strings.dart';
import '../iap/models/coach_plus_product.dart';
import '../iap/models/share_iap_product.dart';
import '../shop/providers/shop_tab_provider.dart';

/// Mini-bot intents. Typed, chip, and speech text share [MiniBotInterpreter].
///
/// This file does not navigate, join, donate, or charge. A spend read only
/// recommends an existing screen and waits for one confirm tap.
enum MiniBotIntent {
  appIntro,
  joinChallenge,
  openCprTicket,
  donate,
  openSafeGuard,
  chargeShare,
  sponsorRunner,
  brandSponsor,
  subscription,
  coachPlus,
  battlePass,
  unknown,
}

enum MiniBotDestination {
  none,
  beginnerRoom,
  challengeLobby,
  cprStore,
  donateStore,
  safeGuardStore,
  shareCharge,
  personalSponsor,
  brandSponsor,
  subscription,
  coachPlus,
  battlePass,
}

class MiniBotRead {
  const MiniBotRead({
    required this.intent,
    required this.destination,
    required this.reply,
    required this.needsConfirm,
  });

  final MiniBotIntent intent;
  final MiniBotDestination destination;
  final String reply;
  final bool needsConfirm;

  /// True only for moves that must wait for an explicit confirm tap.
  bool get awaitsConfirm =>
      needsConfirm && destination != MiniBotDestination.none;

  /// Opens the existing screen. Never completes the spend by itself.
  String get confirmLabel => switch (destination) {
        MiniBotDestination.donateStore ||
        MiniBotDestination.personalSponsor =>
          '후원하기',
        MiniBotDestination.cprStore ||
        MiniBotDestination.safeGuardStore =>
          '구매하기',
        MiniBotDestination.shareCharge => '충전하기',
        MiniBotDestination.beginnerRoom ||
        MiniBotDestination.brandSponsor =>
          '참가하기',
        MiniBotDestination.challengeLobby ||
        MiniBotDestination.subscription ||
        MiniBotDestination.coachPlus ||
        MiniBotDestination.battlePass ||
        MiniBotDestination.none =>
          '이동하기',
      };

  String? get amountLabel => switch (destination) {
        MiniBotDestination.donateStore => MiniBotCopy.donateAmount,
        MiniBotDestination.cprStore ||
        MiniBotDestination.safeGuardStore =>
          MiniBotCopy.itemAmount,
        MiniBotDestination.shareCharge => MiniBotCopy.chargeAmount,
        MiniBotDestination.beginnerRoom => MiniBotCopy.joinAmount,
        MiniBotDestination.personalSponsor => MiniBotCopy.sponsorAmount,
        MiniBotDestination.brandSponsor => MiniBotCopy.brandAmount,
        MiniBotDestination.subscription => MiniBotCopy.subscriptionAmount,
        MiniBotDestination.coachPlus => MiniBotCopy.coachPlusAmount,
        MiniBotDestination.battlePass => MiniBotCopy.battlePassAmount,
        MiniBotDestination.challengeLobby || MiniBotDestination.none => null,
      };
}

class MiniBotChip {
  const MiniBotChip({required this.id, required this.label});

  final String id;
  final String label;
}

abstract final class MiniBotPrompts {
  static const intro = '앱 소개';
  static const joinBeginner = '챌린지 참가';
  static const joinLobby = '챌린지 로비';
  static const cpr = '심폐소생권';
  static const donate = '후원';
  static const safeGuard = '세이프가드';
  static const charge = 'SHARE 충전';
  static const sponsor = '스폰서';
  static const runnerSponsor = '러너 후원';
  static const subscription = '구독';
  static const coachPlus = 'Coach+';
  static const battlePass = '배틀패스';

  /// Guide chips first, then monetization. Confirm still opens the screen only.
  static const chips = <MiniBotChip>[
    MiniBotChip(id: 'intro', label: intro),
    MiniBotChip(id: 'lobby', label: joinLobby),
    MiniBotChip(id: 'donate', label: donate),
    MiniBotChip(id: 'brand', label: sponsor),
    MiniBotChip(id: 'runner', label: runnerSponsor),
    MiniBotChip(id: 'join', label: joinBeginner),
    MiniBotChip(id: 'charge', label: charge),
    MiniBotChip(id: 'cpr', label: cpr),
    MiniBotChip(id: 'safeguard', label: safeGuard),
    MiniBotChip(id: 'subscription', label: subscription),
    MiniBotChip(id: 'coach-plus', label: coachPlus),
    MiniBotChip(id: 'battle-pass', label: battlePass),
  ];
}

abstract final class MiniBotCopy {
  static const greeting = '안녕하세요. 쉐어런 미니봇이에요. 안내하고, 추천한 뒤, 확인받아야만 이동해요.';

  static const intro = '쉐어런은 함께 걷고 달리는 챌린지 앱이에요. '
      '홈에서 오늘 상태를 보고, 챌린지 로비나 초보 1km 방에서 레이스에 참가할 수 있어요. '
      '기록 심폐소생권은 상점 아이템에서 볼 수 있어요. '
      '저는 화면 이동만 돕고, 결제나 참가 확정은 하지 않아요.';

  static String get donateAmount =>
      '${ShopTabNotifier.donateValueAmount} VALUE';

  static String get itemAmount => '${ShopTabNotifier.itemDiaCost} DIA';

  static String get chargeAmount => ShareIapProduct.catalog
      .map((product) => '${_grouped(product.priceKrw)}원')
      .join(' · ');

  static String get joinAmount =>
      '${_grouped(ChallengeEntryFee.beginner1kmShare)} SHARE';

  static String get sponsorAmount => AppStrings.personalSponsorAmount;

  static String get brandAmount => AppStrings.brandSponsorEntryFee;

  static String get subscriptionAmount {
    final monthly = AppStrings.subscriptionDonationStatus.split('\n').first;
    final premium = AppStrings.subscriptionPremiumPrice.split('(').first.trim();
    return '$monthly · $premium';
  }

  static String get battlePassAmount =>
      '${AppStrings.battlePassTitle} · ${AppStrings.battlePassCurrentLevel}';

  static String get donate => '유니세프 기부 펀딩으로 이동할까요? $donateAmount예요. '
      '후원하기를 눌러도 여기서는 기부가 끝나지 않아요. '
      '상점의 기부 버튼으로 직접 눌러 주세요.';

  static String get joinBeginner => '초보 1km 챌린지 방으로 이동할까요? 참가비는 $joinAmount예요. '
      '참가하기를 눌러도 참가는 확정되지 않아요. 그 화면에서 직접 확인해 주세요.';

  static const joinLobby = '챌린지 로비로 이동할까요? 로비에서 참가할 방을 고를 수 있어요.';

  static String get cpr => '상점의 기록 심폐소생권으로 이동할까요? $itemAmount예요. '
      '구매하기를 눌러도 결제하지 않아요. 상점 화면에서 직접 구매해 주세요.';

  static String get safeGuard => '상점의 세이프 가드로 이동할까요? $itemAmount예요. '
      '구매하기를 눌러도 결제하지 않아요. '
      '상점의 세이프 가드 칸에서 직접 구매해 주세요.';

  static String get charge => 'SHARE 충전소로 이동할까요? $chargeAmount 팩이 있어요. '
      '충전하기를 눌러도 여기서는 결제되지 않아요. 충전소에서 직접 골라 주세요.';

  static String get sponsor => '러너 후원 화면으로 이동할까요? $sponsorAmount예요. '
      '후원하기를 눌러도 여기서는 후원이 끝나지 않아요. '
      '그 화면의 후원 버튼으로 직접 확정해 주세요.';

  static String get brand => '브랜드 스폰서 챌린지로 이동할까요? $brandAmount. '
      '참가하기를 눌러도 여기서는 참가하지 않아요. 그 화면에서 직접 확인해 주세요.';

  static String get subscription => '구독 관리 화면으로 이동할까요? $subscriptionAmount. '
      '이동만 하고, 구독이나 결제는 바꾸지 않아요.';

  static String get coachPlusAmount {
    final monthly = CoachPlusPlan.monthly;
    final yearly = CoachPlusPlan.yearly;
    return '${monthly.periodLabel} ${monthly.fallbackPriceLabel} · '
        '${yearly.periodLabel} ${yearly.fallbackPriceLabel}';
  }

  static String get coachPlus => 'Coach+ 안내를 열까요? 심박·상황에 맞춘 심층 코칭이에요. '
      '$coachPlusAmount. 이동만 하고, 여기서는 결제하지 않아요.';

  static String get battlePass => '배틀런 패스 화면으로 이동할까요? $battlePassAmount. '
      '여기서는 패스를 구매하지 않아요. 보상 화면만 열어요.';

  static const cancelled = '알겠어요. 이동은 취소했어요.';

  static const unknown = '그 말은 아직 연결되지 않았어요. '
      '앱 소개, 챌린지 로비, 후원, 스폰서, 러너 후원, 챌린지 참가, '
      'SHARE 충전, 심폐소생권, 세이프가드, 구독, Coach+, 배틀패스 중에서 말해 주세요.';

  static const micDenied = '마이크 권한이 없어 음성을 듣지 못했어요. '
      '한글로 입력하거나 아래 버튼을 눌러 주세요.';

  static const sttUnavailable = '지금은 음성 인식을 쓸 수 없어요. '
      '한글로 입력하거나 아래 버튼을 눌러 주세요.';

  static const sttEmpty = '말씀을 알아듣지 못했어요. 다시 말하거나 한글로 입력해 주세요.';

  static const listening = '듣는 중이에요. 말씀해 주세요.';

  static String executed(MiniBotDestination destination) {
    return switch (destination) {
      MiniBotDestination.beginnerRoom =>
        '초보 1km 챌린지 방으로 이동할게요. 참가 확정은 그 화면에서 해 주세요. '
            '여기서는 참가되지 않아요.',
      MiniBotDestination.challengeLobby => '챌린지 로비로 이동할게요.',
      MiniBotDestination.cprStore => '상점 아이템 화면으로 이동할게요. '
          '기록 심폐소생권을 눌러 구매해 주세요. 여기서는 결제되지 않아요.',
      MiniBotDestination.safeGuardStore => '상점 아이템 화면으로 이동할게요. '
          '세이프 가드를 눌러 구매해 주세요. 여기서는 결제되지 않아요.',
      MiniBotDestination.donateStore => '상점 기부 펀딩으로 이동할게요. '
          '기부 버튼으로 직접 눌러 주세요. 여기서는 기부되지 않아요.',
      MiniBotDestination.shareCharge => 'SHARE 충전소로 이동할게요. '
          '팩은 그 화면에서 직접 골라 주세요. 여기서는 결제되지 않아요.',
      MiniBotDestination.personalSponsor => '러너 후원 화면으로 이동할게요. '
          '후원 버튼으로 직접 확정해 주세요. 여기서는 후원되지 않아요.',
      MiniBotDestination.brandSponsor => '브랜드 스폰서 챌린지로 이동할게요. '
          '참가는 그 화면에서 직접 해 주세요. 여기서는 참가되지 않아요.',
      MiniBotDestination.subscription => '구독 관리 화면으로 이동할게요. 여기서는 구독을 바꾸지 않아요.',
      MiniBotDestination.coachPlus => 'Coach+ 안내를 열게요. '
          '월간·연간은 그 화면에서 직접 골라 주세요. 여기서는 결제되지 않아요.',
      MiniBotDestination.battlePass => '배틀런 패스 화면으로 이동할게요. 여기서는 패스를 구매하지 않아요.',
      MiniBotDestination.none => cancelled,
    };
  }
}

abstract final class MiniBotInterpreter {
  static MiniBotRead interpret(String raw) {
    final text = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) {
      return const MiniBotRead(
        intent: MiniBotIntent.unknown,
        destination: MiniBotDestination.none,
        reply: MiniBotCopy.unknown,
        needsConfirm: false,
      );
    }

    if (_hasSafeGuard(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.openSafeGuard,
        destination: MiniBotDestination.safeGuardStore,
        reply: MiniBotCopy.safeGuard,
        needsConfirm: true,
      );
    }

    if (_hasCpr(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.openCprTicket,
        destination: MiniBotDestination.cprStore,
        reply: MiniBotCopy.cpr,
        needsConfirm: true,
      );
    }

    if (_hasBattlePass(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.battlePass,
        destination: MiniBotDestination.battlePass,
        reply: MiniBotCopy.battlePass,
        needsConfirm: true,
      );
    }

    if (_hasCoachPlus(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.coachPlus,
        destination: MiniBotDestination.coachPlus,
        reply: MiniBotCopy.coachPlus,
        needsConfirm: true,
      );
    }

    if (_hasSubscription(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.subscription,
        destination: MiniBotDestination.subscription,
        reply: MiniBotCopy.subscription,
        needsConfirm: true,
      );
    }

    if (_hasRunnerSponsor(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.sponsorRunner,
        destination: MiniBotDestination.personalSponsor,
        reply: MiniBotCopy.sponsor,
        needsConfirm: true,
      );
    }

    if (_hasBrandSponsor(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.brandSponsor,
        destination: MiniBotDestination.brandSponsor,
        reply: MiniBotCopy.brand,
        needsConfirm: true,
      );
    }

    if (text.contains('충전')) {
      return MiniBotRead(
        intent: MiniBotIntent.chargeShare,
        destination: MiniBotDestination.shareCharge,
        reply: MiniBotCopy.charge,
        needsConfirm: true,
      );
    }

    final hasBeginner =
        text.contains('초보') || text.contains('1km') || text.contains('1 km');
    final hasLobby = text.contains('로비');
    if (hasLobby && !hasBeginner) {
      return const MiniBotRead(
        intent: MiniBotIntent.joinChallenge,
        destination: MiniBotDestination.challengeLobby,
        reply: MiniBotCopy.joinLobby,
        needsConfirm: true,
      );
    }

    if (_hasDonate(text)) {
      return MiniBotRead(
        intent: MiniBotIntent.donate,
        destination: MiniBotDestination.donateStore,
        reply: MiniBotCopy.donate,
        needsConfirm: true,
      );
    }

    final hasJoin = text.contains('참가') ||
        text.contains('레이스') ||
        text.contains('입장') ||
        text.contains('들어가');
    final hasChallenge =
        text.contains('챌린지') || text.contains('대회') || text.contains('도전');
    final hasIntro = _hasIntro(text);
    if (hasBeginner || hasJoin || (hasChallenge && !hasIntro)) {
      return MiniBotRead(
        intent: MiniBotIntent.joinChallenge,
        destination: MiniBotDestination.beginnerRoom,
        reply: MiniBotCopy.joinBeginner,
        needsConfirm: true,
      );
    }

    if (hasIntro || text.contains('sharerun') || text.contains('쉐어런')) {
      return const MiniBotRead(
        intent: MiniBotIntent.appIntro,
        destination: MiniBotDestination.none,
        reply: MiniBotCopy.intro,
        needsConfirm: false,
      );
    }

    return const MiniBotRead(
      intent: MiniBotIntent.unknown,
      destination: MiniBotDestination.none,
      reply: MiniBotCopy.unknown,
      needsConfirm: false,
    );
  }

  static bool _hasSafeGuard(String text) {
    return text.contains('세이프가드') ||
        text.contains('세이프 가드') ||
        text.contains('safeguard');
  }

  static bool _hasCpr(String text) {
    return text.contains('심폐') || text.contains('소생') || text.contains('cpr');
  }

  static bool _hasBattlePass(String text) {
    return text.contains('배틀패스') ||
        text.contains('배틀 패스') ||
        text.contains('배틀런');
  }

  static bool _hasCoachPlus(String text) {
    return text.contains('coach') ||
        text.contains('코치') ||
        text.contains('코칭') ||
        text.contains('심박');
  }

  static bool _hasSubscription(String text) {
    return text.contains('구독') ||
        text.contains('멤버십') ||
        (text.contains('정기') && text.contains('후원'));
  }

  static bool _hasRunnerSponsor(String text) {
    return text.contains('천사') ||
        (text.contains('러너') && text.contains('후원'));
  }

  /// `스폰서` alone is the brand screen. Runner phrases are matched first.
  static bool _hasBrandSponsor(String text) {
    return text.contains('브랜드') || text.contains('스폰서');
  }

  static bool _hasDonate(String text) {
    return text.contains('후원') ||
        text.contains('기부') ||
        text.contains('펀딩') ||
        text.contains('유니세프');
  }

  static bool _hasIntro(String text) {
    return text.contains('소개') ||
        text.contains('뭐야') ||
        text.contains('뭐니') ||
        text.contains('무엇') ||
        text.contains('어떤 앱') ||
        text.contains('what is') ||
        text.contains('설명해');
  }
}

String _grouped(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
